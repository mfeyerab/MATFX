function [sp,LP] = estimateTrough(LP,sp,k,params)

% estimate Trough

% need to add fast and slow trough distinctions

win = 15/LP.acquireRes(1,k);
if length(sp.peakTime) > 1
	for i = 1:length(sp.peakTime)-1
		[trough(i),temp] = min(LP.V{1,k}(sp.peakTime(i):sp.peakTime(i+1)));
		troughTime(i) = sp.peakTime(i)+temp(1)-1;
    end
    [trough(i+1),temp] = min(LP.V{1,k}(sp.peakTime(i+1):sp.peakTime(i+1)+win));
    troughTime(i+1) = sp.peakTime(i+1)+temp(1)-1;
elseif length(sp.peakTime) == 1
    [trough(1),temp] = min(LP.V{1,k}(sp.peakTime(1):sp.peakTime(1)+win));
    troughTime(1) = sp.peakTime(1)+temp(1)-1;
end

%{
QCpeakNtrough
%}

% diffpeak2trough = abs(trough-sp.peak);

% LP.qcRemovals.QCmatTrough = [(diffpeak2trough < params.minDiffPeak2Trough)', ...
%     (trough>params.minTrough)'];
LP.qcRemovals.QCmatTrough = trough>params.minTrough';

% idx = diffpeak2trough < params.minDiffPeak2Trough;
% LP.qcRemovals.diffpeak2trough = LP.putSpTimes2(idx);
% LP.putSpTimes2(idx) = [];
% sp.peak(idx) = []; sp.peakTime(idx) = []; 
% trough(idx) = []; troughTime(idx) = [];
% sp.threshold(idx) = []; sp.thresholdTime(idx) = [];
% sp.maxdVdt(idx) = []; sp.maxdVdtTime(idx) = [];
% sp.thresholdRef(idx) = []; sp.thresholdRefTime(idx) = [];

idx2 = trough > params.minTrough;
LP.qcRemovals.minTrough = LP.putSpTimes2(idx2);
LP.putSpTimes2(idx2) = [];
sp.peak(idx2) = []; sp.peakTime(idx2) = []; 
trough(idx2) = []; troughTime(idx2) = [];
sp.threshold(idx2) = []; sp.thresholdTime(idx2) = [];
sp.maxdVdt(idx2) = []; sp.maxdVdtTime(idx2) = [];
sp.thresholdRef(idx2) = []; sp.thresholdRefTime(idx2) = [];

sp.trough = trough;
sp.troughTime = troughTime;