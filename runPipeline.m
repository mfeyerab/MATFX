function ICsummary = runPipeline(varargin) %{
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

warning('off'); dbstop if error                                            % for troubleshooting errors

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
        BwSwpMode = varargin{length(varargin)};    
        if BwSwpMode == 1
            disp('between sweep QC with a set target value')
        elseif BwSwpMode == 2
            disp('between sweep QC without a set target value')
        else
            error('Please use int 1 or 2 as for respective between sweep QC')
        end
else
   error('No number inputed for between sweep QC')
end
InitRun;                                                                   % Initalizes run-wide variables
tic
%% Looping through nwb files
for n = 1:length(cellList)                                                 % for all cells in directory
 nwb = nwbRead(fullfile(cellList(n).folder,cellList(n).name));             % load nwb file
 %% Initialize Cell Variables
 PS.cellID = cellList(n).name(1:length(cellList(n).name)-4);               % cell ID (used for saving data)
 InitCellVars                                                              % Initalizes cell-wide variables
 %% Looping through sweeps    
 for SwpCt = 1:ICEtab.id.data.dims                                         % loop through sweeps of IntracellularRecordinsTable           
     
  InitSweep                                                                % Initalizes sweep-wide variables 
  if ~contains(ProtoTags(SwpCt,:), PS.SkipTags)                              % only continues if protocol name is not on the list in PS.SkipTags
                
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
                               
   if PS.SwDat.swpAmp > 0                                                  % if current input is depolarizing

    [modSpikes,sp,QC] = processSpikes(CCSers,PS,modSpikes,SwpCt, QC);      % detection and processing of spikes 
    
    if ~isempty(sp) && length(sp.peak) > 0                                 % if sweep has more than one spike
      SpPattrn.spTrainIDs(PS.supraCount,1) = {PS.SwDat.CurrentName};       % sweep name is saved under spike train IDs
      SpPattrn = estimateAPTrainParams(CCSers, sp, PS, SpPattrn);          % getting spike train parameters
    end
    PS.supraCount = PS.supraCount + 1;                         

   elseif PS.SwDat.swpAmp < 0                                              % if current input is hyperpolarizing
    modSubStats = subThresFeatures(CCSers,modSubStats,PS);                 % getting subthreshold parameters                          
    PS.subCount = PS.subCount +1;
   end
  end    
 end
 %% QC bridge balance relative to input resistance
 Ri_preqc = inputResistance(modSubStats.dynamictable, PS);                 % calculate input resistance before QC 
 QC.pass.bridge_balance_rela = ...
       QC.params.bridge_balance_abs < Ri_preqc*PS.factorRelaRa;            % check if input resistance meets relatice bridge balance criterium
 QC.params.bridge_balance_rela = ones(height(QC.params),1)* ...
     Ri_preqc*PS.factorRelaRa;
 QC.pass = convertvars(QC.pass, 'bridge_balance_rela','double');
 %% Between Sweep QC
 QC = BetweenSweepQC(QC, BwSwpMode, PS);                                   % execute betweenSweep QC  
 %% Save QC into nwb file and summary structures
 saveProcessedCell
 %% Feature Extraction and Summary
 if ~isempty(info.values{1}.('initial_access_resistance')) && length(...
   regexp(info.values{1}.('initial_access_resistance'),'\d*','Match')) >= 1% if ini access resistance is non empty and has a number as character
      
  if str2double(info.values{1}.('initial_access_resistance')) ...
    <= PS.cutoffInitRa && str2double(info.values{1}.('initial_access_resistance')) ...                                        
                 <= Ri_preqc*PS.factorRelaRa                               % if ini access resistance is below absolute and relative threshold     

          [ICsummary, PS] = LPsummary(nwb, ICsummary, n, PS);              % extract features from long pulse stimulus
          [ICsummary, PS] =  SPsummary(nwb, ICsummary, n, PS);             % extract features from short pulse stimulus
          plotCellProfile(nwb, PS)                                         % plot cell profile 
          plotSanityChecks(QC, PS, ICsummary, n)
       else 
           display(['excluded by cell-wide QC for initial Ra (', ...
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
     plotSanityChecks(QC ,PS, ICsummary, n)
     disp('No initial access resistance available') 
  end    
  if isnan(ICsummary.thresLP(n)) && PS.noSupra == 1                        % if there is no AP features such as threshold and no suprathreshold traces is cell wide exclusion criterium
        disp('excluded by cell-wide QC for no suprathreshold data') 
        ICsummary(n,1:7) = {NaN};                                          % replace subthreshold features with NaNs
        QCcellWide{end+1} = PS.cellID ;                                    % save cellID for failing cell-wide QC
  end
  %% Add subject data, dendritic type and reporter status   
   AddSubjectCellData 
  %% Export downsampled traces for display on website  
  if PS.Webexport==1 && ~isempty(LPexport)                                 % if there raw traces in the table for export
       exportCells
  end
  %% Write NWB file
 if  ~any(contains(QCcellWide,PS.cellID))                                  % if the cell is not excluded by cell wide QC
   if overwrite == 1
      disp(['Overwriting file ', cellList(n).name])
      nwbExport(nwb, fullfile(PS.outDest, '\', cellList(n).name))          % export nwb object as file
   elseif isfile(fullfile(PS.outDest, '\', cellList(n).name))      
      delete(fullfile(PS.outDest, '\', cellList(n).name));
      disp(['Overwriting file ', cellList(n).name, ' in output folder'])
      nwbExport(nwb, fullfile(PS.outDest, '\', cellList(n).name))          % export nwb object as file 
   else
      nwbExport(nwb, fullfile(PS.outDest, '\', cellList(n).name))          % export nwb object as file
      disp(['saving file ', cellList(n).name, ' in output folder'])
   end
 else
   disp([cellList(n).name, ' not saved for failing cell-wide QC'])
 end
 toc
end                                                                        % end cell level for loop
%% Output summary fiels and figures 
Summary_output_files
end