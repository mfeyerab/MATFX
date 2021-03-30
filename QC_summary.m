%%Summary
clear; close all; clc;                                                      % prepare Matlab workspace

% list of cells
folder = 'H:\NHP cell type database\matlab_files\';                                                      % main folder for data (EDIT HERE)
cellList = dir([folder, '\*.mat']);                                      % cell list

% free parameters (across sweep QC)
minNmaxThres = 10;                                                          % threshold for difference b/w min and max voltage
origStdThresMax = 4;                                                        % above this threshold we remove sweeps > 1.75 S.D.s
origStdThresMin = 0.8;                                                      % below this threshold cells are not QC'd sweep-wise any further

% initializing
qc.sp_mat = zeros(length(cellList),75);
qc.class_mat= zeros(length(cellList),75);

for n = 1:length(cellList)   
    sweep_nr = 1;
    params = loadParams;                                                    % load parameters to workspace
    cellID = cellList(n).name(1:length(cellList(n).name)-4);                % cell ID (used for saving data)
    disp(cellID)                                                            % display ID number
    load([folder,cellList(n).name]);                                        % load data
    protocols = fieldnames(a);     
    qc_logic = zeros(1,8);                                                  % initialize QC matrix
    qc.ID{n,1} = cellID;                                                    % cell ID
    
    for p = 1:length(protocols)  % loop for each protocol    
    if a.(protocols{p}).fullStruct == 1
    qc.(protocols{p}).filenames(n,1) = {(a.(protocols{p}).filenames)}; 
    qc.(protocols{p}).nr_sweeps(n,1) = size(a.(protocols{p}).V,1);    
    qc.(protocols{p}).restVpre = zeros(length(cellList),30);
    qc.(protocols{p}).restVpost = zeros(length(cellList),30);
    qc.(protocols{p}).restVdiffpreNpost = zeros(length(cellList),30);
    qc.(protocols{p}).rmse_pre_lt = zeros(length(cellList),30);
    qc.(protocols{p}).rmse_post_lt = zeros(length(cellList),30);    
%     qc.(protocols{p}).V_vec(n,1:length(a.(protocols{p}).rmp(1,:))) = ...
%         round(a.(protocols{p}).rmp(1,:),2);                                 % resting membrane potential
%     qc.(protocols{p}).V_vecDelta(n,1:length(a.(protocols{p}).rmp(1,:))) = ...
%         round(a.(protocols{p}).rmp(1,1) - a.(protocols{p}).rmp(1,:),2);         % diff RMP pre and post stimulus
    spqcmatn = zeros(length(a.(protocols{p}).sweepAmps),10);               % initialize count of QC removals matrix (each column is a criteria)
    binaryMatCount = 1;
    spqcvectag = nan(20,300);                                              % initialize QC tag storage
    input_current_spqc = zeros(20,1);                                      % initialize input current storage    
                                                                            % if all data is present for protocol
           for k = 1:size(a.(protocols{p}).V,1)                             % for each sweep of the protocol
               a.(protocols{p}).sweep_nr(k,1) = sweep_nr;
               qc.(protocols{p}).restVpre(n,sweep_nr) = round(a.(protocols{p}).stats{k,1}.qc.restVPre,2);        % RMP pre stimulus
               qc.(protocols{p}).restVpost(n,sweep_nr) = round(a.(protocols{p}).stats{k,1}.qc.restVPost,2);      % RMP post stimulus
               qc.(protocols{p}).restVdiffpreNpost(n,sweep_nr) = round( ...
                a.(protocols{p}).stats{k,1}.qc.diffV_b_e,2);                            % diff RMP pre and post stimulus
               qc.(protocols{p}).rmse_pre_lt(n,sweep_nr) = round(a.(protocols{p}).stats{k,1}.qc.rmse_pre,2);     % long term RMS pre stimulus
               qc.(protocols{p}).rmse_post_lt(n,sweep_nr) = round(a.(protocols{p}).stats{k,1}.qc.rmse_post,2);   % lt RMS post stimulus
               qc_logic(1:6) = qc_logic(1:6)+a.(protocols{p}).stats{k,1}.qc.logicVec;  % transfer from mat file to summary variable
               processSpQC                                                 % process spike-wise QC
            
               % assess the removal of this sweep  
             if sum(a.(protocols{p}).stats{k,1}.qc.logicVec) == 0 %isfield(a.(protocols{p}),'stats') &&k<=length(a.(protocols{p}).stats) && ...~isempty(a.(protocols{p}).stats{k,1}) && ...
                qc.sweepID(n,sweep_nr) = sweep_nr;
                qc.sweepBinary(n,sweep_nr) = 1;
                sweepBinaryOrig(1,sweep_nr) = 1;
            else
                qc.sweepID(n,sweep_nr) = 0;
                qc.sweepBinary(n,sweep_nr) = 0;
                sweepBinaryOrig(1,sweep_nr) = 0;
            end
            if isfield(a.(protocols{p}).stats{k,1},'qcRemovals') && ...
                sum([sum(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2P), ...
                   sum(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2PRe), ...
                       sum(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatTrough), ...
                        sum(a.(protocols{p}).stats{k,1}.qcRemovals.percentRheobaseHeight)]) > 0
              if 0.33*length(unique( ...
                      [ a.(protocols{p}).stats{k, 1}.qcRemovals.minInterval,    ...
                        a.(protocols{p}).stats{k, 1}.qcRemovals.dVdt0     ...
                        a.(protocols{p}).stats{k, 1}.qcRemovals.mindVdt     ...   
                        a.(protocols{p}).stats{k, 1}.qcRemovals.maxThreshold     ...
                        a.(protocols{p}).stats{k, 1}.qcRemovals.minDiffThreshold2PeakN   ...
                        a.(protocols{p}).stats{k, 1}.qcRemovals.minDiffThreshold2PeakB   ...
                        a.(protocols{p}).stats{k, 1}.qcRemovals.diffthreshold2peakT   ...
                        a.(protocols{p}).stats{k, 1}.qcRemovals.minIntervalRe   ...
                        a.(protocols{p}).stats{k, 1}.qcRemovals.dVdt0Re   ...
                        a.(protocols{p}).stats{k, 1}.qcRemovals.minTrough   ...
                        a.(protocols{p}).stats{k, 1}.qcRemovals.percentRheobaseHeight   ...
                      ])) > length(a.(protocols{p}).stats{k, 1}.spTimes) 
                  
                qc.sweeps_removed_SpQC(n,sweep_nr) = k;
                qc.sweepBinary(n,sweep_nr) = 0;
                qc.sweepID(n,sweep_nr) = 0;
                qc.class_mat(n,sweep_nr) = 10;
              end
            else
               qc.sweeps_removed_SpQC(n,sweep_nr) = 0;
            end
            sweep_nr = sweep_nr + 1;
           end
            
        %SpQCplots
        qc.(protocols{p}).logic_mat(n,1:6) = qc_logic(1:6);
        if find(qc.sweeps_removed_SpQC)
         qc.(protocols{p}).logic_mat(n, 7) = length(find(qc.sweeps_removed_SpQC(n,:)));
        else
         qc.(protocols{p}).logic_mat(n, 7) = 0;
        end
%       processBwSweepsQC                                                   % across sweep QC
       if size(qc.class_mat,1)~=n
        qc.class_mat(n,:) = 0;
       end
    else
     qc.(protocols{p}).nr_sweeps(n,1) = 0; 
     qc.(protocols{p}).logic_mat(n, :) = NaN;
     qc.(protocols{p}).filenames{n, 1} = NaN;
    end 
    end  
end

%QCSummaryPlots

% sweeps that pass qc
% T = table(cellID,qc.class_mat);
%     writetable(T,[savefilename,'.xlsx'],'Sheet','Sheet1',...
%         'WriteRowNames',true)
% 
% T = table(cellID,meanOrigV,diffMinMaxV,stdOrigV,qc_V_vec,qc_restVpre,qc_restVpost,qc_restVdiffpreNpost,...
%     qc_rmse_pre_lt,qc_rmse_post_lt,qc_rmse_pre_st,qc_rmse_post_st);
%     writetable(T,[savefilename,'.xlsx'],'Sheet','Sheet2',...
%         'WriteRowNames',true)

%% amount and list of sweeps to delete
protocols = fieldnames(a);
qc.accepted_sweeps = sum(qc.sweepBinary,2);
qc.deleted_sweeps = zeros(size(qc.sweepBinary,1),1);
qc.idx_deleted_sweeps = cell(size(qc.sweepBinary,1),1);

for i = 1:size(qc.sweepBinary,1)
  temp = 0;  
 for p = 1:length(protocols)
   if ~isnan(qc.(protocols{p}).nr_sweeps(i))
     temp = temp + qc.(protocols{p}).nr_sweeps(i); 
   end
 end
 qc.deleted_sweeps(i) = temp - qc.accepted_sweeps(i);
 if qc.deleted_sweeps(i) > 0
 qc.idx_deleted_sweeps{i,1} = find(qc.sweepBinary(i,:)==0, qc.deleted_sweeps(i));
 else
 qc.idx_deleted_sweeps{i,1} = NaN;   
 end    
end

counter = 1;


for cell=1:length(qc.idx_deleted_sweeps)
  elements =  qc.idx_deleted_sweeps{cell};
 for e = 1:length(elements)     
    if elements(e) < qc.(protocols{1}).nr_sweeps(cell)
        list{counter,1} = qc.ID{cell};  
        list{counter,4} = protocols{1};
        list{counter,2} = qc.(protocols{1}).filenames{cell};     
        list{counter,3} = elements(e);
        counter = counter + 1;
    elseif  elements(e) < (qc.(protocols{1}).nr_sweeps(cell)+ qc.(protocols{2}).nr_sweeps(cell))
                list{counter,1} = qc.ID{cell};  
        list{counter,4} = protocols{2};
        list{counter,2} = qc.(protocols{2}).filenames{cell};       
        list{counter,3} = elements(e) - qc.(protocols{1}).nr_sweeps(cell)+ 1;
        counter = counter + 1;
        
    elseif elements(e) < (qc.(protocols{1}).nr_sweeps(cell)+ ...
             qc.(protocols{2}).nr_sweeps(cell)+ qc.(protocols{3}).nr_sweeps(cell))
                list{counter,1} = qc.ID{cell};  
        list{counter,4} = protocols{3};
        list{counter,2} = qc.(protocols{3}).filenames{cell};    
        list{counter,3} = elements(e) - qc.(protocols{1}).nr_sweeps(cell) - qc.(protocols{2}).nr_sweeps(cell) + 1;
        counter = counter + 1;    
             
    elseif elements(e) < (qc.(protocols{1}).nr_sweeps(cell)+ ...
             qc.(protocols{2}).nr_sweeps(cell)+ qc.(protocols{3}).nr_sweeps(cell) + qc.(protocols{4}).nr_sweeps(cell)) 
        list{counter,1} = qc.ID{cell};  
        list{counter,4} = protocols{4};     
        list{counter,3} = elements(e) - qc.(protocols{1}).nr_sweeps(cell) - ...
            qc.(protocols{2}).nr_sweeps(cell) - qc.(protocols{3}).nr_sweeps(cell) + 1;
        list{counter,2} = qc.(protocols{4}).filenames{cell}{list{counter,3}};  
        counter = counter + 1;  
    
    elseif elements(e) < (qc.(protocols{1}).nr_sweeps(cell)+ ...
             qc.(protocols{2}).nr_sweeps(cell)+ qc.(protocols{3}).nr_sweeps(cell) + ...
             qc.(protocols{4}).nr_sweeps(cell)+ qc.(protocols{5}).nr_sweeps(cell)) 
        list{counter,1} = qc.ID{cell};  
        list{counter,4} = protocols{5};     
        list{counter,3} = elements(e) - qc.(protocols{1}).nr_sweeps(cell) - ...
            qc.(protocols{2}).nr_sweeps(cell) - qc.(protocols{3}).nr_sweeps(cell) ...
            - qc.(protocols{4}).nr_sweeps(cell) + 1;
        list{counter,2} = qc.(protocols{5}).filenames{cell};   
        counter = counter + 1; 
    elseif elements(e) < (qc.(protocols{1}).nr_sweeps(cell)+ ...
             qc.(protocols{2}).nr_sweeps(cell)+ qc.(protocols{3}).nr_sweeps(cell) + ...
             qc.(protocols{4}).nr_sweeps(cell)+ qc.(protocols{5}).nr_sweeps(cell) + ...
             qc.(protocols{6}).nr_sweeps(cell))
        list{counter,1} = qc.ID{cell};  
        list{counter,4} = protocols{6};     
        list{counter,3} = elements(e) - qc.(protocols{1}).nr_sweeps(cell) - ...
            qc.(protocols{2}).nr_sweeps(cell) - qc.(protocols{3}).nr_sweeps(cell) ...
            - qc.(protocols{4}).nr_sweeps(cell) - qc.(protocols{5}).nr_sweeps(cell) + 1;
        list{counter,2} = qc.(protocols{6}).filenames{cell};   
        counter = counter + 1;  
     end    
 end
end

