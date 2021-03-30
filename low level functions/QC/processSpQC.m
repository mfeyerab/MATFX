%{
processSpQC
%}

% the if statement below filters cells that [1] have a structure
% representing spike-wise QC removals; and, [2] there are some spikes
% that were removed by QC
if isfield(a.(protocols{p}).stats{k,1},'qcRemovals') && ...
        sum([sum(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2P), ...
        sum(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2PRe), ...
        sum(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatTrough), ...
        sum(a.(protocols{p}).stats{k,1}.qcRemovals.percentRheobaseHeight)]) > 0
%     
%     a_orig = size(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2P,1);                   % size of first matrix for spike-wise QC (during threshold computation)
% %     if sum(sum(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2PRe))==0                   % if there are no removals at the refine threshold step
% %         a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2PRe = ...
% %             zeros(a_orig, ...
% %             size(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2PRe,2));                 % set matrices to same size
% %     else
%         [b,c] = size(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2PRe);
%         if a_orig - b > 0
%             a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2PRe(b + 1: ...
%                 a_orig,1:c) = zeros(a_orig - b,c);
%         end
% %     end
% %     if sum(sum(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatTrough))==0
% %         a.(protocols{p}).stats{k,1}.qcRemovals.QCmatTrough = ...
% %             zeros(a_orig, ...
% %             size(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatTrough,2));             % setting this vector to zeros (frustratingly necessary
% %     else
%         [b,c] = size(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatTrough);
%         if a_orig - b > 0
%             a.(protocols{p}).stats{k,1}.qcRemovals.QCmatTrough(b + 1: ...
%                 a_orig,1:c) = zeros(a_orig - b,c);
%         end
% %     end
%     if isempty(a.(protocols{p}).stats{k,1}.qcRemovals.percentRheobaseHeight)
%         a.(protocols{p}).stats{k,1}.qcRemovals.percentRheobaseHeight = 0;
%     end
%     if sum(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatpercentRheobaseHeight)==0
%         a.(protocols{p}).stats{k,1}.qcRemovals.QCmatpercentRheobaseHeight = ...
%             zeros(size(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2P,1),1);       % setting this vector to zeros (frustratingly necessary
%     else
%         [b,c] = size(a.(protocols{p}).stats{k,1}.qcRemovals.QCmatpercentRheobaseHeight);
%         if a_orig - b > 0
%             a.(protocols{p}).stats{k,1}.qcRemovals.QCmatpercentRheobaseHeight(1:c, ...
%                 b + 1: a_orig) = zeros(c,a_orig - b);
%         end
%     end
%     
%     % image of spike-wise criteria (each spike has a row)
%     figure('Position',[50 50 300 250]); set(gcf,'color','w');
%     imagesc([a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2P, ...
%         a.(protocols{p}).stats{k,1}.qcRemovals.QCmatT2PRe, ...
%         a.(protocols{p}).stats{k,1}.qcRemovals.QCmatTrough, ...
%         a.(protocols{p}).stats{k,1}.qcRemovals.QCmatpercentRheobaseHeight])
% 
%     colormap('gray')
%     xticks(1:11)
%     xticklabels({'interval','null dV/dt','dV/dt<5mV/ms', ...
%         'threshold>-20mV','t2p<20mV','t2pT>2ms','interval Re', ...
%         'null dV/dt Re','p2t<30mV','trough>-30mV','<30% Rheobase height'})
%     xtickangle(45)
%     ylabel('spike #')
%     title([int2str(a.(protocols{p}).sweepAmps(k,1)),' pA'])
%     export_fig(['D:\my\genpath\',cellID,' ',int2str(k),' spike QC matrix'],'-pdf','-r100');
%     close
    
    %{
    get spike times for removed spikes
    %}
    vec = [];                           % initialize vector for removed spike times 
    vectag = [];                        % initialize vector for QC tag of removed spikes
    
    % criteria #1: min interval (refractory consideration 0.5 ms)
    if ~isempty(a.(protocols{p}).stats{k,1}.qcRemovals.minInterval)                     % are there removals for this criteria?
        qc.sp_mat(n,k) = qc.sp_mat(n,k) + ...
            length(a.(protocols{p}).stats{k,1}.qcRemovals.minInterval);                 % count of QC removals (rows are cells, columns are sweeps)
        spqcmatn(k,1) = length(a.(protocols{p}).stats{k,1}.qcRemovals.minInterval);     % count of QC removals (rows are sweeps, columns are criteria)
        vec = a.(protocols{p}).stats{k,1}.qcRemovals.minInterval;                       % collect removed spike time
        vectag = ones(1,length(a.(protocols{p}).stats{k,1}.qcRemovals.minInterval));    % add unique QC tag for spike time
    end
    % criteria #2: dV/dt_0 (dV/dt stays too low to find a threshold)
    if ~isempty(a.(protocols{p}).stats{k,1}.qcRemovals.dVdt0)                           % are there removals for this criteria?
        qc.sp_mat(n,k) = qc.sp_mat(n,k) + ...
            length(a.(protocols{p}).stats{k,1}.qcRemovals.dVdt0);                       % count of QC removals (rows are cells, columns are sweeps)
        spqcmatn(k,2) = length(a.(protocols{p}).stats{k,1}.qcRemovals.dVdt0);           % count of QC removals (rows are sweeps, columns are criteria)
        vec = [vec, a.(protocols{p}).stats{k,1}.qcRemovals.dVdt0];                      % collect removed spike time
        vectag = [vectag, ...
            ones(1,length(a.(protocols{p}).stats{k,1}.qcRemovals.dVdt0))+1];            % add unique QC tag for spike time
    end
    % criteria #3: min dV/dt (dV/dt didn't exceed 5mV/ms)
    if ~isempty(a.(protocols{p}).stats{k,1}.qcRemovals.mindVdt)                         % are there removals for this criteria?
        qc.sp_mat(n,k) = qc.sp_mat(n,k) + ...
            length(a.(protocols{p}).stats{k,1}.qcRemovals.mindVdt);                     % count of QC removals (rows are cells, columns are sweeps)
        spqcmatn(k,3) = length(a.(protocols{p}).stats{k,1}.qcRemovals.mindVdt);         % count of QC removals (rows are sweeps, columns are criteria)
        vec = [vec, a.(protocols{p}).stats{k,1}.qcRemovals.mindVdt];                    % collect removed spike time
        vectag = [vectag, ...
            ones(1,length(a.(protocols{p}).stats{k,1}.qcRemovals.mindVdt))+2];          % add unique QC tag for spike time
    end
    % criteria #4: max threshold (-27.5 mV)
    if ~isempty(a.(protocols{p}).stats{k,1}.qcRemovals.maxThreshold)                    % are there removals for this criteria?
        qc.sp_mat(n,k) = qc.sp_mat(n,k) + ...
            length(a.(protocols{p}).stats{k,1}.qcRemovals.maxThreshold);                % count of QC removals (rows are cells, columns are sweeps)
        spqcmatn(k,4) = length(a.(protocols{p}).stats{k,1}.qcRemovals.maxThreshold);    % count of QC removals (rows are sweeps, columns are criteria)
        vec = [vec, a.(protocols{p}).stats{k,1}.qcRemovals.maxThreshold];               % collect removed spike time
        vectag = [vectag, ...
            ones(1,length(a.(protocols{p}).stats{k,1}.qcRemovals.maxThreshold))+3];     % add unique QC tag for spike time
    end
    % criteria #5: diff b/w threshold and peak (30 & 35 mV)
    % here we consider narrow (< 0.7 ms half width) and broad 
    % narrow first
    if ~isnan(a.(protocols{p}).stats{k,1}.qcRemovals.minDiffThreshold2PeakN)            % are there removals for this criteria?
        qc.sp_mat(n,k) = qc.sp_mat(n,k) + ...
            length(a.(protocols{p}).stats{k,1}.qcRemovals.minDiffThreshold2PeakN);      % count of QC removals (rows are cells, columns are sweeps)
        spqcmatn(k,5) = length( ...
            a.(protocols{p}).stats{k,1}.qcRemovals.minDiffThreshold2PeakN);             % count of QC removals (rows are sweeps, columns are criteria)
        vec = [vec, a.(protocols{p}).stats{k,1}.qcRemovals.minDiffThreshold2PeakN];     % collect removed spike time
        vectag = [vectag, ...
            ones(1,length( ...
            a.(protocols{p}).stats{k,1}.qcRemovals.minDiffThreshold2PeakN))+4];         % add unique QC tag for spike time (note: same as broad)
    end
    % broad second
    if ~isnan(a.(protocols{p}).stats{k,1}.qcRemovals.minDiffThreshold2PeakB)            % are there removals for this criteria?
        qc.sp_mat(n,k) = qc.sp_mat(n,k) + ...
            length(a.(protocols{p}).stats{k,1}.qcRemovals.minDiffThreshold2PeakB);      % count of QC removals (rows are cells, columns are sweeps)
        spqcmatn(k,5) = length( ...
            a.(protocols{p}).stats{k,1}.qcRemovals.minDiffThreshold2PeakB);             % count of QC removals (rows are sweeps, columns are criteria)
        vec = [vec, a.(protocols{p}).stats{k,1}.qcRemovals.minDiffThreshold2PeakB];     % collect removed spike time
        vectag = [vectag, ...
            ones(1,length( ...
            a.(protocols{p}).stats{k,1}.qcRemovals.minDiffThreshold2PeakB))+4];         % add unique QC tag for spike time (note: same as narrow)
    end
    % criteria #6: time diff b/w threshold and peak
    if ~isempty(a.(protocols{p}).stats{k,1}.qcRemovals.diffthreshold2peakT)             % are there removals for this criteria?
        qc.sp_mat(n,k) = qc.sp_mat(n,k) + ...
            length(a.(protocols{p}).stats{k,1}.qcRemovals.diffthreshold2peakT);         % count of QC removals (rows are cells, columns are sweeps)
        spqcmatn(k,6) = length( ...
            a.(protocols{p}).stats{k,1}.qcRemovals.diffthreshold2peakT);                % count of QC removals (rows are sweeps, columns are criteria)
        vec = [vec, a.(protocols{p}).stats{k,1}.qcRemovals.diffthreshold2peakT];        % collect removed spike time
        vectag = [vectag, ...
            ones(1,length( ...
            a.(protocols{p}).stats{k,1}.qcRemovals.diffthreshold2peakT))+5];            % add unique QC tag for spike time
    end
    % criteria #7: min interval at revising threshold stage (refractory consideration 0.5 ms)
    if ~isempty(a.(protocols{p}).stats{k,1}.qcRemovals.minIntervalRe)                   % are there removals for this criteria?
        qc.sp_mat(n,k) = qc.sp_mat(n,k) + ...
            length(a.(protocols{p}).stats{k,1}.qcRemovals.minIntervalRe);               % count of QC removals (rows are cells, columns are sweeps)
        spqcmatn(k,7) = length(a.(protocols{p}).stats{k,1}.qcRemovals.minIntervalRe);   % count of QC removals (rows are sweeps, columns are criteria)
        vec = [vec, a.(protocols{p}).stats{k,1}.qcRemovals.minIntervalRe];              % collect removed spike time
        vectag = [vectag, ...
            ones(1,length(a.(protocols{p}).stats{k,1}.qcRemovals.minIntervalRe))+6];    % add unique QC tag for spike time
    end
    % criteria #8: 
    if ~isempty(a.(protocols{p}).stats{k,1}.qcRemovals.dVdt0Re)                         % are there removals for this criteria?
        qc.sp_mat(n,k) = qc.sp_mat(n,k) + ...
            length(a.(protocols{p}).stats{k,1}.qcRemovals.dVdt0Re);                     % count of QC removals (rows are cells, columns are sweeps)
        spqcmatn(k,8) = length(a.(protocols{p}).stats{k,1}.qcRemovals.dVdt0Re);         % count of QC removals (rows are sweeps, columns are criteria)
        vec = [vec, a.(protocols{p}).stats{k,1}.qcRemovals.dVdt0Re];                    % collect removed spike time
        vectag = [vectag, ...
            ones(1,length(a.(protocols{p}).stats{k,1}.qcRemovals.dVdt0Re))+7];          % add unique QC tag for spike time
    end
    % criteria #9: min trough
    if ~isempty(a.(protocols{p}).stats{k,1}.qcRemovals.minTrough)                       % are there removals for this criteria?
        qc.sp_mat(n,k) = qc.sp_mat(n,k) + ...
            length(a.(protocols{p}).stats{k,1}.qcRemovals.minTrough);                   % count of QC removals (rows are cells, columns are sweeps)
        spqcmatn(k,9) = length(a.(protocols{p}).stats{k,1}.qcRemovals.minTrough);       % count of QC removals (rows are sweeps, columns are criteria)
        vec = [vec, a.(protocols{p}).stats{k,1}.qcRemovals.minTrough];                  % collect removed spike time
        vectag = [vectag, ...
            ones(1,length(a.(protocols{p}).stats{k,1}.qcRemovals.minTrough))+8];        % add unique QC tag for spike time
    end
    % criteria #10: percent Rheobase height
    if ~isempty(a.(protocols{p}).stats{k,1}.qcRemovals.percentRheobaseHeight)           % are there removals for this criteria?
        qc.sp_mat(n,k) = qc.sp_mat(n,k) + ...
            length(a.(protocols{p}).stats{k,1}.qcRemovals.percentRheobaseHeight);       % count of QC removals (rows are cells, columns are sweeps)
        spqcmatn(k,10) = length( ...
            a.(protocols{p}).stats{k,1}.qcRemovals.percentRheobaseHeight);              % count of QC removals (rows are sweeps, columns are criteria)
        vec = [vec, a.(protocols{p}).stats{k,1}.qcRemovals.percentRheobaseHeight];      % collect removed spike time
        vectag = [vectag, ...
            ones(1,length( ...
            a.(protocols{p}).stats{k,1}.qcRemovals.percentRheobaseHeight))+9];          % add unique QC tag for spike time
    end

    % good before bad, bad before good
    [vec,loc] = sort(vec);                                                  % sort the removed spike times (loc can be used to index vectag)
    if isfield(a.(protocols{p}).stats{k,1},'spTimes') && ...
            sum(~isnan(a.(protocols{p}).stats{k,1}.spTimes))>0
        
        spvec = abs(a.(protocols{p}).stimOn(k)-a.(protocols{p}).stats{k,1}.spTimes) * ...
            a.(protocols{p}).acquireRes;                                                % spike times that pass QC relative to stimulus
        vec = abs(a.(protocols{p}).stimOn(k)-vec)*a.(protocols{p}).acquireRes;                      % spike times that do not pass QC relative to stimulus
        sp = [spvec,vec];                                                   % concatenate good and bad spikes
        spid = [ones(1,length(spvec)),zeros(1,length(vec))];                % give a tag for good and bad spikes
        [~,I] = sort(sp); spid = spid(I);                                   % sort the good and bad spike tags
        spqcmatnbinary(binaryMatCount,1:length(sp)) = sp;                   % store spike times
        spqcmatnbinaryid(binaryMatCount,1:length(spid)) = spid;             % store tags
        k_len_spID(binaryMatCount,1) = round(double(a.(protocols{p}).sweepAmps(k,1)));
        binaryMatCount = binaryMatCount + 1;
        
%         figure('Position',[50 50 300 250]); set(gcf,'color','w');
%         hold on
%         spTimes = find(spid==1);
%         plot([spTimes;spTimes],[zeros(1,length(spTimes));ones(1,length(spTimes))],'k','linewidth',0.25)
%         spTimes = find(spid==0);
%         plot([spTimes;spTimes],[zeros(1,length(spTimes));ones(1,length(spTimes))],'r','linewidth',0.25)
%         xlabel('spike number')
%         ylabel('blk=pass,red=removed')
%         box off
%         xlim([0.5 length(spid)+0.5])
%         ylim([0 1.1])
%         title([int2str(a.(protocols{p}).sweepAmps(k,1)),' pA'])
%         export_fig(['E:\Michael\genpath\',cellID,' ',int2str(k),' spike QC (binary removals)'],'-pdf','-r100');
%         close        
        
%         if length(unique(vectag))>1
%             
%             'yo'
%         end
%         spqcvectag(k,1:length(vectag)) = vectag;
%         input_current_spqc(k,1) = round(double(a.(protocols{p}).sweepAmps(k,1)));
%         clear sp spid B I
    end
else
%     input_current_spqc(k,1) = round(double(a.(protocols{p}).sweepAmps(k,1)));
end








