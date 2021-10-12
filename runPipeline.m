function ICsummary = runPipeline(varargin) %{

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
cellList = dir([mainFolder,'\','*.nwb']);                                      % list of cell data files
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
    cellFile = nwbRead(fullfile(cellList(n).folder,cellList(n).name));                 % load nwb file    
    params.cellID = cellList(n).name(1:length(cellList(n).name)-4);               % cell ID (used for saving data)   
    
    if ~isempty(cellFile.general_experiment_description) &&...
            contains(cellFile.general_experiment_description,'PatchMaster')
      params.cellID  =  params.cellID (1:31);
      params.cellID(params.cellID =='-') = '_';
      cellFile.identifier = params.cellID ;
    end
    disp(params.cellID)                                                           % display ID number
    params.cellID(params.cellID=='-') = '_';
    %% Initialize processing moduls and new columns for Sweep table 
    initProceModules 
    cellFile  = addColumns2SwTabl(cellFile,qc_tags);    
    %% Setting up two QC tables and initializing Variables for counts and temproray storage    
    QC_parameter = table();
    QC_parameter.SweepID = repmat({''},length(cellFile.acquisition.keys),1);
    QC_parameter.Protocol = repmat({''},length(cellFile.acquisition.keys),1);
    QC_parameter(:,3:length(qc_tags(2:end))+2) = array2table(NaN(...
               length(cellFile.acquisition.keys), length(qc_tags)-1));  
    QC_parameter.Properties.VariableNames(3:width(QC_parameter)) = [qc_tags(3:end), {'CapaComp'}];  
    QCpass = table();
    QCpass.SweepID = repmat({''},length(cellFile.acquisition.keys),1);
    QCpass.Protocol = repmat({''},length(cellFile.acquisition.keys),1);
    QCpass(:,3:length(qc_tags)) = array2table(NaN(length(cellFile.acquisition.keys), length(qc_tags)-2));   
    QCpass.Properties.VariableNames(3:width(QCpass)) = qc_tags(3:end);  
    SpPattrn.ISIs = {}; SpPattrn.spTrain = struct(); SpQC = struct(); 
    SweepCount = 1;  subCount = 1; supraCount = 1;   
    SpPattrn.spTrainIDs = {}; SpPattrn.BinTbl = zeros(0,20); SpPattrn.RowNames = {};
    LP_TracesExport = table();
     
    %% Looping through sweeps 
    SweepPathsAll = {cellFile.general_intracellular_ephys_sweep_table.series.data.path};
    SweepPathsStim = SweepPathsAll(contains(SweepPathsAll,'stimulus'));
    SweepPathsAqui = SweepPathsAll(contains(SweepPathsAll,'acquisition'));
   
    for s = 1:length(SweepPathsStim)                      % loop through sweeps        

        CCStimSeries = cellFile.resolve(SweepPathsStim(s)); 
               
        if isa(CCStimSeries, 'types.core.CurrentClampStimulusSeries') && ...
                ~contains(CCStimSeries.stimulus_description, params.SkipTags) 
        
        %CurrentStimPath = cell2mat(SweepPathsStim(s));
        %CurrentStimName = CurrentStimPath(find(CurrentStimPath=='/',1,'last')+1:length(CurrentStimPath));        
              
        [AquiSwTabIdx, SwTabIdxAll] = getAquisitionIndex(cellFile, CCStimSeries.sweep_number);
        
        CurrentPath = cellFile.general_intracellular_ephys_sweep_table.series.data(AquiSwTabIdx).path;
        CurrentName = CurrentPath(find(CurrentPath=='/',1,'last')+1:length(CurrentPath));
                
        [QC_parameter.SweepID(SweepCount), QCpass.SweepID(SweepCount)] = ...
          deal({CurrentName});
        
        CCSeries = cellFile.resolve(CurrentPath);
         
        GetStimProtocol
        
        if ~strcmp(QCpass.Protocol(SweepCount),'NA')
        %% Analysis
           if contains(CCStimSeries.stimulus_description, params.LPtags)           
               LP_TracesExport = ...
                   exportSweep4web(CCSeries, StimOn, StimOff, sweepAmp, ...
                                     CurrentName, SweepCount, LP_TracesExport);     
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
        end
        SweepCount = SweepCount + 1;    
        end
    end
   %% save AP wave and subthreshold parameters
   
   module_APP = fillAPP_Mod(module_APP,SpPattrn,cellFile.nwb_version); 
   cellFile.processing.set('AP Pattern', module_APP); 
   cellFile.processing.set('subthreshold parameters', module_subStats);
   cellFile.processing.set('AP wave', module_spikes);

   %% QC bridge balance relative to input resistance
   Ri_preqc = inputResistance(...
       cellFile.processing.get('subthreshold parameters').dynamictable, params);
   QCpass.bridge_balance_rela = ...
       QC_parameter.bridge_balance_rela < Ri_preqc*params.factorRelaRa;
   
   %% Between Sweep QC
   [QCpass.betweenSweep, QC_parameter.betweenSweep ] = ...
       BetweenSweepQC(QC_parameter, BwSweepMode, params);
   
   %% save SpikeQC in ragged array    
      
   %% Save QC results in Sweeptable and external 
   
   %QC_parameter = rmmissing(QC_parameter);
   QCpass = rmmissing(QCpass,'MinNumMissing',2);
   QCparameterTotal.(['ID_' params.cellID ]) = QC_parameter;  
   QCpassTotal.(['ID_' params.cellID  ]) = QCpass;  
   QCpass.bad_spikes(isnan(QCpass.bad_spikes)) = 1; 
   tbl = util.table2nwb(QC_parameter, 'QC parameter table');  
   module_QC.dynamictable.set('QC_parameter_table', tbl);
   cellFile.processing.set('QC parameter', module_QC);
    
   for t = 8:cellFile.general_intracellular_ephys_sweep_table.vectordata.Count      %loop trhough QC pass columns in sweep table CHANGED
     key = cellFile.general_intracellular_ephys_sweep_table.vectordata.keys{t};     
     cellFile.general_intracellular_ephys_sweep_table.vectordata.values{t}.data =  ...
       QCpass.(key);                                                                    % fill with the respective value   
   end
   
   for s = 1:height(QCpass)
              
        SweepPos = find(endsWith(SweepPathsAll,QCpass.SweepID(s)));            
        
        if sum(table2array(getRow(cellFile.general_intracellular_ephys_sweep_table,...
              s,'columns', qc_tags(3:end)))) == 11

           cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
               3}.data(SweepPos) = true; 
        else       
           cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
               3}.data(SweepPos) = false;       
        end 
   end
   
   temp = varfun(@sum, QCpass(:,3:end));
   QC_removalsPerTag(n,3:end) = num2cell(-(temp{:,:}-height(QCpass)));
   QC_removalsPerTag(n,2) = {sum(...
     cellFile.general_intracellular_ephys_sweep_table.vectordata.values{3}.data(...
       1:length(SweepPathsAqui)), 'omitnan')};
   QC_removalsPerTag(n,1) = {height(QCpass)};

   %% Feature Extraction and Summary
   if  ~isempty(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) && ...
           (string(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ~= "NaN" && ...
               string(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ~= ...
                   "has to be entered manually")
      
       if str2double(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ...
                 <= params.cutoffInitRa 
           if  str2double(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ...
                 <= Ri_preqc*params.factorRelaRa
                [cellFile, ICsummary, PlotStruct] = ...
                            LPsummary(cellFile, ICsummary, n, params);
                [cellFile, ICsummary, PlotStruct] = ...
                            SPsummary(cellFile, ICsummary, n, params, PlotStruct);
                plotCellProfile(cellFile, PlotStruct, params)
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
       [cellFile, ICsummary, PlotStruct] = ...
                            LPsummary(cellFile, ICsummary, n, params);
       [cellFile, ICsummary, PlotStruct] = ...
                            SPsummary(cellFile, ICsummary, n, params, PlotStruct);
       plotCellProfile(cellFile, PlotStruct, params)
   end    
   if isnan(ICsummary.thresholdLP(n)) && params.noSupra == 1
         disp('     was excluded by cell-wide QC for no suprathreshold data') 
         ICsummary(n,1:7) = {NaN};
         QCcellWide{end+1} = params.cellID ;
   end
  
   %% Add subject data, dendritic type and reporter status   
   if cellFile.processing.isKey('Anatomical data') && ~isempty(...
           cellFile.processing.values{3}.dynamictable.values{1}.vectordata.values{1}.data)   
    ICsummary.dendriticType(n) = ...
       {cellFile.processing.values{3}.dynamictable.values{1}.vectordata.map('DendriticType').data.load};
    ICsummary.SomaLayerLoc(n) = ...
       {cellFile.processing.values{3}.dynamictable.values{1}.vectordata.map('SomaLayerLoc').data.load};
   else
       [ICsummary.dendriticType(n),ICsummary.SomaLayerLoc(n)] = ...
           deal({'NA'});
   end
   if cellFile.general.Count ~= 0
       ICsummary.Weight(n) = {cellFile.general_subject.weight};
       ICsummary.Sex(n) = {cellFile.general_subject.sex};
       ICsummary.Age(n) = {cellFile.general_subject.age};  
       ICsummary.species(n) = {cellFile.general_subject.species};
   end 
   if ~isempty(cellFile.general_intracellular_ephys.values{1}.slice)
        temperature = regexp(...
        cellFile.general_intracellular_ephys.values{1}.slice, '(\d+,)*\d+(\.\d*)?', 'match');
        if isempty(temperature)
           ICsummary.Temperature(n) = NaN;
        else
            ICsummary.Temperature(n) = str2double(cell2mat(temperature));
        end
   end 
   if string(cellFile.general_institution) == "Allen Institute of Brain Science" 
      ICsummary.brainOrigin(n) = {cellFile.general_intracellular_ephys.values{1}.location(...
          1:find(cellFile.general_intracellular_ephys.values{1}.location==',')-1)};
   else
      ICsummary.brainOrigin(n) = {cellFile.general_intracellular_ephys.values{1}.location};
      ICsummary.Species(n) = {cellFile.general_subject.species};
   end
    
   if cellFile.general.Count ~= 0 && string(cellFile.general_subject.species) == "Mus musculus"
        
      ICsummary.ReporterTag(n) = {cellFile.general_subject.genotype};       
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
           fullfile(params.outDest, '\traces\', [cellFile.identifier, '.csv']))
   end
   if overwrite == 1
      delete(fullfile(params.outDest, '\', cellList(n).name)) 
   end    
  % nwbExport(cellFile, fullfile(params.outDest, '\', cellList(n).name));
end                                                                        % end cell level for loop

%% Output summary fiels and figures 
Summary_output_files
% QC_plots
toc

