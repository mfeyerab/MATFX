function [wf] = getWaveforms(LP,params,sp,k)

%{
getWaveforms
%}

params.windowBeg = round(1.2/LP.acquireRes(1,k));              % time prior to spike
params.windowEnd = round(5/LP.acquireRes(1,k));              % time after spike
params.windowBegS = round(1/params.sampleRTdt);         % time prior to spike
params.windowEndS = round(3.5/params.sampleRTdt);         % time after spike

% wf(1,:) = singleWaveform(LP,sp,params,k,1);
% for wfCount = 2:5
%     if length(sp.peakTime) >= wfCount
%         wf(wfCount,:) = singleWaveform(LP,sp,params,k,wfCount);
%     end
% end

wf = singleWaveform(LP,sp,params,k,1);