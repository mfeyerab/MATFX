function [sp,LP] = refineThreshold(LP,sp,k,params)

% refined threshold (based on average max dV/dt)
AVGmaxdVdt = mean(sp.maxdVdt);                                              % max average

thresholdRef = zeros(1,length(LP.putSpTimes2)); 
thresholdRefTime = zeros(1,length(LP.putSpTimes2));

for i = 1:length(LP.putSpTimes2)
    vec = sp.dVdt(sp.peakTime(i) - (params.maxDiffThreshold2PeakT / ...
        LP.acquireRes(1,k)) : sp.peakTime(i));                                   % dV/dt vector
    [~, maxdVdtTime(i)] = max(vec);                                         % max change in voltage
    vec = vec(1:maxdVdtTime(i));
    if ~isempty(find(vec < (params.pcentMaxdVdt*AVGmaxdVdt),1,'last'))
        thresholdRefTime(i) = find(vec < (params.pcentMaxdVdt* ...
            AVGmaxdVdt), 1, 'last');                                        % 5% of max average dV/dt
        thresholdRefTime(i) = thresholdRefTime(i)+sp.peakTime(i) - ...
            (params.maxDiffThreshold2PeakT/LP.acquireRes(1,k)) - 1;              % adjust threshold time for window
        thresholdRef(i) = LP.V{1,k}(thresholdRefTime(i));                   % voltage at refined threshold
    else
        if ~isempty(find(vec < params.absdVdt, 1, 'last'))
            thresholdRefTime(i) = find(vec < params.absdVdt, 1, 'last');    % abs criteria
            thresholdRefTime(i) = thresholdRefTime(i)+sp.peakTime(i) - ...
                (params.maxDiffThreshold2PeakT/LP.acquireRes(1,k)) - 1;          % adjust threshold time for window
            thresholdRef(i) = LP.V{1,k}(thresholdRefTime(i));               % voltage at refined threshold
        else
            if ~isempty(find(vec < 5, 1, 'last'))
                thresholdRefTime(i) = find(vec < 5, 1, 'last');                 % abs criteria
                thresholdRefTime(i) = thresholdRefTime(i)+sp.peakTime(i) - ...
                    (params.maxDiffThreshold2PeakT/LP.acquireRes(1,k)) - 1;          % adjust threshold time for window
                thresholdRef(i) = LP.V{1,k}(thresholdRefTime(i));               % voltage at refined threshold
            else
                thresholdRefTime(i) = 0;
                thresholdRef(i) = 0;
            end
        end
    end
end

LP.qcRemovals.QCmatT2PRe = [(isnan(thresholdRef))',(thresholdRef==0)'];

idx0 = find(isnan(thresholdRef));                                                % number of times interval rule is broken
LP.qcRemovals.minIntervalRe = LP.putSpTimes2(idx0);                           % record event times
LP.putSpTimes2(idx0) = [];
sp.peak(idx0) = []; sp.peakTime(idx0) = [];
sp.threshold(idx0) = [];
sp.thresholdTime(idx0) = [];
sp.maxdVdt(idx0) = [];
sp.maxdVdtTime(idx0) = [];
thresholdRefTime(idx0) = [];
thresholdRef(idx0) = [];

idx00 = thresholdRef==0;                                                % number of times dV/dt rule is broken
LP.qcRemovals.dVdt0Re = LP.putSpTimes2(idx00);                           % record event times
LP.putSpTimes2(idx00) = [];
sp.peak(idx00) = []; sp.peakTime(idx00) = [];
sp.threshold(idx00) = [];
sp.thresholdTime(idx00) = [];
sp.maxdVdt(idx00) = [];
sp.maxdVdtTime(idx00) = [];
thresholdRefTime(idx00) = [];
thresholdRef(idx00) = [];

sp.thresholdRef = thresholdRef;
sp.thresholdRefTime = thresholdRefTime;


%{
for i = 1:length(LP.putSpTimes2)                                            % for each spike time
    if length(LP.putSpTimes2) == 1
        thresholdRefTime(i) = find(sp.dVdt(sp.peakTime(i) - ...
            (params.maxDiffThreshold2PeakT / LP.acquireRes) : ...
            sp.maxdVdtTime(i)) < params.absdVdt, 1, 'last');                % abs criterium
        thresholdTime(i) = thresholdTime(i) + sp.peakTime(i) - ...
            (params.maxDiffThreshold2PeakT/LP.acquireRes) - 1;              % adjust threshold time for window
        thresholdRef(i) = LP.V{1,k}(thresholdRefTime(i));                   % voltage at refined threshold
%         hold on
%         plot(LP.V{1,k})
%         plot(sp.dVdt)
%         scatter([1 10],[AVGmaxdVdt AVGmaxdVdt],'b')
%         scatter(thresholdRefTime(i),thresholdRef(i))
%         scatter(sp.thresholdTime(i),sp.threshold(i))
%         xlim([sp.thresholdTime(i)-10 sp.peakTime(i)+10])
%         pause(1)
%         close
    else
        if i == 1
            [~, maxdVdtTime(i)] = max(sp.dVdt(1:sp.peakTime(i)-1));         % max change in voltage
            thresholdRefTime(i) = find(sp.dVdt(1:maxdVdtTime(i)) < ...
                (params.pcentMaxdVdt*AVGmaxdVdt), 1, 'last');               % 5% of max average dV/dt
            thresholdRef(i) = LP.V{1,k}(thresholdRefTime(i));               % voltage at refined threshold
%             hold on
%             plot(LP.V{1,k})
%             plot(sp.dVdt)
%             scatter([1 10],[AVGmaxdVdt AVGmaxdVdt],'b')
%             scatter(thresholdRefTime(i),thresholdRef(i))
%             scatter(sp.thresholdTime(i),sp.threshold(i))
%             xlim([sp.thresholdTime(i)-10 sp.peakTime(i)+10])
%             pause(1)
%             close
        elseif i > 1
            temp_t = sp.peakTime(i-1)+(params.minRefract/LP.acquireRes);    % add buffer to last spike time (i.e., refractory)
            if sp.peakTime(i)-1 > temp_t                                    % if there is 0.5 ms refractory
                [~, maxdVdtTime(i)] = max(sp.dVdt(temp_t:...
                    sp.peakTime(i)-1));                                     % max change in voltage
                maxdVdtTime(i) = maxdVdtTime(i) + temp_t - 1;               % adjust by peak time
                if ~isempty(find(sp.dVdt ...
                        (sp.peakTime(i-1):maxdVdtTime(i)) < ...
                        (params.pcentMaxdVdt*AVGmaxdVdt), 1, 'last'))       % is there a dVdt < 5% of max?
                    thresholdRefTime(i) = find(sp.dVdt(sp.peakTime(i-1):...
                        maxdVdtTime(i)) < (params.pcentMaxdVdt*AVGmaxdVdt), 1, 'last');    % 5% of max average dV/dt
                    thresholdRefTime(i) = thresholdRefTime(i) + ...
                        sp.peakTime(i-1);                                   % adjust by peak time
                    thresholdRef(i) = LP.V{1,k}(thresholdRefTime(i));       % voltage at refined threshold
%                     hold on
%                     plot(LP.V{1,k})
%                     plot(sp.dVdt)
%                     scatter([1 10],[AVGmaxdVdt AVGmaxdVdt],'b')
%                     scatter(thresholdRefTime(i),thresholdRef(i))
%                     scatter(sp.thresholdTime(i),sp.threshold(i))
%                     xlim([sp.thresholdTime(i)-10 sp.peakTime(i)+10])
%                     pause(1)
%                     close
                else
                    if ~isempty(find(sp.dVdt(maxdVdtTime(i) - ...
                            (1.5/LP.acquireRes):maxdVdtTime(i)) < ...
                            0.5, 1,'last'))                                 % is there a time where dVdt was <0.5?
                        thresholdRefTime(i) = find(sp.dVdt(maxdVdtTime(i)-...
                            (1.5/LP.acquireRes):maxdVdtTime(i)) < 0.5, ...
                            1,'last');                                      % threshold where dV/dt < 0.5mV/ms
                        thresholdRefTime(i) = thresholdRefTime(i) + ...
                            maxdVdtTime(i);                                 % adjust threshold time by max dVdt time
                        thresholdRef(i) = LP.V{1,k}(thresholdRefTime(i));   % record threshold
%                         hold on
%                         plot(LP.V{1,k})
%                         plot(sp.dVdt)
%                         scatter([1 10],[AVGmaxdVdt AVGmaxdVdt],'b')
%                         scatter(thresholdRefTime(i),thresholdRef(i))
%                         scatter(sp.thresholdTime(i),sp.threshold(i))
%                         xlim([sp.thresholdTime(i)-10 sp.peakTime(i)+10])
%                         pause(1)
%                         close
                    else
                        thresholdRefTime(i) = 0;                               % set to zero to ID later
                        thresholdRef(i) = 0;
%                         hold on
%                         plot(LP.V{1,k})
%                         plot(sp.dVdt)
%                         scatter(sp.peakTime(i),-10)
%                         scatter(sp.peakTime(i-1),-10)
%                         xlabel('time-steps')
%                         xlim([sp.peakTime(i-1)-10 sp.peakTime(i)+10])
%                         pause(1)
%                         close
                    end
                end
            else                                                            % if there is no 0.5 ms refractory
                thresholdRefTime(i) = NaN;                                  % used downstream for QC quant
                thresholdRef(i) = NaN;
            end
        end
    end
end
%}