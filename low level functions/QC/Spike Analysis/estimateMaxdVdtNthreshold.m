function [sp,protocol] = estimateMaxdVdtNthreshold(protocol,sp,k,params,cellID,folder)
%{
estimateMaxdVdtNthreshold
[1] of maximum change in voltage (used to find threshold)
[2] initial threshold estimate (see below for more accurate estimate)
[3] QC for spike height
%}

dVdt = diff(protocol.V{k,1})/protocol.acquireRes;                          % derivative
dVdt = smoothdata(dVdt,'gaussian',15,'SamplePoints',1:length(dVdt));      % filter with Gaussian filter

% hold on
% plot(dVdt)
% plot(output)
% legend({'raw','Gaussian'})

maxdVdt = zeros(1,length(protocol.putSpTimes2));
maxdVdtTime = zeros(1,length(protocol.putSpTimes2));
threshold = zeros(1,length(protocol.putSpTimes2));
thresholdTime = zeros(1,length(protocol.putSpTimes2));

for i = 1:length(protocol.putSpTimes2)                                            % for each putative spike
    [maxdVdt(i), maxdVdtTime(i)] = max(dVdt(sp.peakTime(i) - ...
        (params.maxDiffThreshold2PeakT/protocol.acquireRes):sp.peakTime(i)));     % max change in voltage
    maxdVdtTime(i) = maxdVdtTime(i) + sp.peakTime(i) - ...
        (params.maxDiffThreshold2PeakT/protocol.acquireRes) - 1;                  % adjust max time for window
    vec = dVdt(sp.peakTime(i) - (params.maxDiffThreshold2PeakT / ...
        protocol.acquireRes) : maxdVdtTime(i));                                   % dV/dt vector
    if ~isempty(find(vec < (params.pcentMaxdVdt*maxdVdt(i)), 1, 'last'))
        thresholdTime(i) = find(vec < (params.pcentMaxdVdt*maxdVdt(i)), ...
            1, 'last');                                                     % 5% of max dV/dt
        thresholdTime(i) = thresholdTime(i)+sp.peakTime(i) - ...
            (params.maxDiffThreshold2PeakT/protocol.acquireRes) - 1;              % adjust threshold time for window
        threshold(i) = protocol.V{k,1}(thresholdTime(i));
    else
        if ~isempty(find(vec < params.absdVdt, 1, 'last'))
            thresholdTime(i) = find(vec < params.absdVdt, 1, 'last');       % absolute criterium dV/dt
            thresholdTime(i) = thresholdTime(i) + sp.peakTime(i) - ...
                (params.maxDiffThreshold2PeakT/protocol.acquireRes) - 1;          % adjust threshold time for window
            threshold(i) = protocol.V{k,1}(thresholdTime(i));                     % store threshold for spike
        else
            if ~isempty(find(vec < 5, 1, 'last'))
                thresholdTime(i) = find(vec < 5, 1, 'last');                    % absolute criterium dV/dt
                thresholdTime(i) = thresholdTime(i) + sp.peakTime(i) - ...
                    (params.maxDiffThreshold2PeakT/protocol.acquireRes) - 1;          % adjust threshold time for window
                threshold(i) = protocol.V{k,1}(thresholdTime(i));                     % store threshold for spike
            else
                thresholdTime(i) = 0;
                threshold(i) = 0;
            end
        end
    end
end

%{
QCpeakNthreshold
%}

% events with low dV/dt
% diffthreshold2peak = abs(threshold-sp.peak);
diffthreshold2peakT = (sp.peakTime-thresholdTime)*protocol.acquireRes;

% protocol.qcRemovals.QCmatT2P = [(isnan(maxdVdt))',(threshold==0)',...
%     (maxdVdt < params.mindVdt)',...
%     (threshold > params.maxThreshold)',...
%     (diffthreshold2peak < params.minDiffThreshold2Peak)',...
%     (diffthreshold2peakT > params.maxDiffThreshold2PeakT)'];
protocol.qcRemovals.QCmatT2P = [(isnan(maxdVdt))',(threshold==0)',...
    (maxdVdt < params.mindVdt)',...
    (threshold > params.maxThreshold)',...
    (diffthreshold2peakT > params.maxDiffThreshold2PeakT)'];

if params.plot_all == 1
    figure('Position',[50 50 200 250]); set(gcf,'color','w');
    imagesc(protocol.qcRemovals.QCmatT2P)
    colormap('gray')
    colorbar
    xticks(1:5)
    xticklabels({'interval','null dV/dt','dV/dt<5mV/ms','threshold>-20mV','t2pT>2ms'})
    xtickangle(45)
    ylabel('spike #')
    export_fig([folder(1:length(folder)-8),cellID,' ',int2str(k),' spike QC ',protocol.name],'-pdf','-r100');
    close
end

idx0 = find(isnan(maxdVdt));                                                % number of times interval rule is broken
protocol.qcRemovals.minInterval = protocol.putSpTimes2(idx0);                           % record event times
protocol.putSpTimes2(idx0) = [];
sp.peak(idx0) = []; sp.peakTime(idx0) = [];
threshold(idx0) = [];
thresholdTime(idx0) = [];
maxdVdt(idx0) = [];
maxdVdtTime(idx0) = [];

idx00 = threshold==0;                                                % number of times dV/dt rule is broken
protocol.qcRemovals.dVdt0 = protocol.putSpTimes2(idx00);                           % record event times
protocol.putSpTimes2(idx00) = [];
sp.peak(idx00) = []; sp.peakTime(idx00) = [];
threshold(idx00) = [];
thresholdTime(idx00) = [];
maxdVdt(idx00) = [];
maxdVdtTime(idx00) = [];

idx1 = maxdVdt < params.mindVdt;
protocol.qcRemovals.mindVdt = protocol.putSpTimes2(idx1);                           % record event times
protocol.putSpTimes2(idx1) = [];
sp.peak(idx1) = []; sp.peakTime(idx1) = [];
threshold(idx1) = [];
thresholdTime(idx1) = [];
maxdVdt(idx1) = [];
maxdVdtTime(idx1) = [];

idx = threshold > params.maxThreshold;
protocol.qcRemovals.maxThreshold = protocol.putSpTimes2(idx);
protocol.putSpTimes2(idx) = [];
sp.peak(idx) = []; sp.peakTime(idx) = [];
threshold(idx) = [];
thresholdTime(idx) = [];
maxdVdt(idx) = [];
maxdVdtTime(idx) = [];

% diffthreshold2peak = abs(threshold-sp.peak);
% idx2 = diffthreshold2peak < params.minDiffThreshold2Peak;
% protocol.qcRemovals.diffthreshold2peak = protocol.putSpTimes2(idx2);
% protocol.putSpTimes2(idx2) = [];
% sp.peak(idx2) = []; sp.peakTime(idx2) = []; 
% threshold(idx2) = [];
% thresholdTime(idx2) = [];
% maxdVdt(idx2) = [];
% maxdVdtTime(idx2) = [];

diffthreshold2peakT = (sp.peakTime-thresholdTime)*protocol.acquireRes;
idx3 = diffthreshold2peakT > params.maxDiffThreshold2PeakT;
protocol.qcRemovals.diffthreshold2peakT = protocol.putSpTimes2(idx3);
protocol.putSpTimes2(idx3) = [];
sp.peak(idx3) = []; sp.peakTime(idx3) = [];
threshold(idx3) = [];
thresholdTime(idx3) = [];
maxdVdt(idx3) = [];
maxdVdtTime(idx3) = [];

sp.dVdt = dVdt;
sp.threshold = threshold;
sp.thresholdTime = thresholdTime;
sp.maxdVdt = maxdVdt;
sp.maxdVdtTime = maxdVdtTime;


%{
for i = 1:length(protocol.putSpTimes2)                                            % for each putative spike
    % find max dV/dt
    if length(protocol.putSpTimes2) == 1                                          % if there is only one spike
    	[maxdVdt(i), maxdVdtTime(i)] = max(dVdt(sp.peakTime(i) - ...
            (params.maxDiffThreshold2PeakT/protocol.acquireRes):sp.peakTime(i))); % max change in voltage
        maxdVdtTime(i) = maxdVdtTime(i) + sp.peakTime(i) - ...
            (params.maxDiffThreshold2PeakT/protocol.acquireRes) - 1;              % adjust max time for window
        
        if ~isempty(find(dVdt(sp.peakTime(i) - ...
                (params.maxDiffThreshold2PeakT / protocol.acquireRes) : ...
                maxdVdtTime(i)) < (params.pcentMaxdVdt*maxdVdt(i)), 1, 'last'))
            thresholdTime(i) = find(dVdt(sp.peakTime(i) - ...
                (params.maxDiffThreshold2PeakT / protocol.acquireRes) : ...
                maxdVdtTime(i)) < (params.pcentMaxdVdt*maxdVdt(i)), 1, 'last'); % 5% of max dV/dt
            thresholdTime(i) = thresholdTime(i) + sp.peakTime(i) - ...
                (params.maxDiffThreshold2PeakT/protocol.acquireRes) - 1;              % adjust threshold time for window
            threshold(i) = protocol.V{1,k}(thresholdTime(i));
        else
            thresholdTime(i) = find(dVdt(sp.peakTime(i) - ...
                (params.maxDiffThreshold2PeakT / protocol.acquireRes) : ...
                maxdVdtTime(i)) < params.absdVdt, 1, 'last');                   % absolute criterium dV/dt
            thresholdTime(i) = thresholdTime(i) + sp.peakTime(i) - ...
                (params.maxDiffThreshold2PeakT/protocol.acquireRes) - 1;              % adjust threshold time for window
            threshold(i) = protocol.V{1,k}(thresholdTime(i));                         % store threshold for spike
        end
%         hold on
%         plot(protocol.V{1,k})
%         plot(dVdt)
%         scatter(maxdVdtTime(i),maxdVdt(i))
%         scatter(thresholdTime(i),threshold(i))
%         scatter(thresholdTime(i),dVdt(thresholdTime(i)))
%         xlim([thresholdTime(i)-10 sp.peakTime(i)+10])
%         pause(1)
%         close
    elseif length(protocol.putSpTimes2) > 1                                       % if more than one spike
        if i == 1                                                           % if this is first spike
            [maxdVdt(i), maxdVdtTime(i)] = max(dVdt(sp.peakTime(i) - ...
                (params.maxDiffThreshold2PeakT/protocol.acquireRes):sp.peakTime(i)-1));   % max change in voltage
            thresholdTime(i) = find(dVdt(1:maxdVdtTime(i)) < ...
                (params.pcentMaxdVdt*maxdVdt(i)), 1, 'last');               % 5% of max dV/dt
%             thresholdTime(i) = find(dVdt(1:maxdVdtTime(i)) < ...
%                 params.absdVdt, 1, 'last');                                 % abs crit
            threshold(i) = protocol.V{1,k}(thresholdTime(i));                     % store threshold for spike
%             hold on
%             plot(protocol.V{1,k})
%             plot(dVdt)
%             scatter(maxdVdtTime(i),maxdVdt(i))
%             scatter(thresholdTime(i),threshold(i))
%             scatter(thresholdTime(i),dVdt(thresholdTime(i)))
%             xlim([thresholdTime(i)-10 sp.peakTime(i)+10])
%             pause(1)
%             close
        elseif i > 1                                                        % if this the second or greater spike
            temp_t = sp.peakTime(i-1)+(params.minRefract/protocol.acquireRes);    % last spike + refractory
            if sp.peakTime(i)-1 > temp_t                                    % consider 0.5 ms refractory
                [maxdVdt(i), maxdVdtTime(i)] = max(dVdt(temp_t:...
                    sp.peakTime(i)-1));                                     % max change in voltage
                maxdVdtTime(i) = maxdVdtTime(i) + temp_t - 1;               % adjust max time by peak time
                if ~isempty(find(dVdt(sp.peakTime(i-1):maxdVdtTime(i)) < ...
                        (params.pcentMaxdVdt*maxdVdt(i)), 1, 'last'))       % if there is a clear indication of threshold
                    thresholdTime(i) = find(dVdt(sp.peakTime(i-1): ...
                        maxdVdtTime(i))<(params.pcentMaxdVdt*maxdVdt(i)), 1, 'last');      % store threshold crossing time
%                     thresholdTime(i) = find(dVdt(sp.peakTime(i-1): ...
%                         maxdVdtTime(i))< params.absdVdt, 1, 'last');      % store threshold crossing time
                    thresholdTime(i) = thresholdTime(i)+sp.peakTime(i-1);   % adjust threshold time by peak time
                    threshold(i) = protocol.V{1,k}(thresholdTime(i));             % store threshold voltage
%                     hold on
%                     plot(protocol.V{1,k})
%                     plot(dVdt)
%                     scatter(maxdVdtTime(i),maxdVdt(i))
%                     scatter(thresholdTime(i),threshold(i))
%                     scatter(thresholdTime(i),dVdt(thresholdTime(i)))
%                     xlim([thresholdTime(i)-10 sp.peakTime(i)+10])
%                     pause(1)
%                     close
                else                                                        % if there is no clear indication of threshold
                    if ~isempty(find(dVdt(maxdVdtTime(i)-...
                            (1.5/protocol.acquireRes):maxdVdtTime(i))<0.5, 1,'last'))
                        thresholdTime(i) = find(dVdt(maxdVdtTime(i)-...
                            (1.5/protocol.acquireRes):maxdVdtTime(i))<0.5, 1,'last'); % threshold where dV/dt < 0.5mV/ms
                        thresholdTime(i) = thresholdTime(i)+maxdVdtTime(i);     % adjust threshold time by max dVdt time
                        threshold(i) = protocol.V{1,k}(thresholdTime(i));             % record threshold
%                         hold on
%                         plot(protocol.V{1,k})
%                         plot(dVdt)
%                         scatter(maxdVdtTime(i),maxdVdt(i))
%                         scatter(thresholdTime(i),threshold(i))
%                         scatter(sp.peakTime(i),-10)
%                         scatter(sp.peakTime(i-1),-10)
%                         xlim([maxdVdtTime(i)-10 sp.peakTime(i)+10])
%                         close
                    else
                        thresholdTime(i) = 0;                               % set to zero to ID later
                        threshold(i) = 0;
%                         hold on
%                         plot(protocol.V{1,k})
%                         plot(dVdt)
%                         scatter(sp.peakTime(i),-10)
%                         scatter(sp.peakTime(i-1),-10)
%                         xlabel('time-steps')
%                         xlim([sp.peakTime(i-1)-10 sp.peakTime(i)+10])
%                         pause(1)
%                         close
                    end
                end
            else                                                            % record data for spikes removed due to short intervals
                maxdVdt(i) = NaN;
                maxdVdtTime(i) = NaN;
                thresholdTime(i) = NaN;
                threshold(i) = NaN;
%                 hold on
%                 plot(protocol.V{1,k})
%                 plot(dVdt)
%                 scatter(sp.peakTime(i),-10)
%                 scatter(sp.peakTime(i-1),-10)
%                 xlabel('time-steps')
%                 xlim([sp.peakTime(i-1)-10 sp.peakTime(i)+10])
%                 pause(1)
%                 close
            end
        end
    end
end

%}