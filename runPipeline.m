function ICsummary = runPipeline(varargin) %{

warning('off')
dbstop if error

%{ 
Runs analysis pipeline on all nwb file in the path indicated as first input argument.
Second input argument is the path at which nwb files with additional processing moduls are saved. 
If only one input argument is used nwb files will be overwritten.
In addition there are two different modes of between Sweep QC: Mode 1, in
which the cell has a target membrane potential which is the average of the
prestimulus membrane potential of the first three sweeps. And Mode 2, in
which there is no set membrane potential and the between sweep QC is assessed 
by deviations from the grand average. To set the between sweep mode also add
a 1 or 2 as input argument.
%}

check1 = 0;
check2 = 0;
for v = 1:nargin
    if check1 == 0 && (isa(varargin{v}, 'char') || isa(varargin{v}, 'string'))
        mainFolder = varargin{v};
        if endsWith(mainFolder, '\') || endsWith(mainFolder, '/')
          mainFolder(length(mainFolder)) = [];
        end
        check1 = 1;
    elseif (isa(varargin{v}, 'char') || isa(varargin{v}, 'string'))
        outDest = varargin{v};
        if endsWith(outDest, '\') || endsWith(outDest, '/')
          outDest(length(outDest)) = [];
        end      
        disp('No overwrite mode')
    elseif isa(varargin{v}, 'double') 
        BwSweepMode = varargin{v};    
        check2 = 1;
        if BwSweepMode == 1
            disp('between sweep QC with a set target value')
        elseif BwSweepMode == 2
            disp('between sweep QC without a set target value')
        else
            error('Please use 1 or 2 as input for respective between sweep mode ')
        end
    end
end
if check2 == 0
   error('No number inputed for between sweep QC')
end
cellList = dir([mainFolder,'\','*.nwb']);                                  % list of cell data files
cellList = cellList(~[cellList.isdir]);
params = loadParams;   
params.outDest = outDest; % load parameters to workspace
tic

delete(fullfile(params.outDest, '\peristim\*'))
delete(fullfile(params.outDest, '\resistance\*'))
delete(fullfile(params.outDest, '\profiles\*'))
delete(fullfile(params.outDest, '\firingPattern\*'))
delete(fullfile(params.outDest, '\QC\*'))
delete(fullfile(params.outDest, '\traces\*'))
delete(fullfile(params.outDest, '\betweenSweeps\*'))
mkdir(fullfile(params.outDest, '\peristim'))
mkdir(fullfile(params.outDest, '\resistance'))
mkdir(fullfile(params.outDest, '\profiles'))
mkdir(fullfile(params.outDest, '\firingPattern'))
mkdir(fullfile(params.outDest, '\QC'))
mkdir(fullfile(params.outDest, '\traces'))
mkdir(fullfile(params.outDest, '\betweenSweeps'))
mkdir(fullfile(params.outDest, '\AP_Waveforms'))

%% Set to overwrite or delete nwb files from output folder 

overwrite = 0;
if length(mainFolder) == length(outDest) && mainFolder == outDest
    overwrite = 1;
else    
    for k = 1 : length(cellList)
      baseFileName = cellList(k).name;
      fullFileName = fullfile(outDest, baseFileName);
      fprintf(1, 'Now deleting %s\n', fullFileName);
      delete(fullFileName);
    end
    clear fullFileName baseFileName
end    

%% Initialize feature and QC summary tables

ICsummary = initICSummary(cellList); 

qc_tags = {'SweepsTotal' 'QC_total_pass' 'stRMSE_pre' 'stRMSE_post' ...
        'ltRMSE_pre' 'ltRMSE_post' 'diffVrest' ...
        'Vrest'  'holdingI' 'betweenSweep' ...
        'bridge_balance_abs' 'bridge_balance_rela' 'bad_spikes' ...
         };
     
QC_removalsPerTag = array2table(NaN(length(cellList),length(qc_tags)), ...
    'VariableNames', qc_tags,'RowNames', {cellList.name});

QCparameterTotal = struct(); QCpassTotal = struct(); QCcellWide = {};

%% Looping through nwb files
for n = 1:length(cellList)                                                 % for all cells in directory
  nwb = nwbRead(fullfile(cellList(n).folder,cellList(n).name));            % load nwb file
  params.cellID = cellList(n).name(1:length(cellList(n).name)-4);          % cell ID (used for saving data)
    
  if ~isempty(nwb.general_experiment_description) &&...
            contains(nwb.general_experiment_description,'PatchMaster')
        params.cellID  =  params.cellID (1:31);
        params.cellID(params.cellID =='-') = '_';
        nwb.identifier = params.cellID ;
  end
  disp(params.cellID)                                                      % display ID number
  params.cellID(params.cellID=='-') = '_';
%% Initialize processing moduls and new columns for Sweep table
  initProceModules
  nwb  = addColumns2SwTabl(nwb,qc_tags);
%% Setting up two QC tables and initializing Variables for counts and temproray storage

  QC_parameter = table();
  QC_parameter.SweepID = repmat({''},length(nwb.acquisition.keys),1);
  QC_parameter.Protocol = repmat({''},length(nwb.acquisition.keys),1);
  QC_parameter(:,3:length(qc_tags(2:end))+2) = array2table(NaN(...
    length(nwb.acquisition.keys), length(qc_tags)-1));
  QC_parameter.Properties.VariableNames(3:width(QC_parameter)) = ...
      [qc_tags(3:end), {'CapaComp'}];
  QCpass = table();
  QCpass.SweepID = repmat({''},length(nwb.acquisition.keys),1);
  QCpass.Protocol = repmat({''},length(nwb.acquisition.keys),1);
  QCpass(:,3:length(qc_tags)+1) = ...
      array2table(NaN(length(nwb.acquisition.keys), length(qc_tags)-1));
  QCpass.Properties.VariableNames(3:width(QCpass)) = qc_tags(2:end);
  SpPattrn.ISIs = {}; SpPattrn.spTrain = struct(); SpQC = struct();
  subCount = 1; supraCount = 1;
  SpPattrn.spTrainIDs = {}; SpPattrn.BinTbl = zeros(0,20); SpPattrn.RowNames = {};
  LP_TracesExport = table();
  
%% Looping through sweeps
    
  ResponseTbl = ...
nwb.general_intracellular_ephys_intracellular_recordings.responses.response.data.load;
    
  for SweepCount = 1:nwb.general_intracellular_ephys_intracellular_recordings.id.data.dims                    % loop through sweeps        
      
    CurrentPath = table2array(ResponseTbl(SweepCount,3)).path;
        
    CurrentName = CurrentPath(find(CurrentPath=='/',1,'last')+1:length(CurrentPath));
                
    [QC_parameter.SweepID(SweepCount), QCpass.SweepID(SweepCount)] = deal({CurrentName});
      
    [QC_parameter.Protocol(SweepCount), QCpass.Protocol(SweepCount)] = deal(...
     nwb.general_intracellular_ephys_intracellular_recordings.dynamictable.map(...
       'protocol_type').vectordata.values{1}.data.load(SweepCount));   
   
    if ~contains(...
nwb.general_intracellular_ephys_intracellular_recordings.dynamictable.values{...
           1}.vectordata.values{1}.data.load(SweepCount), params.SkipTags) 
                
       CCSeries = nwb.resolve(CurrentPath);
                       
       StimOn = double(table2array(ResponseTbl(SweepCount,1))); 
       StimOff = double(StimOn + table2array(ResponseTbl(SweepCount,2))); 
       
       sweepAmp = double(...
  nwb.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
         1}.data.load(SweepCount));
       
       %% Sweep-wise analysis
       if contains(CCSeries.stimulus_description, params.LPtags)           
           LP_TracesExport = exportSweep4web(CCSeries, StimOn, ...
               StimOff, sweepAmp, CurrentName, SweepCount, LP_TracesExport);     
       end
           
       [QC_parameter, QCpass]  = SweepwiseQC(CCSeries, StimOn, StimOff, ...
                                   SweepCount, QC_parameter, QCpass, params);                                     
                               
       if sweepAmp > 0                                                                % if current input > 0

          [module_spikes, sp, SpQC, QCpass] = ...
                 processSpikes(CCSeries, StimOn, StimOff, params, ...
                                 supraCount, module_spikes, SpQC, ...
                                   QCpass, SweepCount, CurrentName);

            if ~isempty(sp) && length(sp.peak) > 1
                 SpPattrn.spTrainIDs(supraCount,1) = {CurrentName};
                 SpPattrn = estimateAPTrainParams(...
                       sp,StimOn,CCSeries, supraCount, SpPattrn);
            end
            supraCount = supraCount + 1;

            elseif sweepAmp < 0 
               module_subStats = subThresFeatures(CCSeries, StimOn, StimOff, ...
                              sweepAmp, CurrentName, module_subStats, params);                          
               subCount = subCount +1;
       end
     SweepCount = SweepCount + 1;    
    end    
  end
   %% save AP wave and subthreshold parameters
   
   module_APP = fillAPP_Mod(module_APP,SpPattrn,nwb.nwb_version); 
   nwb.processing.set('AP Pattern', module_APP); 
   nwb.processing.set('subthreshold parameters', module_subStats);
   nwb.processing.set('AP wave', module_spikes);

   %% QC bridge balance relative to input resistance
   Ri_preqc = inputResistance(...
       nwb.processing.get('subthreshold parameters').dynamictable, params);
   QCpass.bridge_balance_rela = ...
       QC_parameter.bridge_balance_rela < Ri_preqc*params.factorRelaRa;
   
   %% Between Sweep QC
   [QCpass.betweenSweep, QC_parameter.betweenSweep ] = ...
       BetweenSweepQC(QC_parameter, BwSweepMode, params);
   
   %% save SpikeQC in ragged array    
      
   %% Save QC results in Sweeptable and external   
   QCpass.bad_spikes(isnan(QCpass.bad_spikes)) = 1; 
   QCparameterTotal.(['ID_' params.cellID ]) = QC_parameter;  
   QCpassTotal.(['ID_' params.cellID  ]) = QCpass;  
   tbl = util.table2nwb(QC_parameter, 'QC parameter table');  
   module_QC.dynamictable.set('QC_parameter_table', tbl);
   nwb.processing.set('QC parameter', module_QC);
   keys = nwb.general_intracellular_ephys_intracellular_recordings.dynamictable.map(...
    'quality_control_pass').vectordata.keys;
   
  for s = 1:height(QCpass)                                                 % loop through sweeps/rows of QC pass table
      if  sum(isnan(QCpass{s,4:14})) == 0 && sum(QCpass{s,4:14}) == 11     % Condition 1: QC pass columns do not contain NaN. Condition 2: All columns have to contain 1
          QCpass(s,3) = {1};
      elseif sum(isnan(QCpass{s,4:14})) > 3                                % If row contains more than 3 NaNs the sweep is not QC-able and the total pass parameter should be NaN as well
          QCpass(s,3) = {NaN};
      else
         QCpass(s,3) = {0};                                                % sweep has not passed the total QC
      end
  end
  for t = 1:length(keys)                                                   %loop trhough QC pass 
    if any(contains(fieldnames(QCpass),keys(t)))
        nwb.general_intracellular_ephys_intracellular_recordings.dynamictable.values{...
          2}.vectordata.values{t}.data = ...
                  QCpass.(char(keys(t)))';   
    end
  end
  
  totalSweeps = height(QCpass)-sum(isnan(QCpass.QC_total_pass));
  QC_removalsPerTag(n,1) = {totalSweeps};
  QC_removalsPerTag(n,2) = varfun(@sum, rmmissing(QCpass(:,3)));
  QC_removalsPerTag(n,3:end) = num2cell(abs(table2array(...
      varfun(@sum, rmmissing(QCpass(:,4:end))))-totalSweeps));
 
   %% Feature Extraction and Summary
   info = nwb.general_intracellular_ephys;
   
   if ~isempty(info.values{1}.('initial_access_resistance')) && ...
          length(regexp(info.values{1}.('initial_access_resistance'),...
                                      '\d*','Match')) >= 1                  % if ini access resistance is non empty and has a number as character
      
       if str2double(nwb.general_intracellular_ephys.values{1}.('initial_access_resistance')) ...
                 <= params.cutoffInitRa 
           if  str2double(nwb.general_intracellular_ephys.values{1}.('initial_access_resistance')) ...
                 <= Ri_preqc*params.factorRelaRa
                [nwb, ICsummary, PlotStruct] = ...
                            LPsummary(nwb, ICsummary, n, params);
                [nwb, ICsummary, PlotStruct] = ...
                            SPsummary(nwb, ICsummary, n, params, PlotStruct);
                plotCellProfile(nwb, PlotStruct, params)
           else
              display(['    was excluded by cell-wide QC for Ra higher than ', ...
                  num2str(Ri_preqc*params.factorRelaRa)]);
                  QCcellWide{end+1} = params.cellID ;
           end
       else
              display(['    was excluded by cell-wide QC for Ra higher than ', ...
                  num2str(params.cutoffInitRa )])
                  QCcellWide{end+1} = params.cellID ;
      end              
   else
       [nwb, ICsummary, PlotStruct] = ...
                            LPsummary(nwb, ICsummary, n, params);
       [nwb, ICsummary, PlotStruct] = ...
                            SPsummary(nwb, ICsummary, n, params, PlotStruct);
       plotCellProfile(nwb, PlotStruct, params)
   end    
   if isnan(ICsummary.thresholdLP(n)) && params.noSupra == 1
         disp('     was excluded by cell-wide QC for no suprathreshold data') 
         ICsummary(n,1:7) = {NaN};
         QCcellWide{end+1} = params.cellID ;
   end
  
   %% Add subject data, dendritic type and reporter status   
   if nwb.processing.isKey('Anatomical data') && ~isempty(...
           nwb.processing.values{3}.dynamictable.values{...
                        1}.vectordata.values{1}.data)   
                    
    ICsummary.dendriticType(n) = ...
       {nwb.processing.values{3}.dynamictable.values{1}.vectordata.map(...
               'DendriticType').data.load};
    ICsummary.SomaLayerLoc(n) = ...
       {nwb.processing.values{3}.dynamictable.values{1}.vectordata.map(...
               'SomaLayerLoc').data.load};
   else
       [ICsummary.dendriticType(n),ICsummary.SomaLayerLoc(n)] = ...
           deal({'NA'});
   end
   if nwb.general.Count ~= 0
       ICsummary.Weight(n) = {nwb.general_subject.weight};
       ICsummary.Sex(n) = {nwb.general_subject.sex};
       ICsummary.Age(n) = {nwb.general_subject.age};  
       ICsummary.species(n) = {nwb.general_subject.species};
   end 
   if ~isempty(nwb.general_intracellular_ephys.values{1}.slice)
        temperature = regexp(nwb.general_intracellular_ephys.values{...
                                  1}.slice, '(\d+,)*\d+(\.\d*)?', 'match');
        if isempty(temperature)
           ICsummary.Temperature(n) = NaN;
        else
            ICsummary.Temperature(n) = str2double(cell2mat(temperature));
        end
   end 
   if string(nwb.general_institution) == "Allen Institute of Brain Science" 
      ICsummary.brainOrigin(n) = {nwb.general_intracellular_ephys.values{...
        1}.location(1:find(nwb.general_intracellular_ephys.values{...
           1}.location==',')-1)};
   else
      ICsummary.brainOrigin(n) = {nwb.general_intracellular_ephys.values{1}.location};
      ICsummary.Species(n) = {nwb.general_subject.species};
   end
    
   if nwb.general.Count ~= 0 && ...
           string(nwb.general_subject.species)== "Mus musculus"
        
      ICsummary.ReporterTag(n) = {nwb.general_subject.genotype};       
      %string(cellFile.processing.values{4}.dynamictable.values{1}.vectordata.values{3}.data.load) == "positive"
   else
       ICsummary.ReporterTag(n) = {'None'} ;
   end       
   %% Export Traces and NWB file
   
  if ~isempty(LP_TracesExport)
      prndRow = [];
      for r = 1:height(LP_TracesExport)    
          if sum(LP_TracesExport{r,3}) == 0
               prndRow = [prndRow; r]; 
          end
      end
      LP_TracesExport(prndRow,:) = [];     % pruning empty sweeps

      writetable(LP_TracesExport, ...
           fullfile(params.outDest, '\traces\', [nwb.identifier, '.csv']))
  end
  if overwrite == 1
      delete(fullfile(params.outDest, '\', cellList(n).name)) 
  end    
  nwbExport(nwb, fullfile(params.outDest, '\', cellList(n).name));                                                                        % end cell level for loop
  toc
end
%% Output summary fiels and figures 
% QC_plots
Summary_output_files
end

