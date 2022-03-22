function ICsummary = runPipeline(varargin) %{

warning('off'); dbstop if error                                            % for troubleshooting errors
%{ 
Runs analysis pipeline on all nwb files in the path indicated as first input argument.
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
  if ~contains(ProtoTags(SwpCt), PS.SkipTags)                              % only continues if protocol name is not on the list in PS.SkipTags
                
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