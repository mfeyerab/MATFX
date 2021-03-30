function supraStats = outputNaNs(LP,k)

% store spike-wise QC
if isfield(LP,'qcRemovals')
    % spike wise QC matrices
    if isfield(LP.qcRemovals,'QCmatT2P')
        supraStats.qcRemovals.QCmatT2P = LP.qcRemovals.QCmatT2P;
    else
        supraStats.qcRemovals.QCmatT2P = NaN;
    end
    if isfield(LP.qcRemovals,'QCmatT2PRe')
        supraStats.qcRemovals.QCmatT2PRe = LP.qcRemovals.QCmatT2PRe;
    else
        supraStats.qcRemovals.QCmatT2PRe = NaN;
    end
    if isfield(LP.qcRemovals,'QCmatTrough')
        supraStats.qcRemovals.QCmatTrough = LP.qcRemovals.QCmatTrough;
    else
        supraStats.qcRemovals.QCmatTrough = NaN;
    end
    if isfield(LP.qcRemovals,'QCmatpercentRheobaseHeight')
        supraStats.qcRemovals.QCmatpercentRheobaseHeight = ...
            LP.qcRemovals.QCmatpercentRheobaseHeight;
    else
        supraStats.qcRemovals.QCmatpercentRheobaseHeight = NaN;
    end
    % spike-wsie QC parameters
    if isfield(LP.qcRemovals,'minInterval')
        supraStats.qcRemovals.minInterval = LP.qcRemovals.minInterval;
    else
        supraStats.qcRemovals.minInterval = NaN;
    end
    if isfield(LP.qcRemovals,'dVdt0')
        supraStats.qcRemovals.dVdt0 = LP.qcRemovals.dVdt0;
    else
        supraStats.qcRemovals.dVdt0 = NaN;
    end
    if isfield(LP.qcRemovals,'mindVdt')
        supraStats.qcRemovals.mindVdt = LP.qcRemovals.mindVdt;
    else
        supraStats.qcRemovals.mindVdt = NaN;
    end
    if isfield(LP.qcRemovals,'maxThreshold')
        supraStats.qcRemovals.maxThreshold = LP.qcRemovals.maxThreshold;
    else
        supraStats.qcRemovals.maxThreshold = NaN;
    end
    if isfield(LP.qcRemovals,'minDiffThreshold2PeakN')
        supraStats.qcRemovals.minDiffThreshold2PeakN = LP.qcRemovals.minDiffThreshold2PeakN;
    else
        supraStats.qcRemovals.minDiffThreshold2PeakN = NaN;
    end
    if isfield(LP.qcRemovals,'minDiffThreshold2PeakB')
        supraStats.qcRemovals.minDiffThreshold2PeakB = LP.qcRemovals.minDiffThreshold2PeakB;
    else
        supraStats.qcRemovals.minDiffThreshold2PeakB = NaN;
    end
    if isfield(LP.qcRemovals,'diffthreshold2peakT')
        supraStats.qcRemovals.diffthreshold2peakT = LP.qcRemovals.diffthreshold2peakT;
    else
        supraStats.qcRemovals.diffthreshold2peakT = NaN;
    end
    
    if isfield(LP.qcRemovals,'minIntervalRe')
        supraStats.qcRemovals.minIntervalRe = LP.qcRemovals.minIntervalRe;
    else
        supraStats.qcRemovals.minIntervalRe = NaN;
    end
    if isfield(LP.qcRemovals,'dVdt0Re')
        supraStats.qcRemovals.dVdt0Re = LP.qcRemovals.dVdt0Re;
    else
        supraStats.qcRemovals.dVdt0Re = NaN;
    end
%     if isfield(LP.qcRemovals,'diffpeak2trough')
%         supraStats.qcRemovals.diffpeak2trough = LP.qcRemovals.diffpeak2trough;
%     else
%         supraStats.qcRemovals.diffpeak2trough = NaN;
%     end
    if isfield(LP.qcRemovals,'minTrough')
        supraStats.qcRemovals.minTrough = LP.qcRemovals.minTrough;
    else
        supraStats.qcRemovals.minTrough = NaN;
    end
    if isfield(LP.qcRemovals,'percentRheobaseHeight')
        supraStats.qcRemovals.percentRheobaseHeight = LP.qcRemovals.percentRheobaseHeight;
    else
        supraStats.qcRemovals.percentRheobaseHeight = NaN;
    end
else
    supraStats.qcRemovals.QCmatT2P = NaN;
    supraStats.qcRemovals.QCmatT2PRe = NaN;
    supraStats.qcRemovals.QCmatTrough = NaN;
    supraStats.qcRemovals.QCmatpercentRheobaseHeight = NaN;
    supraStats.qcRemovals.minInterval = NaN;
    supraStats.qcRemovals.dVdt0 = NaN;
    supraStats.qcRemovals.mindVdt = NaN;
    supraStats.qcRemovals.maxThreshold = NaN;
    supraStats.qcRemovals.diffthreshold2peakN = NaN;
    supraStats.qcRemovals.diffthreshold2peakB = NaN;
    supraStats.qcRemovals.diffthreshold2peakT = NaN;
    supraStats.qcRemovals.minIntervalRe = NaN;
    supraStats.qcRemovals.dVdt0Re = NaN;
%     supraStats.qcRemovals.diffpeak2trough = NaN;
    supraStats.qcRemovals.minTrough = NaN;
    supraStats.qcRemovals.percentRheobaseHeight = NaN;
end

% store NaNs
supraStats.spTimes = NaN;
supraStats.spWaveforms = NaN;
supraStats.peak = NaN; 
supraStats.peakTime = NaN;
supraStats.maxdVdt = NaN;
supraStats.maxdVdtTime = NaN;
supraStats.threshold = NaN;
supraStats.thresholdTime = NaN;
supraStats.thresholdRef = NaN;
supraStats.thresholdRefTime = NaN;
supraStats.trough = NaN;
supraStats.troughTime = NaN;
supraStats.peak2trough = NaN;
supraStats.heightPT = NaN;
supraStats.halfHeightTimeUpPT = NaN;
supraStats.halfHeightTimeDownPT = NaN;
supraStats.fullWidthPT = NaN;
supraStats.heightTP = NaN;
supraStats.halfHeightTimeUpTP = NaN;
supraStats.halfHeightTimeDownTP = NaN;
supraStats.fullWidthTP = NaN;
supraStats.peakUpStroke = NaN;
supraStats.peakDownStroke = NaN;
supraStats.peakStrokeRatio = NaN;
supraStats.fastTrough = NaN;
supraStats.fastTroughDur = NaN;
supraStats.slowTrough = NaN;
supraStats.slowTroughDur = NaN;
supraStats.latency = NaN;
supraStats.meanFR50 = NaN;
supraStats.meanFR100 = NaN;
supraStats.meanFR250 = NaN;
supraStats.meanFR500 = NaN;
supraStats.meanFR750 = NaN;
supraStats.meanFR1000 = NaN;
supraStats.peakAdapt = NaN;
supraStats.ISI = NaN;
supraStats.instaRate = NaN;
supraStats.meanISI = NaN;
supraStats.cvISI = NaN;
supraStats.adaptIndex = NaN;
supraStats.adaptIndex2 = NaN;
supraStats.peakAdapt2 = NaN;
supraStats.delay = NaN;
supraStats.burst = NaN;
supraStats.sweepID = k;