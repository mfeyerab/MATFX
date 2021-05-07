%{
summaryICanalysis
%}

clear; close all; clc;                                                      % prepare Matlab workspace

% Which protocols should be subjected to QC
protocols4qc = ["LP","SP"];
save_path = 'D:\output_AIBS2\';
plot_format = '-jpg'; %'-pdf'

% list of cells
mainFolder = 'D:\genpath';                                                      % main folder for data (EDIT HERE)
cellList = dir([mainFolder,'\*.mat']);                                      % cell list

%% initialize
qc.removedListNoValues = strings(1,1);rmvdNoVCount = 1;

% sweeps wise qc parameter
for p = 1:length(protocols4qc)
qc.(protocols4qc{p}).V_vec = zeros(length(cellList),250); 
qc.(protocols4qc{p}).restVpre = zeros(length(cellList),250);             
qc.(protocols4qc{p}).restVpost = zeros(length(cellList),250);                 
qc.(protocols4qc{p}).restVdiffpreNpost = zeros(length(cellList),250);    
qc.(protocols4qc{p}).rmse_pre_lt = zeros(length(cellList),250);    
qc.(protocols4qc{p}).rmse_post_lt = zeros(length(cellList),250);  
qc.(protocols4qc{p}).rmse_post_st = zeros(length(cellList),250);  
qc.(protocols4qc{p}).rmse_pre_st = zeros(length(cellList),250);  
qc.(protocols4qc{p}).I_hold = zeros(length(cellList),250);
qc.(protocols4qc{p}).bridg_bala = zeros(length(cellList),250);
end

spqcmat = zeros(length(cellList),120);
qc.class_mat = cell(length(cellList),251);
qc.V_vecDelta = zeros(length(cellList),251);

% tags for QC output table
qcTags = {'oldID','st rmse pre','st rmse post','rmse pre','rmse post', ...
 'delta Vm pre2post','Vm abs','I hold','bridg balan abs',...
 'bridg balan rela', 'between Sw', 'SpQC', 'Cell-wise: Ra abs', ...
 'Cell-wise: Ra fract', 'Cell-wise: basic feat'};
qc_logic_mat = array2table(zeros(length(cellList),15),'VariableNames',qcTags);

%% Looping through cells
for n = 1:length(cellList)                                                 % for each cells
    clc; disp(n)                                                           % display n value
    sweepIDcount = 1;
    params = loadParams; 
    cellID = [];
    cellID = cellList(n).name(1:length(cellList(n).name)-4);               % lab ID - extension 
    if length(cellID) == 35
        cellID= [cellID(1:18), '00',cellID(19:end)];
    end
    IC.ID(n,:) = cellID;
%    IC.ID_new(n,:) = NHP_ID_conversion(IC.ID(n,:));                        % Conversion into NeuroNex ID  
        
    load([mainFolder,'\',cellList(n).name]);                               % load output from processICsweeps              
         
    %% Getting cell level metadata    
    if sum(strcmp(fieldnames(a), 'Metadata')) == 1  && ...
            ~isempty(fieldnames(a.Metadata)) && ...
            string(a.Metadata.inital_access_resistance) ~= '-'  
        
         IC.access_resistance(n,1) = a.Metadata.inital_access_resistance; 
         IC.temperature(n,1) = a.Metadata.temperature;
         IC.tp_membrR(n,1) = a.Metadata.membrane_resistance;
    else    
       IC.access_resistance(n,1) = NaN;
       IC.temperature(n,1) = NaN;
    end
    
   IC.resistance_preqc(n,1) = resistance_preqc(a.LP); 
   %% setting up QC 
   qc_logic = zeros(1,9);
   protocols = fieldnames(a);                                              % Get structurs that contain protocols
   [ii,~] = find(protocols==protocols4qc);
   protocols = protocols(ii);   
   
   for p = 1:length(protocols)  % loop for each protocol    
    if a.(protocols{p}).fullStruct == 1  
    sweep_nr = 1;   
    
    qc.(protocols{p}).nr_sweeps(n,1) = length(a.(protocols{p}).V);    
    qc.(protocols{p}).ID{n,1} = IC.ID(n,:); 
    qc.(protocols{p}).V_vec(n, ...
        sweep_nr:sweep_nr+ qc.(protocols{p}).nr_sweeps(n,1)-1) = ...
           round(a.(protocols{p}).rmp(1,:),2);
    
    for k = 1:length(a.(protocols{p}).V)                                   % for each sweep
        
        spqcmatn = zeros(length(a.LP.sweepAmps),10);                       % initialize count of QC removals matrix (each column is a criteria)
        binaryMatCount = 1;                                                %for SpQC  
        spqcvectag = nan(20,300);                                          %for SpQC
        short_label = convertStringsToChars(...
            a.(protocols{p}).sweep_label(k));
        qc.(protocols{p}).sweep_labels(n,k) = string(short_label(14:end));
        
        % sweep-wise quality control parameters
        qc.(protocols{p}).restVpre(n,sweep_nr) = ...
            round(a.(protocols{p}).stats{k,1}.qc.restVPre,2);          % RMP pre stimulus
        qc.(protocols{p}).restVpost(n,sweep_nr) = ...
            round(a.(protocols{p}).stats{k,1}.qc.restVPost,2);         % RMP post stimulus
        qc.(protocols{p}).restVdiffpreNpost(n,sweep_nr) = round( ...
         a.(protocols{p}).stats{k,1}.qc.diffV_b_e,2);                  % diff RMP pre and post stimulus
        qc.(protocols{p}).rmse_pre_lt(n,sweep_nr) = ...
            round(a.(protocols{p}).stats{k,1}.qc.rmse_pre,2);          % long term RMS pre stimulus
        qc.(protocols{p}).rmse_post_lt(n,sweep_nr) = ...
            round(a.(protocols{p}).stats{k,1}.qc.rmse_post,2);         % lt RMS post stimulus
        qc.(protocols{p}).rmse_pre_st(n,sweep_nr) = round(...
        a.(protocols{p}).stats{k,1}.qc.rmse_pre_st,2);                 % st RMS pre stimulus
        qc.(protocols{p}).rmse_post_st(n,sweep_nr) = round( ...
             a.(protocols{p}).stats{k,1}.qc.rmse_post_st,2);           % st RMS post stimulus

        qc.(protocols{p}).I_hold(n,sweep_nr) = ...
            a.(protocols{p}).holding_current(k);                       % adding holding current
        qc.(protocols{p}).bridg_bala(n,sweep_nr) = ...
            a.(protocols{p}).bridge_balance(k);                        % adding bridge balance

        qc_logic = qc_logic+ a.(protocols{p}).stats{k,1}.qc.logicVec;   % QC logic vector (each column is a criteria)
        qc.class_mat{n,sweepIDcount} = [qc.class_mat{n,sweepIDcount}, ...
            find(a.(protocols{p}).stats{k,1}.qc.logicVec)];

        %% spike-wise QC processing and removals            
        processSpQC                                                    % process spike-wise QC 
        
        % assess the removal of this sweep
        if isfield(a.(protocols{p}),'stats') && ...
                sum(a.(protocols{p}).stats{k,1}.qc.logicVec == 0)         
            qc.sweepID(n,sweepIDcount) = sweepIDcount;
            qc.sweepBinary(n,sweepIDcount) = 1;
            sweepBinaryOrig(1,sweepIDcount) = 1;
        else
            qc.sweepID(n,sweepIDcount) = 0;
            qc.sweepBinary(n,sweepIDcount) = short_label;
            sweepBinaryOrig(1,sweepIDcount) = 0;
        end
        if exist('spid') && ( ...
             round(params.minGoodSpFra*length(spid)) > sum(spid==1) || ...
              spid(1) == 0)    
           qc.sweeps_removed_SpQC(n,k) = k;                               % sweeps is recorded in anotehr variable
           qc.sweepBinary(n,sweepIDcount) = 0;                            % sweep is removed from the Binary sheet
           qc.sweepID(n,sweepIDcount) = 0;                                % sweepID is deleted 
           qc.class_mat{n,sweepIDcount} = [qc.class_mat{n,sweepIDcount}, 12];                             % 11 is the code for SpQC removals
           qc_logic_mat{n,12} = qc_logic_mat{n,12} + 1;                   % count of sweeps kicked because of SpQC increased
           clear spid;
        end                          
        sweep_nr = sweep_nr + 1; 
        sweepIDcount = sweepIDcount + 1;       
        end    
    end  
   end
   qc_logic_mat(n,2:10) = array2table(qc_logic);         
   plotSpQC
   processBwSweepsQC   
   
   % including cell wise QC in tag matrix
   if IC.access_resistance(n,1)  >= params.cutoffInitRa && ...
           size(qc.sweepBinary,1)==n
       qc_logic_mat{n,13} = max(qc.sweepID(n,:)); 
   end    
%    if IC.access_resistance(n,1) >= ...
%       a.Metadata.membrane_resistance*params.factorRelaRa && ...
%          size(qc.sweepBinary,1)==n
%        qc_logic_mat{n,14} = max(qc.sweepID(n,:));         
%    end
   
    %% Feature extraction
    
   if size(qc.sweepBinary,1)==n && sum(qc.sweepBinary(n,:))>0 && ... 
            isfield(a.LP.stats{qc.LP.nr_sweeps(n,1),1},'qcRemovals') %&& ...
            %IC.access_resistance(n,1)  <= params.cutoffInitRa && ...
            %IC.access_resistance(n,1) <= ...
            %a.Metadata.membrane_resistance*params.cutoffInitRa             % selecting for initial access resistance
        
        if a.LP.fullStruct == 1 %&& length(fieldnames(a.LP.stats{1,1})) > 1
        LP_summary
        end
        if a.SP.fullStruct == 1 %&& length(fieldnames(a.LP.stats{1,1})) > 1
        SP_summary
        end
        plot_cell_profile
        clear B I idxSP ampSP idxLP ampLP temp k
   else
    no_final_analysis
   end    
end

clear cell_reporter_status donor__species line_name specimen__id structure__acronym ...
    structure__layer tag__dendrite_type access_resistance amp B binaryMatCount cellID dendrite_typeMJ ...
    flag idx ind k marker n Layer leyerID int_vec pyrID temp temperature ...
    Rm spCheck I 

%% Clean up
fieldnames_var = fieldnames(IC);                                            % Getting the variable names to overwrite in them
for n = 1:length(cellList)-1 
 if params.basic_features == 1 && (...
         isnan(IC.time_constant(n,1)) || isnan(IC.rheobaseLP(n,1))) 
    for var = 12:length(fieldnames_var)                                % Leave the first 11 variables untouched, since they are still usefull
      if isnumeric(IC.(fieldnames_var{var,1})) 
        IC.(fieldnames_var{var})(n,1) = NaN;
      end  
    end
    qc.sweepBinary(n,:) = 0;
    if qc_logic_mat{n,13} == 0 && qc_logic_mat{n,14} == 0 
    qc_logic_mat{n,15} = max(qc.sweepID(n,:));
    end
  end 
end

%% 
QC_plots
QC_output_files
Summary_output_files