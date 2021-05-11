%{
processICsweepsParFor
- analysis of intracellular hyperpolarizing and depolarizing sweeps
%}
mainFolder = 'C:\Users\mjimenez\Documents\GitHub\QC_PCTD\';            % main folder (EDIT HERE)
start = 1;

outDest = 'C:\Users\mjimenez\Documents\GitHub\QC_PCTD\';                                             % general path
cellList = dir([mainFolder,'*.nwb']);                                          % list of cell data files

tic;                                                                       % initialize clock
for n = start:length(cellList)                                                 % for all cells in directory
    params = loadParams;                                                   % load parameters to workspace
    cellID = cellList(n).name(1:length(cellList(n).name)-4);               % cell ID (used for saving data)
    disp(cellID)                                                           % display ID number
    cellFile = nwbRead([mainFolder,cellList(n).name]);                                                      % load nwb file
    offset_stim_acq = 0; 
    SweepQC = types.core.FeatureExtraction(...
    'description', 'Sweep wise QC removal and flags',...
    'electrodes', types.hdmf_common.DynamicTableRegion(...
     'table',[], 'description', 'electrode', 'data', []), ...
    'features', [ones(length(cellFile.acquisition.keys),1), ...
      zeros(length(cellFile.acquisition.keys),1) ], ...
    'times', []);
    for sweepNr = 1:length(cellFile.acquisition.keys)                            % loop through sweeps
          if  any(cellFile.stimulus_presentation.values{...
                      sweepNr-offset_stim_acq}.data.load())
%             [ltRMSE, VPs, stRMSE, SweepQC] = SweepwiseQC(...
%                 cellFile.acquisition.values{sweepNr}, ...
%                 cellFile.stimulus_presentation.values{...
%                      sweepNr-offset_stim_acq},...
%                      SweepQC,sweepNr, params...
%                  ); 
%           writeQC
%          if mode(nonzeros(...
%              cellFile.stimulus_presentation.values{sweepNr}.data.load)) > 0                                                                % if current input > 0
%                cellFile.processing  = processDepolLP(...
%                 cellFile.acquisition.values{sweepNr}, ...
%                 cellFile.stimulus_presentation.values{...
%                      sweepNr-offset_stim_acq}...
%                  );
%          else
%            cellFile.processing = ...
%              processHyperpolLP( ...
%               cellFile.acquisition.values{sweepNr}, ...
%               cellFile.stimulus_presentation.values{...
%                      sweepNr-offset_stim_acq}...
%                     );
           %end
    end
    nwbExport(cellFile, cellList(n).name);
end                                                                         % end cell level for loop
                                               