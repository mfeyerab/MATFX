function SweepRemovalTP(path)
% function for removing sweeps manually according to the test pulse and its
% change over time
%
%
%
%

%% Start
cellList = dir([path,'\','*.nwb']);                                        % list of cell data files
cellList = cellList(~[cellList.isdir]);
OnsetBuffer = 20;                                                               % number of samples to substract in case of poor stim onset detection
if ~exist(fullfile(path, 'inputTabsTP'), 'dir')
    mkdir(fullfile(path, 'inputTabsTP')) 
end
run(fullfile(path, 'loadParams.m')); PS = ans; 
PS.preTP= 0.015; PS.TPtrace = 0.08;

%% Looping through cells
for n = 488:length(cellList)                                                 % for all cells in directory
 cellID = cellList(n).name(1:length(cellList(n).name)-4);                  % cell ID (used for saving data)
 if ~isfile(fullfile(path,'inputTabsTP',[cellID,'_TP.csv']))
   nwb = nwbRead(fullfile(cellList(n).folder,cellList(n).name));         % load nwb file
   %% Improve readability by creating additonal variables with shorter names
   ICEtab = nwb.general_intracellular_ephys_intracellular_recordings;      % assigning IntracellularRecordinsTable to new variable for readability of subsequent code
   RespTbl = ICEtab.responses.response.data.load;                          % loading all sweep response from IntracellularRecordingsTable
   %% Initalizing cell variables
   Idx = find(~contains(string(ICEtab.vectordata.values{1}.data.load),...
                   PS.SkipTags));
   QC.pass = table(); 
   temp = regexp({RespTbl.timeseries.path},'\w*','match');
   QC.pass.SweepID = cellfun(@(z)z(2),temp)';
   QC.pass.Protocol = ICEtab.vectordata.values{1}.data.load;
   SmplRt = nwb.resolve(RespTbl.timeseries(Idx(1)).path).starting_time_rate;
   QC.testpulse = zeros(length(Idx),(PS.preTP+PS.TPtrace)*SmplRt);    
   QC.pass.TP =  repmat({NaN},ICEtab.responses.id.data.dims,1);
   for i = 1:length(Idx)
     CurrentPath = RespTbl.timeseries(Idx(i)).path;                        % get path to sweep within nwb file  
     StimOn = RespTbl.idx_start(Idx(i));
     PreStimData = nwb.resolve(ICEtab.stimuli.stimulus.data.load(...
       ).timeseries(Idx(i)).path).data.load(1:StimOn-OnsetBuffer); 
     CCSers = nwb.resolve(CurrentPath);                                    % load the CurrentClampSeries of the respective sweep   
     PS.SwDat.CurrentName = CurrentPath;
     if range(PreStimData)<15
       disp([CurrentPath, ' has no test pulse'])
     else
       [~, QC.testpulse(Idx(i),:)] = getTestPulse(PS,CCSers, PreStimData);         
     end
   end
   if all(QC.testpulse==0, 'all')
      QC.pass.TP(Idx) = num2cell(ones(length(Idx),1)); 
      disp(['No TP review'])
   else
      tempTPvec = QC.testpulse; save('tempTPvec', 'tempTPvec'); 
      TestPulseComparision
      prompt = ' from which sweep onwards are test pulses unacceptable? Enter 0 if no manual removal necessary';
      x = input(['For ', cellID, prompt]);
      if x == 0
        QC.pass.TP(Idx) = num2cell(ones(length(Idx),1));
      else
        QC.pass.TP(Idx) = num2cell([ones(x-1,1); zeros(length(Idx)-x+1,1)]);
      end
   end
   writetable(QC.pass, fullfile(path,'inputTabsTP',[cellID,'_TP.csv']))
   disp(['exporting ', cellID])
   close all
 end
end