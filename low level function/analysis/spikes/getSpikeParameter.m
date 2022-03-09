function [sp] = getSpikeParameter(CCSers,sp,PS)

sp.dVdt = diff(CCSers.data.load())/(1000/CCSers.starting_time_rate);
win4Trough = 15*round(CCSers.starting_time_rate)/1000;

sp.maxdVdt = NaN(1,length(sp.peak));
sp.maxdVdtTime = NaN(1,length(sp.peak));
sp.threshold = NaN(1,length(sp.peak));
sp.thresholdTime = NaN(1,length(sp.peak));
sp.trough = NaN(1,length(sp.peak));
sp.troughTime = NaN(1,length(sp.peak));
sp.heightPT= NaN(1,length(sp.peak));
sp.fullWidthPT = NaN(1,length(sp.peak));
sp.peakUpStroke = NaN(1,length(sp.peak));
sp.peakDownStroke = NaN(1,length(sp.peak));
sp.peakStrokeRatio = NaN(1,length(sp.peak));
sp.fast_trough= NaN(1,length(sp.peak));
sp.fast_trough_dur = NaN(1,length(sp.peak));
sp.slow_trough= NaN(1,length(sp.peak));
sp.slow_trough_dur = NaN(1,length(sp.peak));
sp.fullWidthTP = NaN(1,length(sp.peak));


for i = 1:length(sp.peak)  % for each putative spike
%% Getting Threshold

    [sp.maxdVdt(i), sp.maxdVdtTime(i)] = max(sp.dVdt(sp.peakTime(i) - ...
      fix(PS.maxDiffThreshold2PeakT/(1000/CCSers.starting_time_rate)):...
        sp.peakTime(i)));                                                     % max change in voltage
    
    sp.maxdVdtTime(i) = fix(sp.maxdVdtTime(i) + sp.peakTime(i) - ...
    PS.maxDiffThreshold2PeakT/(1000/CCSers.starting_time_rate) - 1);  % adjust max time for window
    
    vec = sp.dVdt(sp.peakTime(i) - fix(PS.maxDiffThreshold2PeakT / ...
        (1000/CCSers.starting_time_rate)) : sp.maxdVdtTime(i));              % dV/dt vector
    
    if ~isempty(find(vec < (PS.pcentMaxdVdt*sp.maxdVdt(i)), 1, 'last'))
        sp.thresholdTime(i) = find(vec < (PS.pcentMaxdVdt*sp.maxdVdt(i)), ...
            1, 'last');                                                     % 5% of max dV/dt
        sp.thresholdTime(i) = sp.thresholdTime(i)+sp.peakTime(i) - ...
            (PS.maxDiffThreshold2PeakT/(1000/CCSers.starting_time_rate)) - 1;              % adjust threshold time for window
        sp.threshold(i) = CCSers.data.load(sp.thresholdTime(i));
    else
        if ~isempty(find(vec < PS.absdVdt, 1, 'last'))
            sp.thresholdTime(i) = find(vec < PS.absdVdt, 1, 'last');      % absolute criterium dV/dt
            sp.thresholdTime(i) = sp.thresholdTime(i) + sp.peakTime(i) - ...
             (PS.maxDiffThreshold2PeakT/...
                 (1000/CCSers.starting_time_rate)) - 1;                  % adjust threshold time for window
            sp.threshold(i) = CCSers.data.load(sp.thresholdTime(i));           % store threshold for spike
        else
            if ~isempty(find(vec < 5, 1, 'last'))
                sp.thresholdTime(i) = find(vec < 5, 1, 'last');                % absolute criterium dV/dt
                sp.thresholdTime(i) = sp.thresholdTime(i) + sp.peakTime(i) - ...
                    round(PS.maxDiffThreshold2PeakT/(1000/CCSers.starting_time_rate)) - 1;      % adjust threshold time for window
                sp.threshold(i) = CCSers.data.load(sp.thresholdTime(i));                 % store threshold for spike
            else
                sp.thresholdTime(i) = 0;
                sp.threshold(i) = 0;
            end
        end
    end   
    
    sp.thresholdTime(i) = round(sp.thresholdTime(i));
    
%% Determining Trough    
    if i < length(sp)
	  [sp.trough(i),temp] = min(CCSers.data.load(sp.peakTime(i):sp.peakTime(i)));
		sp.troughTime(i) = sp.peakTime(i)+temp(1)-1;
    else
       [sp.trough(i),temp] = min(CCSers.data.load(sp.peakTime(i):sp.peakTime(i)+win4Trough));
          sp.troughTime(i) = sp.peakTime(i)+temp-1;
    end
    
    sp.heightPT(i) = sp.peak(i) - sp.trough(i);
    peakMinusHeight = sp.peak(i)-(sp.heightPT(i)/2);
    
    if sp.thresholdTime(i)~=0
      temp2 = find(CCSers.data.load(sp.thresholdTime(i):sp.peakTime(i))<peakMinusHeight, 1, 'last');          
      temp2 = sp.thresholdTime(i) + temp2;
    else 
      temp2 = [];
    end
    if ~isempty(temp2)
        halfHeightTimeUpPT(i) = temp2; 
        temp2 = find(CCSers.data.load(sp.peakTime(i):sp.troughTime(i))<peakMinusHeight, 1, 'first');          
        temp2 = sp.peakTime(i) + temp2;
        if ~isempty(temp2)
            halfHeightTimeDownPT(i) = temp2(1);
            sp.fullWidthPT(i) = (halfHeightTimeDownPT(i) - halfHeightTimeUpPT(i))*1000/CCSers.starting_time_rate;
        end
    end
%% Get Spikeparameter
    sp.heightTP(i) = sp.peak(i) - sp.threshold(i);
    peakMinusHeight = sp.peak(i)-(sp.heightTP(i)/2);
    if sp.thresholdTime(i)~=0
      temp2 = find(CCSers.data.load(sp.thresholdTime(i):sp.peakTime(i))<peakMinusHeight, 1, 'last');          
      temp2 = sp.thresholdTime(i) + temp2;
    else 
      temp2 = [];
    end
    if ~isempty(temp2)
        halfHeightTimeUpTP(i) = temp2;
        temp2 = find(CCSers.data.load(sp.peakTime(i):sp.troughTime(i))<peakMinusHeight, 1, 'first');          
        temp2 = sp.peakTime(i) + temp2;
        if ~isempty(temp2)
            halfHeightTimeDownTP(i) = temp2(1);
            sp.fullWidthTP(i) = (halfHeightTimeDownTP(i) - halfHeightTimeUpTP(i))*(1000/CCSers.starting_time_rate);
        end
    end
    % compute peak stroke ratio
    if sp.thresholdTime(i)~=0
        maxTemp = max(sp.dVdt(sp.thresholdTime(i):sp.peakTime(i)));
        minTemp = min(sp.dVdt(sp.peakTime(i):sp.troughTime(i)-1));
    else 
        maxTemp = [];
        minTemp = [];
    end
    if ~isempty(maxTemp) && ~isempty(minTemp)
        sp.peakUpStroke(i) = maxTemp;
        sp.peakDownStroke(i) = minTemp;
        sp.peakStrokeRatio(i) = sp.peakUpStroke(i) / sp.peakDownStroke(i);
    end

    % Short (5ms) and long (between events) troughs
%     restingPot = mean(CCSeries(CCSeries.stimOn(1,k)-(550/CCSeries.acquireRes):CCSeries.stimOn(1,k)-(50/CCSeries.acquireRes)));
    [sp.fast_trough(i),sp.fast_trough_dur(i)] = min(CCSers.data.load(sp.peakTime(i):sp.peakTime(i)+(5/(1000/CCSers.starting_time_rate))));
    if i < length(sp.peakTime)
        [sp.slow_trough(i), sp.slow_trough_dur(i)] = min(CCSers.data.load(sp.peakTime(i):sp.peakTime(i+1)));
    else
        [sp.slow_trough(i), sp.slow_trough_dur(i)] = min(...
            CCSers.data.load(sp.peakTime(i):...
              PS.SwDat.StimOff+...
                (5/(1000/CCSers.starting_time_rate)) ...
                 ));

    end
end

sp.threshold(sp.thresholdTime==0) = [];
sp.peak(sp.thresholdTime==0) = [];
sp.peakTime(sp.thresholdTime==0) = [];
sp.maxdVdt(sp.thresholdTime==0) = [];
sp.maxdVdtTime(sp.thresholdTime==0) = [];
sp.trough(sp.thresholdTime==0) = [];
sp.troughTime(sp.thresholdTime==0) = [];
sp.heightPT(sp.thresholdTime==0) = [];
sp.fullWidthPT(sp.thresholdTime==0) = [];
sp.peakDownStroke(sp.thresholdTime==0) = [];
sp.peakUpStroke(sp.thresholdTime==0) = [];
sp.peakStrokeRatio(sp.thresholdTime==0) = [];
sp.fast_trough(sp.thresholdTime==0) = [];
sp.fast_trough_dur(sp.thresholdTime==0) = [];
sp.slow_trough(sp.thresholdTime==0) = [];
sp.slow_trough_dur(sp.thresholdTime==0) = [];
sp.fullWidthTP(sp.thresholdTime==0) = [];
sp.heightTP(sp.thresholdTime==0) = [];
sp.thresholdTime(sp.thresholdTime==0) = [];
