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

PS = struct(); PS.preTP= 0.015; PS.TPtrace = 0.08;

%% Looping through cells
for n = 1:length(cellList)                                                 % for all cells in directory
 cellID = cellList(n).name(1:length(cellList(n).name)-4);                  % cell ID (used for saving data)
 if ~isfile(fullfile(path,'inputTabsTP',[cellID,'_TP.csv']))
     nwb = nwbRead(fullfile(cellList(n).folder,cellList(n).name));         % load nwb file
     %% Improve readability by creating additonal variables with shorter names
     ICEtab = nwb.general_intracellular_ephys_intracellular_recordings;        % assigning IntracellularRecordinsTable to new variable for readability of subsequent code
     RespTbl = ICEtab.responses.response.data.load;                            % loading all sweep response from IntracellularRecordingsTable
    %% Initalizing cell variables
     QC.testpulse = zeros(ICEtab.id.data.dims,(PS.preTP+PS.TPtrace)*...
         nwb.acquisition.values{1}.starting_time_rate+1); 
     QC.pass = table(); 
     QC.pass.SweepID = repmat({''},length(nwb.acquisition.keys),1);            % initializing SweepID column of QC passing table 
     QC.pass.Protocol = repmat({''},length(nwb.acquisition.keys),1);           % initializing Protocol column of QC passing table
     QC.pass.TP =  repmat({NaN},length(nwb.acquisition.keys),1);

     for SwpCt = 1:ICEtab.id.data.dims 
      CurrentPath = table2array(RespTbl(SwpCt,3)).path;                        % get path to sweep within nwb file  
      PreStimData = nwb.resolve(ICEtab.stimuli.stimulus.data.load(...
           ).timeseries(SwpCt).path).data.load(1:RespTbl{SwpCt,1}-OnsetBuffer);
      CCSers = nwb.resolve(CurrentPath);                                       % load the CurrentClampSeries of the respective sweep   
      PS.SwDat.CurrentName = CurrentPath;
      [~, QC.testpulse(SwpCt,:)] = getTestPulse(PS,CCSers, PreStimData);  
      temp = regexp(CurrentPath,'\w*','match');
      QC.pass.SweepID(SwpCt,:) = temp(length(temp));
      QC.pass.Protocol(SwpCt,:) = ICEtab.dynamictable.values{...
                                  1}.vectordata.values{1}.data.load(SwpCt); 
     end
     temp = QC.testpulse; save('temp', 'temp'); TestPulseComparision
     prompt = ' from which sweep onwards are test pulses unacceptable? Enter 0 if no manual removal necessary';
     x = input(['For ', cellID, prompt]);
     if x == 0
         QC.pass.TP = ones(height(QC.pass),1);
     else
         QC.pass.TP = [ones(x-1,1); zeros(height(QC.pass)-x+1,1)];
     end
     writetable(QC.pass, fullfile(path,'inputTabsTP',[cellID,'_TP.csv']))
     disp(['exporting ', cellID])
     close all
 end
end