
load('manual_entry_data_updated.mat')   
mainFolder = 'C:\Users\MFeyerabend\Documents\Genpath2\';                                                 % main folder (EDIT HERE) 
folder = [mainFolder,'Temp\'];                                   % general path
cellList = dir([folder,'*.mat']);                                           % list of cell data files
tic;                                                                        % initialize clock
  
for n = 1:length(cellList)                                               % for all cells in directory
    params = loadParams;                                                    % load parameters to workspace
    cellID = cellList(n).name(1:length(cellList(n).name)-4);                % cell ID (used for saving data)
    disp(cellID)                                                            % display ID number
    a = loadFile(folder,cellList(n).name);                                  % load voltage data
    protocols = fieldnames(a);                                              % get all the protocol names
    if double(access_resistance(ID==cellID)) <= 20                                %check for initial access resistance, more cell wide QC checks can be implemented here
        for p = 1:numel(protocols)                                              % loop for each protocol
          if a.(protocols{p}).fullStruct == 1                                     % if all data is present for protocol
            for k = 1:size(a.(protocols{p}).V,1)                                  % for each sweep of the protocol
                qc = estimateRMSnoisePFfunction(a.(protocols{p})...
                    ,k,params,cellID,folder);                                   % RMS noise measurements (for QC)
                if sum(qc.logicVec) == 0                                        % if sweep passes QC criteria
                    if a.(protocols{p}).sweepAmps(k,1) > 0                                  % if current input > 0
                        a.(protocols{p}).stats{k,1} = processDepolarizingLongPulsePF...     % for deploarizing analysis for Spike QC
                            (a.(protocols{p}),params,k,cellID,folder);                      
                    end                                                         % end current level if
                else                                                            % if QC fails
                    plotQCfailed(a.(protocols{p}),k,cellID,qc,folder,params)      % plot raw voltage trace
                    a.(protocols{p}).stats{k,1}.qc = qc;                          % store QC parameters
                end                                                             % end QC logic if
            a.(protocols{p}).stats{k,1}.qc = qc;                                % add RMS values to data structure
            end                                                                 % end sweep for loop
          end                                                                   % end protocol for loop
          if a.(protocols{p}).fullStruct == 1  
          protocols{p} = betweenSweepVmQC(a.(protocols{p}),cellID,folder,params);       % QC between sweeps
           % a.(protocols{p}) = (protocols{p});   
          end
        end                                                                 % end full structure if
        saveFile(a, cellID, mainFolder);                                      % save and count cell
    end                                                                     % end access resistance if
end                                                                         % end cell level for loop
at = toc/60;                                                                % analysis duration in seconds
