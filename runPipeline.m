function ICsummary = runPipeline(varargin) %{

warning('off')
dbstop if error

%{ 
Runs analysis pipeline on all nwb file in the path indicated as first input argument.
Second input argument is the path at which nwb files with additional processing moduls are saved. 
If only one input argument is used nwb files will be overwritten. An additional input argument 
is necessary to set the betweenSweepQCmode (either 1 or 2): Mode 1, with a target membrane potential,
which is the average of the prestimulus interval of the first three sweeps. Mode 2, in
which betweenSweep QC is assessed by deviations from the grand average. 
%}

if length(varargin) > 2                                                 
          disp('No overwrite mode') 
          overwrite = 0;
          mainFolder = varargin{1};
          outDest = varargin{2};
else
     disp('Overwrite mode') 
     [outDest, mainFolder] = deal(varargin{1});
     overwrite = 1;
end    

if isa(varargin{length(varargin)}, 'double') 
        BwSweepMode = varargin{length(varargin)};    
        if BwSweepMode == 1
            disp('between sweep QC with a set target value')
        elseif BwSweepMode == 2
            disp('between sweep QC without a set target value')
        else
            error('Please use int 1 or 2 as for respective between sweep QC')
        end
else
   error('No number inputed for between sweep QC')
end

cellList = dir([mainFolder,'\','*.nwb']);                                  % list of cell data files
cellList = cellList(~[cellList.isdir]);
PS = loadParams; PS.outDest = outDest;                                     % save parameters to workspace structure
tic

if ~exist(fullfile(PS.outDest, '\peristim'), 'dir')
    mkdir(fullfile(PS.outDest, '\peristim'))
    mkdir(fullfile(PS.outDest, '\resistance'))
    mkdir(fullfile(PS.outDest, '\profiles'))
    mkdir(fullfile(PS.outDest, '\firingPattern'))
    mkdir(fullfile(PS.outDest, '\QC'))
    mkdir(fullfile(PS.outDest, '\traces'))
    mkdir(fullfile(PS.outDest, '\betweenSweeps'))
    mkdir(fullfile(PS.outDest, '\AP_Waveforms'))
    mkdir(fullfile(PS.outDest, '\tauFit'))    
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
  PS.cellID = cellList(n).name(1:length(cellList(n).name)-4);          % cell ID (used for saving data)
%% Initialize processing moduls and new columns for Sweep table
  initProceModules                                                         % initialize processing modules
  nwb  = addColumns2SwTabl(nwb,qc_tags);                                   % add initialized QC to sweep table
%% Setting up QC tables and initializing variables
  QC_parameter = table();                                                  % creating empty MATLAB table for QC paramters
  QC_parameter.SweepID = repmat({''},length(nwb.acquisition.keys),1);      % initializing SweepID column of QC paramters table
  QC_parameter.Protocol = repmat({''},length(nwb.acquisition.keys),1);     % initializing Protocol column of QC paramters table
  QC_parameter(:,3:length(qc_tags(2:end))+2) = array2table(NaN(...         
    length(nwb.acquisition.keys), length(qc_tags)-1));                     % initializing actual parameter variables with NaNs
  QC_parameter.Properties.VariableNames(3:width(QC_parameter)) = ...        
      [qc_tags(3:end), {'CapaComp'}];                                      % naming parameter variables
  
  QCpass = table();                                                        % creating empty MATLAB table for QC passing logic 
  QCpass.SweepID = repmat({''},length(nwb.acquisition.keys),1);            % initializing SweepID column of QC passing table 
  QCpass.Protocol = repmat({''},length(nwb.acquisition.keys),1);           % initializing Protocol column of QC passing table
  QCpass(:,3:length(qc_tags)+1) = ...
      array2table(NaN(length(nwb.acquisition.keys), length(qc_tags)-1));   % initializing logic values for passing table
  QCpass.Properties.VariableNames(3:width(QCpass)) = qc_tags(2:end);       % naming passing parameters variables
  
  SpPattrn.ISIs = {}; SpPattrn.spTrain = struct(); SpQC = struct();        % initializing variables for interspike intervals, spike train parameters, spike QC 
  subCount = 1; supraCount = 1;                                            % starting counting variables for sub- and suprathreshold variables
  SpPattrn.spTrainIDs = {}; SpPattrn.BinTbl = zeros(0,13);                 % initializing variables to save spike train sweep IDs and binned spike train table
  SpPattrn.RowNames = {};                                                  %
  LP_TracesExport = table();                                               % initializing table for exporting raw data traces as csv 
  
%% Looping through sweeps
    
  IcephysTab = nwb.general_intracellular_ephys_intracellular_recordings;   % assigning IntracellularRecordinsTable to new variable for readability of subsequent code
  ResponseTbl = IcephysTab.responses.response.data.load;                   % loading all sweep response from IntracellularRecordingsTable
    
  for SweepCount = 1:IcephysTab.id.data.dims                                % loop through sweeps of IntracellularRecordinsTable        
     
    SwData = struct();                                                     % initialize  structure for variabels containing sweep specific Data  
      
    SwData.CurrentPath = table2array(ResponseTbl(SweepCount,3)).path;      % get path to sweep within nwb file 
    SwData.CurrentName = ...
      SwData.CurrentPath(find(SwData.CurrentPath=='/',1,'last') ...
          +1:length(SwData.CurrentPath));                                  % extracts name of the sweep
                
    [QC_parameter.SweepID(SweepCount), QCpass.SweepID(SweepCount)] = ...
        deal({SwData.CurrentName});                                        % saves the sweep name in QC tables        
    [QC_parameter.Protocol(SweepCount), QCpass.Protocol(SweepCount)] = ...
           deal(IcephysTab.dynamictable.map('protocol_type' ...
                ).vectordata.values{1}.data.load(SweepCount));             % saves the protocol name/type in QC tables   
   
    if ~contains(IcephysTab.dynamictable.values{...
           1}.vectordata.values{1}.data.load(SweepCount), PS.SkipTags) % only continues if protocol name is not on the list in PS.SkipTags
                
       CCSeries = nwb.resolve(SwData.CurrentPath);                         % load the CurrentClampSeries of the respective sweep
                       
       SwData.StimOn = double(table2array(ResponseTbl(SweepCount,1)));     % gets stimulus onset from response table 
       SwData.StimOff = double(SwData.StimOn + ...
                                 table2array(ResponseTbl(SweepCount,2)));  % gets end of stimulus from response table 
       
       SwData.sweepAmp = double(IcephysTab.stimuli.vectordata.values{...
                         1}.data.load(SweepCount));                        % gets current amplitude from IntracellularRecordingsTable
       
       %% Sweep-wise analysis
       if contains(CCSeries.stimulus_description, PS.LPtags)           % if sweep is a long pulse protocol 
           
           LP_TracesExport = exportSweepCSV(...
               CCSeries, SwData, SweepCount, LP_TracesExport);             % a certain section of the trace is exported as csv  
       end
           
       [QC_parameter, QCpass] = SweepwiseQC(CCSeries, SwData, SweepCount, ...
                                        QC_parameter, QCpass, PS);     % Sweep QC of the CurrentClampSeries                              
                               
       if SwData.sweepAmp > 0                                              % if current input is depolarizing

          [module_spikes, sp, SpQC, QCpass] = ...
                 processSpikes(CCSeries, SwData, PS, supraCount, ...
                                 module_spikes, SpQC, QCpass, SweepCount); % detection and processing of spikes 

            if ~isempty(sp) && length(sp.peak) > 1                         % if sweep has more than one spike
                 SpPattrn.spTrainIDs(supraCount,1) = {SwData.CurrentName}; % sweep name is saved under spike train IDs
                 SpPattrn = estimateAPTrainParams(... 
                       sp,SwData.StimOn,CCSeries, supraCount, SpPattrn);   % getting spike train parameters
            end
            supraCount = supraCount + 1;                         

            elseif SwData.sweepAmp < 0                                     % if current input is hyperpolarizing
               module_subStats = subThresFeatures(CCSeries, SwData, ...
                                                  module_subStats, PS);% getting subthreshold parameters                          
               subCount = subCount +1;
       end
     SweepCount = SweepCount + 1;    
    end    
  end
   %% save AP wave and subthreshold parameters
   
   module_APP = fillAPP_Mod(module_APP,SpPattrn,nwb.nwb_version);          % make AP pattern processing module  
   nwb.processing.set('AP Pattern', module_APP);                           % add AP pattern processing module to nwb obejct
   nwb.processing.set('subthreshold parameters', module_subStats);         % add subthreshold parameters processing module to nwb obejct 
   nwb.processing.set('AP wave', module_spikes);                           % add AP wave from processing module to nwb obejct

   %% QC bridge balance relative to input resistance
   Ri_preqc = inputResistance(...
       nwb.processing.get('subthreshold parameters').dynamictable, PS);% calculate input resistance before QC 
   QCpass.bridge_balance_rela = ...
       QC_parameter.bridge_balance_rela < Ri_preqc*PS.factorRelaRa;    % check if input resistance meets relatice bridge balance criterium
   
   %% Between Sweep QC
   [QCpass.betweenSweep, QC_parameter.betweenSweep ] = ...
       BetweenSweepQC(QC_parameter, BwSweepMode, PS);                  % execute betweenSweep QC 
   
   %% save SpikeQC in ragged array    
      
   %% Save QC results in Sweeptable and external   
   QCpass.bad_spikes(isnan(QCpass.bad_spikes)) = 1;                        % replace nans with 1s for pass in the bad spike column these are from sweeps without sweeps
   QCparameterTotal.(['ID_' PS.cellID ]) = QC_parameter;               % add QC parameter table of the cell to structure for saving those  
   QCpassTotal.(['ID_' PS.cellID  ]) = QCpass;                         % add QC pass table of the cell to structure for saving those  
   tbl = util.table2nwb(QC_parameter, 'QC parameter table');               % convert QC parameter to DynamicTable
   module_QC.dynamictable.set('QC_parameter_table', tbl);                  % add DynamicTable to QC processing module
   nwb.processing.set('QC parameter', module_QC);                          % add QC processing module to nwb object
   keys = IcephysTab.dynamictable.map(...
    'quality_control_pass').vectordata.keys;                               % Get columns of quality control section of IntracellularRecordingTable
   
  for s = 1:height(QCpass)                                                 % loop through sweeps/rows of QC pass table
      if  sum(isnan(QCpass{s,4:14})) == 0 && sum(QCpass{s,4:14}) == 11     % Condition 1: QC pass columns do not contain NaN. Condition 2: All columns have to contain 1
          QCpass(s,3) = {1};
      elseif sum(isnan(QCpass{s,4:14})) > 3                                % If row contains more than 3 NaNs the sweep is not QC-able and the total pass parameter should be NaN as well
          QCpass(s,3) = {NaN};
      else
         QCpass(s,3) = {0};                                                % sweep has not passed the total QC
      end
  end
  for t = 1:length(keys)                                                   %loop columns of QC pass 
    if any(contains(fieldnames(QCpass),keys(t)))
        IcephysTab.dynamictable.values{...
          2}.vectordata.values{t}.data = ...
                  QCpass.(char(keys(t)))';   
    end
  end
  
  totalSweeps = height(QCpass)-sum(isnan(QCpass.QC_total_pass));           % calculates the number of sweeps being considered during the analysis
  QC_removalsPerTag(n,1) = {totalSweeps};                                  % adding total number of sweeps to the removals-per-tag table
  QC_removalsPerTag(n,2) = varfun(@sum, rmmissing(QCpass(:,3)));           % adding the number of passed sweeps to the removals-per-tag table
  QC_removalsPerTag(n,3:end) = num2cell(abs(table2array(...
      varfun(@sum, rmmissing(QCpass(:,4:end))))-totalSweeps));             % adding the number of failed sweeps per QC criterium to the removals-per-tag table
 
   %% Feature Extraction and Summary
   info = nwb.general_intracellular_ephys;
   
   if ~isempty(info.values{1}.('initial_access_resistance')) && ...
          length(regexp(info.values{1}.('initial_access_resistance'),...
                                      '\d*','Match')) >= 1                 % if ini access resistance is non empty and has a number as character
      
       if str2double(info.values{1}.('initial_access_resistance')) ...
                <= PS.cutoffInitRa  && ...                             % if ini access resistance is below absolute and relative threshold
          str2double(info.values{1}.('initial_access_resistance')) ...
                 <= Ri_preqc*PS.factorRelaRa

          [ICsummary, PS] = LPsummary(nwb, ICsummary, n, PS);       % extract features from long pulse stimulus
          [ICsummary, PS] =  SPsummary(nwb, ICsummary, n, PS); % extract features from short pulse stimulus
          plotCellProfile(nwb, PS)                                    % plot cell profile 
       else 
           display(['excluded by cell-wide QC for initial Ra (', ...
                 num2str(info.values{1}.('initial_access_resistance')),...
                ') higher than realtive cutoff (', ...
                      num2str(Ri_preqc*PS.factorRelaRa), ...
                ') or absolute cutoff (', num2str(PS.cutoffInitRa),')'... 
                  ]);
           QCcellWide{end+1} = PS.cellID ;                             % save cellID for failing cell-wide QC
       end  
       
   else
       [ICsummary, PS] = LPsummary(nwb, ICsummary, n, PS);    % extract features from long pulse stimulus 
       [ICsummary, PS] = SPsummary(nwb, ICsummary, n, PS); % extract features from short pulse stimulus 
       plotCellProfile(nwb, PS)                            % plot cell profile
       disp('No initial access resistance available') 
   end    
   if isnan(ICsummary.thresLP(n)) && PS.noSupra == 1               % if there is no AP features such as threshold and no suprathreshold traces is cell wide exclusion criterium
         disp('excluded by cell-wide QC for no suprathreshold data') 
         ICsummary(n,1:7) = {NaN};                                         % replace subthreshold features with NaNs
         QCcellWide{end+1} = PS.cellID ;                               % save cellID for failing cell-wide QC
   end
   %% Add subject data, dendritic type and reporter status   
   if nwb.processing.isKey('Anatomical data') && ~isempty(...              
           nwb.processing.values{3}.dynamictable.values{...                % if there is an anatomical data processing module
                        1}.vectordata.values{1}.data)                      % and there is data on dendritic type of the cell
                    
    ICsummary.dendriticType(n) = ...
       {nwb.processing.values{3}.dynamictable.values{1}.vectordata.map(...
               'DendriticType').data.load};                                % assigning dendritic type to summary table
    ICsummary.SomaLayerLoc(n) = ...
       {nwb.processing.values{3}.dynamictable.values{1}.vectordata.map(...
               'SomaLayerLoc').data.load};                                 % assigning soma layer location to summary table
   else
       [ICsummary.dendriticType(n),ICsummary.SomaLayerLoc(n)] = ...
           deal({'NA'});                                                   % NA for soma layer location and dendritic type of cells without entries 
   end
   if nwb.general.Count ~= 0                                               % if  
       ICsummary.Weight(n) = {nwb.general_subject.weight};
       ICsummary.Sex(n) = {nwb.general_subject.sex};
       ICsummary.Age(n) = {nwb.general_subject.age};  
       ICsummary.species(n) = {nwb.general_subject.species};
   end 
   if ~isempty(info.values{1}.slice)                                       % if there is information on brain slice of experiment
        temperature = regexp(info.values{...
                                  1}.slice, '(\d+,)*\d+(\.\d*)?', 'match');% extracting values for temperature
        if isempty(temperature)                                            % if there is no temperature values
           ICsummary.Temperature(n) = NaN;
        else
            ICsummary.Temperature(n) = str2double(cell2mat(temperature));  % assign temperature values to summary table
        end
   end 
   if string(nwb.general_institution) == "Allen Institute of Brain Science"% if the cell is from the AIBS 
      ICsummary.brainOrigin(n) = {info.values{...
        1}.location(1:find(info.values{...
           1}.location==',')-1)};                                          % assign part of the description of as brain area to summary table 
   else
      ICsummary.brainOrigin(n) = {info.values{1}.location};                % assign brain area to summary table          
      ICsummary.Species(n) = {nwb.general_subject.species};                % assign species to summary table    
   end
    
   if nwb.general.Count ~= 0 && ...
           string(nwb.general_subject.species)== "Mus musculus" 
       if string(cellFile.processing.values{4}.dynamictable.values{1 ...
                           }.vectordata.values{3}.data.load) == "positive"
         ICsummary.ReporterTag(n) = {nwb.general_subject.genotype};        % assigning genotype to summary table  
       else
         ICsummary.ReporterTag(n) = {'None'} ;
       end
   end       
   %% Export Traces and NWB file
   
  if ~isempty(LP_TracesExport)                                             % if there raw traces in the table for export
      prndRow = [];                                                        % initialize variable to prune rows
      for r = 1:height(LP_TracesExport)                                    % loop through rows of the table
          if sum(LP_TracesExport{r,3}) == 0                                % if the sweep is zero 
               prndRow = [prndRow; r];                                     % save values in variables
          end
      end
      LP_TracesExport(prndRow,:) = [];                                     % pruning empty sweeps

      writetable(LP_TracesExport, ...
           fullfile(PS.outDest, '\traces\', [nwb.identifier, '.csv'])) % export table of raw sweep data as csv
  end
  
  if  ~any(contains(QCcellWide,PS.cellID))                             % if the cell is not excluded by cell wide QC
      if overwrite == 1
          disp(['Overwriting file ', cellList(n).name])
          nwbExport(nwb, fullfile(PS.outDest, '\', cellList(n).name))  % export nwb object as file
      elseif isfile(fullfile(PS.outDest, '\', cellList(n).name))      
          delete(fullfile(PS.outDest, '\', cellList(n).name));
          disp(['Overwriting file ', cellList(n).name, ' in output folder'])
          nwbExport(nwb, fullfile(PS.outDest, '\', cellList(n).name))  % export nwb object as file 
      else
          nwbExport(nwb, fullfile(PS.outDest, '\', cellList(n).name))  % export nwb object as file
          disp(['saving file ', cellList(n).name, ' in output folder'])
      end
  else
      disp([ cellList(n).name, ' not saved for failing cell-wide QC'])
  end
  toc
end                                                                        % end cell level for loop
%% Output summary fiels and figures 
% QC_plots
Summary_output_files
end

