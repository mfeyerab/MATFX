function [sp] = estimateAPTrainParams(LP,sp,k)

% estimate AP train parameters

latency = (sp.thresholdRefTime(1)-LP.stimOn(1,k))*LP.acquireRes(1,k);
% not a firing rate, simply a sum of spikes
meanFR50 = sum(sp.thresholdRefTime<(LP.stimOn(1,k)+(50/LP.acquireRes(1,k)))) / 0.05;
meanFR100 = sum(sp.thresholdRefTime<(LP.stimOn(1,k)+(100/LP.acquireRes(1,k)))) / 0.1;
meanFR250 = sum(sp.thresholdRefTime<(LP.stimOn(1,k)+(250/LP.acquireRes(1,k)))) / 0.25;
meanFR500 = sum(sp.thresholdRefTime<(LP.stimOn(1,k)+(500/LP.acquireRes(1,k)))) / 0.5;
meanFR750 = sum(sp.thresholdRefTime<(LP.stimOn(1,k)+(750/LP.acquireRes(1,k)))) / 0.75;
meanFR1000 = sum(sp.thresholdRefTime<(LP.stimOn(1,k)+(1000/LP.acquireRes(1,k))));

if length(sp.thresholdRefTime) >= 2						% skip this sweep if there was only 1 
    peakAdapt = sp.heightTP(end) / sp.heightTP(1);
    ISI = diff(sp.thresholdRefTime)*LP.acquireRes(1,k);
	instaRate = 1./ISI;
	meanISI = mean(ISI);
	cvISI = std(ISI) / meanISI;
	if length(ISI) >= 3
		for i = 1:length(ISI)-1
			numer(i) = (ISI(i+1)-ISI(i))/(ISI(i+1)+ISI(i));
		end
		adaptIndex = sum(numer)/(length(ISI)-1);
		adaptIndex2 = ISI(end)/ISI(1);			% if > 1, neuron adapts
        clear numer
        for i = 1:length(ISI)-1
			numer(i) = (sp.heightTP(i+1)-sp.heightTP(i))/...
                (sp.heightTP(i+1)+sp.heightTP(i));
		end
		peakAdapt2 = sum(numer)/(length(ISI)-1);
        clear numer
    else
        adaptIndex = NaN;
        adaptIndex2 = NaN;
        peakAdapt2 = NaN;
    end
	delay = latency/meanISI;
    if length(ISI) > 1
        burst = sum(ISI(1:2))/2;
    else
        burst = NaN;
    end
else
    peakAdapt = NaN;
    ISI = NaN;
    instaRate = NaN;
	meanISI = NaN;
	cvISI = NaN;
	adaptIndex = NaN;
    adaptIndex2 = NaN;
	delay = NaN;
	burst = NaN;
    peakAdapt2 = NaN;
end

sp.latency = latency;
sp.meanFR50 = meanFR50;
sp.meanFR100 = meanFR100;
sp.meanFR250 = meanFR250;
sp.meanFR500 = meanFR500;
sp.meanFR750 = meanFR750;
sp.meanFR1000 = meanFR1000;
sp.peakAdapt = peakAdapt;
sp.ISI = ISI;
sp.instaRate = instaRate;
sp.meanISI = meanISI;
sp.cvISI = cvISI;
sp.adaptIndex = adaptIndex;
sp.adaptIndex2 = adaptIndex2;
sp.peakAdapt2 = peakAdapt2;
sp.delay = delay;
sp.burst = burst;