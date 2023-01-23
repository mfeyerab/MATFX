function icSum = runPipeline(varargin) %{
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

if length(varargin) > 1                                                
     disp('No overwrite mode') 
     overwrite = 0;
     mainFolder = varargin{1};
     outDest = varargin{2};
else
     disp('Overwrite mode') 
     [outDest, mainFolder] = deal(varargin{1});
     overwrite = 1;
end    
InitRun;                                                                   % Initalizes run-wide variables
tic
%% Looping through nwb files
for n = 98:length(cellList)                                                 % for all cells in directory
 PS.cellID = cellList(n).name(1:length(cellList(n).name)-4);               % cell ID (used for saving data)
 InitCellVars                                                              % Initalizes cell-wide variables
 if PS.manTPremoval && all(TPtab.TP(~isnan(TPtab.TP))==0)                  % If all sweeps failed manual review
   disp([PS.cellID, ' skipped'])                                           % skipp the cell
 else
 nwb = nwbRead(fullfile(cellList(n).folder,cellList(n).name));             % load nwb file
 %% Initialize QC
 QC.params = table(); 
 QC.pass = table(); 
 QC.testpulse = cell(0,0);                                                 % creating empty MATLAB table for QC paramters

 QC.params.SweepID = repmat({''},length(nwb.acquisition.keys),1);          % initializing SweepID column of QC paramters table
 QC.params.Protocol = repmat({''},length(nwb.acquisition.keys),1);         % initializing Protocol column of QC paramters table
 QC.params(:,3:length(qc_tags(2:end))+2) = array2table(NaN(...         
    length(nwb.acquisition.keys), length(qc_tags)-1));                     % initializing actual parameter variables with NaNs
 QC.params.Properties.VariableNames(3:width(QC.params)) = ...        
      [qc_tags(3:end), {'CapaComp'}];                                      % naming parameter variables

 QC.pass.SweepID = repmat({''},length(nwb.acquisition.keys),1);            % initializing SweepID column of QC passing table 
 QC.pass.Protocol = repmat({''},length(nwb.acquisition.keys),1);           % initializing Protocol column of QC passing table
 QC.pass(:,3:length(qc_tags)+2) = ...
      array2table(NaN(length(nwb.acquisition.keys), length(qc_tags)));     % initializing logic values for passing table
 QC.pass.Properties.VariableNames(3:width(QC.pass)-1) = qc_tags(2:end);    % naming passing parameters variables
 QC.pass.Properties.VariableNames(width(QC.pass)) = {'manuTP'};            % initializing additional variable for sweep wise QC encoding manual test pulse review

 if PS.manTPremoval
   QC.pass.manuTP = TPtab.TP;                                              % assign binary from results of test pulse review to QC pass table
 end

 if ~isempty(nwb.general_devices.values{1}.manufacturer) &&...             % determines if cell was recorded on HEKA amplifier          
     contains(nwb.general_devices.values{1}.manufacturer,'Heka')
     PS.isHeka = true;
 else
     PS.isHeka = false;
 end
 %% Improve readability by creating additonal variables with shorter names
 ICEtab = nwb.general_intracellular_ephys_intracellular_recordings;        % assigning IntracellularRecordinsTable to new variable for readability of subsequent code
 if isempty(ICEtab)
     disp([nwb.identifier ' is empty. Cell will be skipped.'])
     continue
 end
     
 RespTbl = ICEtab.responses.response.data.load;                            % loading all sweep response from IntracellularRecordingsTable
 ProtoTags = deblank(string(...
             ICEtab.dynamictable.values{1}.vectordata.values{1}.data.load));% Gets all protocol names without white space
 info = nwb.general_intracellular_ephys;   
 %% Initialize processing moduls and new columns for Sweep table
 initProceModules                                                          % initialize processing modules
 nwb  = addColumns2SwTabl(nwb,qc_tags);                                    % add initialized QC to sweep table 
 %% Looping through sweeps    
 for SwpCt = 1:ICEtab.id.data.dims                                         % loop through sweeps of IntracellularRecordinsTable             
  InitSweep                                                                % Initalizes sweep-wide variables 
  if ~contains(ProtoTags(SwpCt,:), PS.SkipTags) && ...                     % only continues if protocol name is not on the list in PS.SkipTags AND 
  (~PS.manTPremoval || (PS.manTPremoval  && QC.pass.manuTP(SwpCt)))        % (manual sweep removal because of test pulse is not enabled OR manual sweep removal because of test pulse is enabled and sweep passes

   CCSers = nwb.resolve(PS.SwDat.CurrentPath);                             % load the CurrentClampSeries of the respective sweep
   PS.SwDat.StimOn = double(table2array(RespTbl(SwpCt,1)));                % gets stimulus onset from response table 
   PS.SwDat.StimOff = double(...
                          PS.SwDat.StimOn + table2array(RespTbl(SwpCt,2)));% gets end of stimulus from response table  
   PS.SwDat.swpAmp = ICEtab.stimuli.vectordata.values{1}.data.load(SwpCt); % gets current amplitude from IntracellularRecordingsTable
                     
   if contains(CCSers.stimulus_description, PS.LPtags) && PS.Webexport==1  % if sweep is a long pulse protocol           
     LPexport = exportSweepCSV(CCSers, PS.SwDat, SwpCt, LPexport);         % a certain section of the trace is exported as csv  
   end  
   %% Sweep-wise analysis          
   if (PS.([char(ProtoTags(SwpCt,:)),'qc_recovTime'])+ ...                 % checks if the sweep is of sufficient size for the respective protocol
        PS.([char(ProtoTags(SwpCt,:)),'length']))*CCSers.starting_time_rate...
        < length(CCSers.data.load)                                                  
          
     QC = SweepwiseQC(CCSers, PS, QC, SwpCt, LPfilt);                      % Sweep QC of the CurrentClampSeries                              
                               
     if PS.SwDat.swpAmp > 0                                                % if current input is depolarizing

       [modSpikes,sp,QC] = processSpikes(CCSers,PS,modSpikes,SwpCt, QC);   % detection and processing of spikes 
    
       if ~isempty(sp) && ~isempty(sp.peak) && ProtoTags(SwpCt,:)=="LP"    % if sweep has more than one spike
         SpPattrn.spTrainIDs(PS.supraCount,1) = {PS.SwDat.CurrentName};    % sweep name is saved under spike train IDs
         SpPattrn = estimateAPTrainParams(CCSers, sp, PS, SpPattrn);       % getting spike train parameters
         PS.supraCount = PS.supraCount + 1;                         
       elseif ProtoTags(SwpCt,:)=="LP"                                     % if no spikes have been detected and protocol is long pulse
         modSubStats = subThresFeatures(CCSers,modSubStats,PS,LPfilt);     % getting subthreshold parameters                          
         PS.subCount = PS.subCount +1;
       end
     elseif ProtoTags(SwpCt,:)=="LP" 
         modSubStats = subThresFeatures(CCSers,modSubStats,PS,LPfilt);     % getting subthreshold parameters                          
         PS.subCount = PS.subCount +1;
     end
   else
       disp([PS.SwDat.CurrentPath, ...
           ' has insufficient length for QC analysis'])
   end
  end
 end
 %% Finishing QC (relative Ra, between sweep) and saving results
 QC = BetweenSweepQC(QC, PS);                                              % execute betweenSweep QC  
 [~,tempRin,~] = getRin(modSubStats.dynamictable.values{1}, PS, ...
                        find(~any(QC.pass{:,4:end}==0,2))-1);                % calculate input resistance before final QC 
 if  PS.isHeka
     QC.pass.bridge_balance_rela(SwpCt) = true;
 else
     QC.pass.bridge_balance_rela = ...
       QC.params.bridge_balance_abs < tempRin*PS.factorRelaRa;             % check if input resistance meets relatice bridge balance criterium
     QC.params.bridge_balance_rela = ones(height(QC.params),1)* ...
     tempRin*PS.factorRelaRa;
 end
 QC.pass = convertvars(QC.pass, 'bridge_balance_rela','double');

 saveProcessedCell                                                         % Save QC into nwb file and summary structures
 %% Cell-wise QC 1: initial access resistance
 InitRa = info.values{1}.('initial_access_resistance');
 QCcellWise.ID(n) = {PS.cellID};                                           % save cellID for failing cell-wide QC
 QCcellWise.Vm(n) =  {median(QC.params.Vrest(1:3))};                       % 
 QCcellWise.Ra(n) =  {InitRa};                                             % 
 QCcellWise.Fail(n) = 0;                                                   %  
 if PS.InitRa && ~isempty(InitRa) && ...
         length(regexp(InitRa,'\d*','Match')) >= 1                         % if ini access resistance is non empty and has a number as character
   InitRa = str2double(InitRa);
   if InitRa > PS.cutoffInitRa && InitRa > tempRin*PS.factorRelaRa        % if ini access resistance is below absolute and relative threshold 
     display(['excluded by cell-wide QC for initial Ra (', ...
        num2str(InitRa),') higher than relative cutoff (', ...
        num2str(tempRin*PS.factorRelaRa), ') or absolute cutoff (', ...
        num2str(PS.cutoffInitRa),')']);
        QCcellWise.Fail(n) = 1;                                            % save cellID for failing cell-wide QC
   end
 else
     disp('No QC by initial access resistance or value not available') 
 end
 %% Feature Extraction and Summary     
 if QCcellWise.Fail(n)==0
      [icSum, PS] = LPsummary(nwb, icSum, n, PS);                          % extract features from long pulse stimulus
      [icSum, PS] = SPsummary(nwb, icSum, n, PS);                          % extract features from short pulse stimulus
      plotCellProfile(nwb, PS)                                             % plot cell profile 
      if PS.plot_all >0
       plotSanityChecks(QC, PS, icSum, n, ICEtab)
      end
 end  
  %% Cell-wise QC 2: Too depolarized after breaktrough
 if isnan(icSum.RinSS(n))
    QCcellWise.VmCutOff(n) = {PS.maxCellBasLinPot + ...
     (QC.params.holdingI(1)*1e-09*6*sqrt(icSum.RinHD(n))*1e06)};  
 else
     QCcellWise.VmCutOff(n) = {PS.maxCellBasLinPot + ...
     (QC.params.holdingI(1)*1e-09*6*sqrt(icSum.RinSS(n))*1e06)};    
 end 
 QCcellWise.Rm(n) =  {icSum.RinSS(n)};
 if QCcellWise.Vm{n} > QCcellWise.VmCutOff{n}
    disp("first recorded Vrest after breakthrough too depolarized")
    QCcellWise.Fail(n) = 1; 
    icSum(n,1:end-8) = {NaN};
    theFiles = dir(fullfile(PS.outDest, ['**\*',PS.cellID,'*']));
 end
 %% Cell-wise QC 3: No suprathreshold LP sweeps 
 if QCcellWise.Fail(n)~= 1  && PS.noSupraSub == 1 &&  ...                        % if there is no AP features such as threshold and no suprathreshold traces is cell wide exclusion criterium
       (isnan(icSum.thresLP(n)) || isnan(icSum.RinHD(n)))                               
    disp('excluded by cell-wide QC for no suprathreshold data') 
     QCcellWise.Fail(n) = 1; 
     icSum{n,1:end-8}=NaN;
     theFiles = dir(fullfile(PS.outDest, ['**\*',PS.cellID,'*']));
 end
 if QCcellWise.Fail(n)== 1 && exist('theFiles')
   for k = 1 : length(theFiles)
       delete(fullfile(theFiles(k).folder,theFiles(k).name));
   end
 end%
%% Add subject data, dendritic type and reporter status   
%  AddSubjectCellData 
%% Export downsampled traces for display on website  
 if PS.Webexport==1 && ~isempty(LPexport)                                  % if there raw traces in the table for export
     WebExportCell
 end
  %% Write NWB file
 if QCcellWise.Fail(n)==0                                                  % if the cell is not excluded by cell wide QC
   if overwrite == 1
      disp(['Overwriting file ', cellList(n).name])
      %nwbExport(nwb, fullfile(PS.outDest, '\', cellList(n).name))          % export nwb object as file
   elseif isfile(fullfile(PS.outDest, '\', cellList(n).name))      
      delete(fullfile(PS.outDest, '\', cellList(n).name));
      disp(['Overwriting file ', cellList(n).name, ' in output folder'])
      %nwbExport(nwb, fullfile(PS.outDest, '\', cellList(n).name))          % export nwb object as file 
   else
      %nwbExport(nwb, fullfile(PS.outDest, '\', cellList(n).name))          % export nwb object as file
      disp(['saving file ', cellList(n).name, ' in output folder'])
   end
 else
   disp([cellList(n).name, ' not saved for failing cell-wide QC'])
 end
 close all;
 rm = javax.swing.RepaintManager.currentManager([]);
 dim = rm.getDoubleBufferMaximumSize();
 rm.setDoubleBufferMaximumSize(java.awt.Dimension(0,0));  % clear
 rm.setDoubleBufferMaximumSize(dim);  %restore original dim
 java.lang.System.gc();  % garbage-collect
 toc
 end
end                                                                        % end cell level for loop
%% Output summary fiels and figures 
Summary_output_files
end