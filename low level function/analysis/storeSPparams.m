function supraStats = storeSPparams(LP,sp,wf,k)

%{
storeSPparams
%}

supraStats.qcRemovals.QCmatT2P = LP.qcRemovals.QCmatT2P;
supraStats.qcRemovals.minInterval = LP.qcRemovals.minInterval;
supraStats.qcRemovals.dVdt0 = LP.qcRemovals.dVdt0;
supraStats.qcRemovals.mindVdt = LP.qcRemovals.mindVdt;
supraStats.qcRemovals.maxThreshold = LP.qcRemovals.maxThreshold;
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
supraStats.qcRemovals.diffthreshold2peakT = LP.qcRemovals.diffthreshold2peakT;
supraStats.qcRemovals.QCmatT2PRe = LP.qcRemovals.QCmatT2PRe;
supraStats.qcRemovals.minIntervalRe = LP.qcRemovals.minIntervalRe;
supraStats.qcRemovals.dVdt0Re = LP.qcRemovals.dVdt0Re;
supraStats.qcRemovals.QCmatTrough = LP.qcRemovals.QCmatTrough;
% supraStats.qcRemovals.diffpeak2trough = LP.qcRemovals.diffpeak2trough;
supraStats.qcRemovals.minTrough = LP.qcRemovals.minTrough;
supraStats.qcRemovals.percentRheobaseHeight = LP.qcRemovals.percentRheobaseHeight;
supraStats.qcRemovals.QCmatpercentRheobaseHeight = LP.qcRemovals.QCmatpercentRheobaseHeight;

supraStats.spTimes = LP.putSpTimes2;
supraStats.peak = sp.peak; 
supraStats.peakTime = sp.peakTime;
supraStats.maxdVdt = sp.maxdVdt;
supraStats.maxdVdtTime = sp.maxdVdtTime;
supraStats.threshold = sp.threshold;
supraStats.thresholdTime = sp.thresholdTime;
supraStats.thresholdRef = sp.thresholdRef;
supraStats.thresholdRefTime = sp.thresholdRefTime;
supraStats.trough = sp.trough;
supraStats.troughTime = sp.troughTime;
supraStats.peak2trough = (sp.troughTime-sp.peakTime).*LP.acquireRes(1,k);
supraStats.heightPT = sp.heightPT;
supraStats.halfHeightTimeUpPT = sp.halfHeightTimeUpPT;
supraStats.halfHeightTimeDownPT = sp.halfHeightTimeDownPT;
supraStats.fullWidthPT = sp.fullWidthPT;
supraStats.heightTP = sp.heightTP;
supraStats.halfHeightTimeUpTP = sp.halfHeightTimeUpTP;
supraStats.halfHeightTimeDownTP = sp.halfHeightTimeDownTP;
supraStats.fullWidthTP = sp.fullWidthTP;
supraStats.peakUpStroke = sp.peakUpStroke;
supraStats.peakDownStroke = sp.peakDownStroke;
supraStats.peakStrokeRatio = sp.peakStrokeRatio;
supraStats.latency = sp.latency;
supraStats.meanFR50 = sp.meanFR50;
supraStats.meanFR100 = sp.meanFR100;
supraStats.meanFR250 = sp.meanFR250;
supraStats.meanFR500 = sp.meanFR500;
supraStats.meanFR750 = sp.meanFR750;
supraStats.meanFR1000 = sp.meanFR1000;
supraStats.peakAdapt = sp.peakAdapt;
supraStats.ISI = sp.ISI;
supraStats.instaRate = sp.instaRate;
supraStats.meanISI = sp.meanISI;
supraStats.cvISI = sp.cvISI;
supraStats.adaptIndex = sp.adaptIndex;
supraStats.adaptIndex2 = sp.adaptIndex2;
supraStats.peakAdapt2 = sp.peakAdapt2;
supraStats.delay = sp.delay;
supraStats.burst = sp.burst;
if isfield(sp,'fast_trough')
    supraStats.fastTrough = sp.fast_trough;
    supraStats.fastTroughDur = sp.fast_trough_dur;
else
    supraStats.fastTrough = NaN;
    supraStats.fastTroughDur = NaN;
end
if isfield(sp,'slow_trough')
    supraStats.slowTrough = sp.slow_trough;
    supraStats.slowTroughDur = sp.slow_trough_dur;
else
    supraStats.slowTrough = NaN;
    supraStats.slowTroughDur = NaN;
end
supraStats.waves = wf;
supraStats.sweepID = k;