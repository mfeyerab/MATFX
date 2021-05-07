function supraStats = processDepolarizingLongPulsePF(protocol,params,k, ...
    cellID,folder,sweepIDcount)
%{
processSuprathresholdLongPulsePF
- analysis of depolarizing sweeps
%}
protocol.putSpTimes = protocol.stimOn(1,k)+...
    find(protocol.V{1,k}(protocol.stimOn(1,k):protocol.stimOff(1,k)+3/protocol.acquireRes(1,k))>=params.thresholdV)-1;   % voltage threshold
protocol = getSPdVdt(protocol,k,params.thresholdDVDT,...
    cellID,folder,params,sweepIDcount);             % derivative threshold
% assess agreement betweeen detection, assign peak based on dV/dt, remove
% setting of interval for peak detection
if ~isempty(protocol.putSpTimes)                                                  % if no spikes
    [int4Peak,protocol.putSpTimes2] = int4APs(protocol.putSpTimes);                     % interval for peak voltage
    sp = estimatePeak(protocol,int4Peak,k);                                       % estimate of peak
    [sp,protocol] = estimateMaxdVdtNthreshold(protocol,sp,k,params,...
        cellID,folder,sweepIDcount);      % dV/dt & initial threshold
    if ~isempty(sp.peak)                                                    % if no spikes
        [sp,protocol] = refineThreshold(protocol,sp,k,params);                          % refine threshold estimate
        [sp,protocol] = estimateTrough(protocol,sp,k,params);                           % estimate trough
        if ~isempty(sp.peak)                                                % if no spikes
            [sp,protocol] = estimateSpParams(protocol,sp,k,params);                     % estimate spike parameters
            if ~isempty(sp.peak)                                            % if no spikes
                sp = estimateAPTrainParams(protocol,sp,k);                        % estimate spike train parameters
                % estimate plateau potential
                % assessPersistence (spikes post-stim)
                wf = getWaveforms(protocol,params,sp,k);                          % get spike waveforms 
                supraStats = storeSPparams(protocol,sp,wf,k);                     % store spike parameters
                plotQCdDepolarizing(protocol,sp,k,cellID,...
                    folder,params,sweepIDcount)                             % plot voltage and spike parameters
            else                                                            % if there are no spikes
                supraStats = outputNaNs(protocol,k);                              % output structure of NaNs
            end
        else                                                                % if there are no spikes
            supraStats = outputNaNs(protocol,k);                                  % output structure of NaNs
        end
    else                                                                    % if there are no spikes
        supraStats = outputNaNs(protocol,k);                                      % output structure of NaNs
    end
else                                                                        % if there are no spikes
    supraStats = outputNaNs(protocol,k);                                          % output structure of NaNs
end