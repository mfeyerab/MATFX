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
PS = loadParams; PS.preTP= 0.015; PS.TPtrace = 0.08;

%% Looping through cells
for n = 1:length(cellList)                                                 % for all cells in directory
 cellID = cellList(n).name(1:length(cellList(n).name)-4);                  % cell ID (used for saving data)
 if ~isfile(fullfile(path,'inputTabsTP',[cellID,'_TP.csv']))
   nwb = nwbRead(fullfile(cellList(n).folder,cellList(n).name));         % load nwb file
   %% Improve readability by creating additonal variables with shorter names
   ICEtab = nwb.general_intracellular_ephys_intracellular_recordings;        % assigning IntracellularRecordinsTable to new variable for readability of subsequent code
   RespTbl = ICEtab.responses.response.data.load;                            % loading all sweep response from IntracellularRecordingsTable
   %% Initalizing cell variables
   Idx = find(~contains(string(...
         ICEtab.dynamictable.values{1}.vectordata.values{1}.data.load),...
                   PS.SkipTags));
   QC.pass = table(); 
   temp = regexp({RespTbl.timeseries.path},'\w*','match');
   QC.pass.SweepID = cellfun(@(z)z(2),temp(Idx))';
   QC.pass.Protocol = ICEtab.dynamictable.values{...
                                   1}.vectordata.values{1}.data.load(Idx)';
   QC.testpulse = zeros(length(Idx),(PS.preTP+PS.TPtrace)*...
         nwb.acquisition.values{Idx(1)}.starting_time_rate);    
   QC.pass.TP =  repmat({NaN},length(Idx),1);
   if contains(cellID, "JR")
        QC.pass.TP = ones(height(QC.pass),1); 
   else
     for i = 1:length(Idx)
      CurrentPath = table2array(RespTbl(Idx(i),3)).path;                        % get path to sweep within nwb file  
      PreStimData = nwb.resolve(ICEtab.stimuli.stimulus.data.load(...
           ).timeseries(Idx(i)).path).data.load(1:RespTbl{Idx(i),1}-OnsetBuffer); 
      temp = regexp(CurrentPath,'\w*','match'); 
      QC.pass.SweepID(Idx(i),:) = temp(length(temp));
      QC.pass.Protocol(Idx(i),:) = ICEtab.dynamictable.values{...
                                1}.vectordata.values{1}.data.load(i); 
                                      CCSers = nwb.resolve(CurrentPath);                                       % load the CurrentClampSeries of the respective sweep   
      PS.SwDat.CurrentName = CurrentPath;
      if range(PreStimData)<15
         disp([CurrentPath, 'has no test pulse'])
         QC.pass.TP = ones(height(QC.pass),1);
      else
        [~, QC.testpulse(Idx(i),:)] = getTestPulse(PS,CCSers, PreStimData);         
      end
     end
     tempTPvec = QC.testpulse; save('tempTPvec', 'tempTPvec'); TestPulseComparision
     prompt = ' from which sweep onwards are test pulses unacceptable? Enter 0 if no manual removal necessary';
     x = input(['For ', cellID, prompt]);
     if x == 0
      QC.pass.TP = ones(height(QC.pass),1);
     else
      QC.pass.TP = [ones(x-1,1); zeros(height(QC.pass)-x+1,1)];
     end
  end
  writetable(QC.pass, fullfile(path,'inputTabsTP',[cellID,'_TP.csv']))
  disp(['exporting ', cellID])
  close all
 end
end