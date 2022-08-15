function ICsummary = runPipeline(varargin) %{
<<<<<<< Updated upstream

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

%Runs quality control and feature analysis on data indicated
%by input argument
% 
% Examples:
%
%  runPipeline(inputPath, outputPath, BetweenSwpMode) 
%  Gets all NWB Files from the input path and processes them.  
%  The between sweep mode sets what kind of between sweep quality  
%  assurance will be used. After the cell is processed a multitude of 
%  features is extracted, the processed data is saved in the NWB File and
%  written into  the output path
%
%  runPipeline(Path, BetweenSwpMode) 
%  Gets all NWB Files from the input path and overwrites files after
%  processing and feature extraction
%
% Inputs:
%
%  (input/output)Path - string or character array specifiying 
%                      location for reading and/or writing NWB files
%
%  BetweenSwpMode     - integer of either 1 or 2: Mode 1 has a target
%                      membrane potential, determined by a robust average  
%                      of the first five sweeps: between sweep quality 
%                      control in Mode 2 is assessed by deviations from 
%                      the robust average of all sweeps.
% 
% Creates following files and folders in output folder:
% 
% ephys_features  - table with all extraced features per cell; for more   
%                 information on names and methods for features see the
%                 feature table under utilities. 
%              
% box1            - table without cells that have not passed quality 
%                control with important anatomical and subject data for the 
%                purpose of publishing this information on a website.
%
% box2_ephys      - table without cells that have not passed quality  
%                control with a few key electrophysiological features for  
%                the purpose of publishing this information on a website.
% 
% binary_selection - table with binary codes for passing the quality
%                  control; 1 means the sweep passed; 0 means the sweep 
%                  failed quality control; NaN means that this cell did not
%                  contain as many sweeps as columns in the table.
%
% ID_lookup       - table with two columns showing correspondence between
%                 old NWB cell ID and new NWB cell ID. These new cell IDs  
%                 are introduced to publish the data on an open-source 
%                 website.
%
% QC_sweeps_per_tag_martix  - table that summarizes the results of the 
%                 sweepwise quality control. 
%
% procedure_doc   - table to document all quality control parameters used 
%                 in the analysis run and some other important enviroment   
%                 variables.
%
% AP_Waveforms   - folder to export voltage data of long pulse rheobase  
%                 spike for review and display on an open-source website.
%
% betweenSweep   - folder to export visualizations of the between sweep  
%                 quality control.
%
% firingPattern  - folder to export visualizations of firing pattern
%                 analysis.
%
% peristim       - folder to export raw voltage traces for evaluating 
%                membrane potential variability for quality control.
%              
% profiles       - folder to export cell profiles showing key sweeps. These   
%                figures are designed to provide a quick impression of the
%                cell's biophysical properties. 
%
% QC             - folder to export all results of the quality control
%                analysis. It contains two tables for each individual cell:
%                one table to encode the results in respect of passing or  
%                failing, the other to save the values of all relavant 
%                quality parameters and other additional data for helpful
%                context.
%
% resistance    - folder to export visualizations for determining input    
%                resistance: one for voltage deflection from baseline to   
%                highest deflection, the other one for voltage deflection
%                from baseline to the steady state (postfix: _ss).
%
% tauFit        -folder to export visualizations for determining the               
%               membrane time constant for each individual sweep.
%
% TP            -folder to export plots for manual evaluation of pipette
%               compensation and its changes over time. There are two plots  
%               for each cell: for one, raw voltage traces of test pulses   
%               across the entire recording, the other showing the voltage 
%               data at the onset of the long pulse stimulus.
%
% traces       -folder for the export of downsampled long pulse voltage 
%              traces in a one csv file per cell. This data is for online 
%              display (not actual sharing) of voltage data on an 
%              open-source website.

warning('off'); dbstop error                                               % for troubleshooting errors

if length(varargin) > 2                                                 
          disp('No overwrite mode') 
          overwrite = 0;
          mainFolder = varargin{1};
          outDest = varargin{2};
else
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
params = loadParams;   
params.outDest = outDest;                                                  % save parameters to workspace structure
tic

if ~exist(fullfile(params.outDest, '\peristim'), 'dir')
    mkdir(fullfile(params.outDest, '\peristim'))
    mkdir(fullfile(params.outDest, '\resistance'))
    mkdir(fullfile(params.outDest, '\profiles'))
    mkdir(fullfile(params.outDest, '\firingPattern'))
    mkdir(fullfile(params.outDest, '\QC'))
    mkdir(fullfile(params.outDest, '\traces'))
    mkdir(fullfile(params.outDest, '\betweenSweeps'))
    mkdir(fullfile(params.outDest, '\AP_Waveforms'))
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
  SpPattrn.spTrainIDs = {}; SpPattrn.BinTbl = zeros(0,20);                 % initializing variables to save spike train sweep IDs and bined spike train table
  SpPattrn.RowNames = {};                                                  %
  LP_TracesExport = table();                                               % initializing table for exporting raw data traces as csv 
  
%% Looping through sweeps
    
  IcepysTab = nwb.general_intracellular_ephys_intracellular_recordings;    % assigning IntracellularRecordinsTable to new variable for readability of subsequent code
  ResponseTbl = IcepysTab.responses.response.data.load;                    % loading all sweep response from IntracellularRecordingsTable
    
  for SweepCount = 1:IcepysTab.id.data.dims                                % loop through sweeps of IntracellularRecordinsTable        
     
    SwData = struct();                                                     % initialize  structure for variabels containing sweep specific Data  
      
    SwData.CurrentPath = table2array(ResponseTbl(SweepCount,3)).path;      % get path to sweep within nwb file 
    SwData.CurrentName = ...
      SwData.CurrentPath(find(SwData.CurrentPath=='/',1,'last') ...
          +1:length(SwData.CurrentPath));                                  % extracts name of the sweep
                
    [QC_parameter.SweepID(SweepCount), QCpass.SweepID(SweepCount)] = ...
        deal({SwData.CurrentName});                                        % saves the sweep name in QC tables        
    [QC_parameter.Protocol(SweepCount), QCpass.Protocol(SweepCount)] = ...
           deal(IcepysTab.dynamictable.map('protocol_type' ...
                ).vectordata.values{1}.data.load(SweepCount));             % saves the protocol name/type in QC tables   
   
    if ~contains(IcepysTab.dynamictable.values{...
           1}.vectordata.values{1}.data.load(SweepCount), params.SkipTags) % only continues if protocol name is not on the list in params.SkipTags
                
       CCSeries = nwb.resolve(SwData.CurrentPath);                                % load the CurrentClampSeries of the respective sweep
                       
       SwData.StimOn = double(table2array(ResponseTbl(SweepCount,1)));     % gets stimulus onset from response table 
       SwData.StimOff = double(SwData.StimOn + ...
                                 table2array(ResponseTbl(SweepCount,2)));  % gets end of stimulus from response table 
       
       SwData.sweepAmp = double(IcepysTab.stimuli.vectordata.values{...
                         1}.data.load(SweepCount));                        % gets current amplitude from IntracellularRecordingsTable
       
       %% Sweep-wise analysis
       if contains(CCSeries.stimulus_description, params.LPtags)           % if sweep is a long pulse protocol 
           
           LP_TracesExport = exportSweepCSV(...
               CCSeries, SwData, SweepCount, LP_TracesExport);             % a certain section of the trace is exported as csv  
       end
           
       [QC_parameter, QCpass] = SweepwiseQC(CCSeries, SwData, SweepCount, ...
                                        QC_parameter, QCpass, params);     % Sweep QC of the CurrentClampSeries                              
=======
for n = 1:length(cellList)                                                % for all cells in directory
 nwb = nwbRead(fullfile(cellList(n).folder,cellList(n).name));             % load nwb file
 %% Initialize Cell Variables
 PS.cellID = cellList(n).name(1:length(cellList(n).name)-4);               % cell ID (used for saving data)
 InitCellVars                                                              % Initalizes cell-wide variables
 %% Looping through sweeps    
 for SwpCt = 1:height(RespTbl)                                             % loop through sweeps of IntracellularRecordinsTable             
  InitSweep                                                                % Initalizes sweep-wide variables 
  if ~contains(ProtoTags(SwpCt,:), PS.SkipTags) && ...                     % only continues if protocol name is not on the list in PS.SkipTags AND 
    (~PS.manTPremoval || (PS.manTPremoval  && QC.pass.manTP(SwpCt)))      % (manual sweep removal because of test pulse is not enabled OR manual sweep removal because of test pulse is enabled and sweep passes
            
   CCSers = nwb.resolve(PS.SwDat.CurrentPath);                             % load the CurrentClampSeries of the respective sweep
   PS.SwDat.StimOn = double(table2array(RespTbl(SwpCt,1)));                % gets stimulus onset from response table 
   PS.SwDat.StimOff = double(...
                          PS.SwDat.StimOn + table2array(RespTbl(SwpCt,2)));% gets end of stimulus from response table  
   PS.SwDat.swpAmp = ICEtab.stimuli.vectordata.values{1}.data.load(SwpCt); % gets current amplitude from IntracellularRecordingsTable
                     
   if contains(CCSers.stimulus_description, PS.LPtags) && PS.Webexport==1  % if sweep is a long pulse protocol           
     LPexport = exportSweepCSV(CCSers, PS.SwDat, SwpCt, LPexport);         % a certain section of the trace is exported as csv  
   end
   %% Sweep-wise analysis          
   QC = SweepwiseQC(CCSers, PS, QC, SwpCt);                                % Sweep QC of the CurrentClampSeries                              
                               
       if SwData.sweepAmp > 0                                              % if current input is depolarizing

          [module_spikes, sp, SpQC, QCpass] = ...
                 processSpikes(CCSeries, SwData, params, supraCount, ...
                                 module_spikes, SpQC, QCpass, SweepCount); % detection and processing of spikes 

            if ~isempty(sp) && length(sp.peak) > 1                         % if sweep has more than one spike
                 SpPattrn.spTrainIDs(supraCount,1) = {SwData.CurrentName}; % sweep name is saved under spike train IDs
                 SpPattrn = estimateAPTrainParams(... 
                       sp,SwData.StimOn,CCSeries, supraCount, SpPattrn);   % getting spike train parameters
            end
            supraCount = supraCount + 1;                         

            elseif SwData.sweepAmp < 0                                     % if current input is hyperpolarizing
               module_subStats = subThresFeatures(CCSeries, SwData, ...
                                                  module_subStats, params);% getting subthreshold parameters                          
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
       nwb.processing.get('subthreshold parameters').dynamictable, params);% calculate input resistance before QC 
   QCpass.bridge_balance_rela = ...
       QC_parameter.bridge_balance_rela < Ri_preqc*params.factorRelaRa;    % check if input resistance meets relatice bridge balance criterium
   
   %% Between Sweep QC
   [QCpass.betweenSweep, QC_parameter.betweenSweep ] = ...
       BetweenSweepQC(QC_parameter, BwSweepMode, params);                  % execute betweenSweep QC 
   
   %% save SpikeQC in ragged array    

   %% Save QC results in Sweeptable and external   
   QCpass.bad_spikes(isnan(QCpass.bad_spikes)) = 1;                        % replace nans with 1s for pass in the bad spike column these are from sweeps without sweeps
   QCparameterTotal.(['ID_' params.cellID ]) = QC_parameter;               % add QC parameter table of the cell to structure for saving those  
   QCpassTotal.(['ID_' params.cellID  ]) = QCpass;                         % add QC pass table of the cell to structure for saving those  
   tbl = util.table2nwb(QC_parameter, 'QC parameter table');               % convert QC parameter to DynamicTable
   module_QC.dynamictable.set('QC_parameter_table', tbl);                  % add DynamicTable to QC processing module
   nwb.processing.set('QC parameter', module_QC);                          % add QC processing module to nwb object
   keys = IcepysTab.dynamictable.map(...
    'quality_control_pass').vectordata.keys;                               % Get columns of quality control section of IntracellularRecordingTable
   
  for s = 1:height(QCpass)                                                 % loop through sweeps/rows of QC pass table
      if  sum(isnan(QCpass{s,4:14})) == 0 && sum(QCpass{s,4:14}) == 11     % Condition 1: QC pass columns do not contain NaN. Condition 2: All columns have to contain 1
          QCpass(s,3) = {1};
      elseif sum(isnan(QCpass{s,4:14})) > 3                                % If row contains more than 3 NaNs the sweep is not QC-able and the total pass parameter should be NaN as well
          QCpass(s,3) = {NaN};
      else
         QCpass(s,3) = {0};                                                % sweep has not passed the total QC
      end
  if str2double(info.values{1}.('initial_access_resistance')) ...
    <= PS.cutoffInitRa && str2double(info.values{1}.('initial_access_resistance')) ...                                        
                 <= Ri_preqc*PS.factorRelaRa                               % if ini access resistance is below absolute and relative threshold     

          [ICsummary, PS] = LPsummary(nwb, ICsummary, n, PS);              % extract features from long pulse stimulus
          [ICsummary, PS] = SPsummary(nwb, ICsummary, n, PS);              % extract features from short pulse stimulus
          plotCellProfile(nwb, PS)                                         % plot cell profile 
          plotSanityChecks(QC, PS, ICsummary, n, ICEtab)
       else 
           disp(['excluded by cell-wide QC for initial Ra (', ...
                 num2str(info.values{1}.('initial_access_resistance')),...
                ') higher than realtive cutoff (', ...
                      num2str(Ri_preqc*PS.factorRelaRa), ...
                ') or absolute cutoff (', num2str(PS.cutoffInitRa),')'... 
                  ]);
           QCcellWide{end+1} = PS.cellID ;                                 % save cellID for failing cell-wide QC
       end        
  else
     [ICsummary, PS] = LPsummary(nwb, ICsummary, n, PS);                   % extract features from long pulse stimulus 
     [ICsummary, PS] = SPsummary(nwb, ICsummary, n, PS);                   % extract features from short pulse stimulus 
     plotCellProfile(nwb, PS)                                              % plot cell profile
     plotSanityChecks(QC ,PS, ICsummary, n, ICEtab)
     disp('No initial access resistance available') 
  end    
  if isnan(ICsummary.thresLP(n)) && PS.noSupra == 1                        % if there is no AP features such as threshold and no suprathreshold traces is cell wide exclusion criterium
        disp('excluded by cell-wide QC for no suprathreshold data') 
        ICsummary(n,1:7) = {NaN};                                          % replace subthreshold features with NaNs
        QCcellWide{end+1} = PS.cellID ;                                    % save cellID for failing cell-wide QC
  end
  for t = 1:length(keys)                                                   %loop columns of QC pass 
    if any(contains(fieldnames(QCpass),keys(t)))
        IcepysTab.dynamictable.values{...
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
              length(info.values{1}.('initial_access_resistance')) < 3     % if ini access resistance is non empty and smaller than 3 characters
      
       if str2double(info.values{1}.('initial_access_resistance')) ...
                <= params.cutoffInitRa  && ...                             % if ini access resistance is below absolute and relative threshold
          str2double(info.values{1}.('initial_access_resistance')) ...
                 <= Ri_preqc*params.factorRelaRa

           [nwb, ICsummary, PlotStruct] = LPsummary(nwb, ICsummary, n,...
                                                       params);            % extract features from long pulse stimulus
           [nwb, ICsummary, PlotStruct] =  SPsummary(nwb, ICsummary, n,...
                                            params, PlotStruct);           % extract features from short pulse stimulus

           plotCellProfile(nwb, PlotStruct, params)                        % plot cell profile 
       else
           display(['excluded by cell-wide QC for Ra higher than ', ...
                  num2str(Ri_preqc*params.factorRelaRa), ' or ',...
                   num2str(params.cutoffInitRa )]);
           QCcellWide{end+1} = params.cellID ;                             % save cellID for failing cell-wide QC
       end  
       
   else
       [nwb, ICsummary, PlotStruct] = LPsummary(nwb, ICsummary, n, params);% extract features from long pulse stimulus 
       [nwb, ICsummary, PlotStruct] = SPsummary(nwb, ICsummary, ...
                                                   n, params, PlotStruct); % extract features from short pulse stimulus 
       plotCellProfile(nwb, PlotStruct, params)                            % plot cell profile
       disp('No initial access resistance available') 
   end    
   if isnan(ICsummary.thresholdLP(n)) && params.noSupra == 1               % if there is no AP features such as threshold and no suprathreshold traces is cell wide exclusion criterium
         disp('excluded by cell-wide QC for no suprathreshold data') 
         ICsummary(n,1:7) = {NaN};                                         % replace subthreshold features with NaNs
         QCcellWide{end+1} = params.cellID ;                               % save cellID for failing cell-wide QC
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
  %% Write NWB file
 if  ~any(contains(QCcellWide,PS.cellID))                                  % if the cell is not excluded by cell wide QC
   if overwrite == 1
      disp(['Overwriting file ', cellList(n).name])
       nwbExport(nwb, fullfile(PS.outDest, '\', cellList(n).name))        % export nwb object as file
   elseif isfile(fullfile(PS.outDest, '\', cellList(n).name))      
      delete(fullfile(PS.outDest, '\', cellList(n).name));
      disp(['Overwriting file ', cellList(n).name, ' in output folder'])
      nwbExport(nwb, fullfile(PS.outDest, '\', cellList(n).name))          % export nwb object as file 
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
           fullfile(params.outDest, '\traces\', [nwb.identifier, '.csv'])) % export table of raw sweep data as csv
  end
  
  if  ~any(contains(QCcellWide,params.cellID))                             % if the cell is not excluded by cell wide QC
      if overwrite == 1
          disp(['Overwriting file ', cellList(n).name])
          nwbExport(nwb, fullfile(params.outDest, '\', cellList(n).name))  % export nwb object as file
      elseif isfile(fullfile(params.outDest, '\', cellList(n).name))      
          delete(fullfile(params.outDest, '\', cellList(n).name));
          disp(['Overwriting file ', cellList(n).name, ' in output folder'])
          nwbExport(nwb, fullfile(params.outDest, '\', cellList(n).name))  % export nwb object as file 
      else
          nwbExport(nwb, fullfile(params.outDest, '\', cellList(n).name))  % export nwb object as file
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

