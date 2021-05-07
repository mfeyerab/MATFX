%{
processICsweepsParFor
- analysis of intracellular hyperpolarizing and depolarizing sweeps
%}
mainFolder = 'D:\genpath\';            % main folder (EDIT HERE)
start = 1;

folder = [mainFolder,'genpath\'];                                          % general path
cellList = dir([folder,'*.mat']);                                          % list of cell data files

tic;                                                                       % initialize clock
for n = start:length(cellList)                                                 % for all cells in directory
    params = loadParams;                                                   % load parameters to workspace
    cellID = cellList(n).name(1:length(cellList(n).name)-4);               % cell ID (used for saving data)
    disp(cellID)                                                           % display ID number
    sweepIDcount = 1;
    a = loadFile(folder,cellList(n).name);                                 % load voltage data
    protocols = fieldnames(a);                                             % get all the protocol names
    protocols(2) = [];                                                     % delete metadata
    for p = 1:numel(protocols)                                             % loop for each protocol
          if string(protocols{p}) ~= "gapfree"  && ...
                  a.(protocols{p}).fullStruct == 1                         % if all data is present for protocol or NONAIBS
            for k = 1:size(a.(protocols{p}).V,2)                           % for each sweep of the protocol
                qc = SweepwiseQC(a.(protocols{p}),k,params,cellID,...
                    folder,a.Metadata,sweepIDcount);                % RMS noise measurements (for QC)
                if sum(qc.logicVec) == 0                                   % if sweep passes QC criteria
                    if a.(protocols{p}).sweepAmps(k,1) > 0                                  % if current input > 0
                        a.(protocols{p}).stats{k,1} = ...
                            processDepolarizingLongPulsePF( ...               % for deploarizing analysis for Spike QC
                            a.(protocols{p}),...
                            params,k,cellID,folder,sweepIDcount);     
                    elseif a.(protocols{p}).sweepAmps(k,1) < 0  
                       a.(protocols{p}).stats{k,1} = ...
                         processHyperpolarizingLongPulsePF( ...
                         a.(protocols{p}),params,...
                         qc,k,cellID,folder,sweepIDcount); 
                    end                                                         % end current level if
                else                                                            % if QC fails
                    plotQCfailed(a.(protocols{p}),k,cellID,qc,...
                        folder,params, sweepIDcount)                       % plot raw voltage trace
                    a.(protocols{p}).stats{k,1}.qc = qc;                          % store QC parameters
                end                                                             % end QC logic if
            a.(protocols{p}).stats{k,1}.qc = qc;                                % add RMS values to data structure
            sweepIDcount = sweepIDcount + 1;
            end                                                                 % end sweep for loop
          a.(protocols{p}) = betweenSweepVmQC(...
              a.(protocols{p}),cellID,folder,params);                      % QC between sweeps
          end
    end 
    a.LP.subSummary = summarizeSubthreshold(a.LP,cellID,folder,params);     % subthreshold summary
    save([mainFolder,cellID],'a');                                          % save .mat files
end                                                                         % end cell level for loop
                                               