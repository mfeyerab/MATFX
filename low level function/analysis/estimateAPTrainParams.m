function [spTrain, ISIs] = estimateAPTrainParams(sp,StimOn,CCSeries,supraCount, ISIs, spTrain)

latency = (sp.thresholdTime(1)-StimOn)/round(CCSeries.starting_time_rate/1000);
% not a firing rate, simply a sum of spikes
spTrain.meanFR50(supraCount,1) = sum(sp.thresholdTime<(StimOn+(50/(1000/CCSeries.starting_time_rate)))) / 0.05;
spTrain.meanFR100(supraCount,1) = sum(sp.thresholdTime<(StimOn+(100/(1000/CCSeries.starting_time_rate)))) / 0.1;
spTrain.meanFR250(supraCount,1) = sum(sp.thresholdTime<(StimOn+(250/(1000/CCSeries.starting_time_rate)))) / 0.25;
spTrain.meanFR500(supraCount,1) = sum(sp.thresholdTime<(StimOn+(500/(1000/CCSeries.starting_time_rate)))) / 0.5;
spTrain.meanFR750(supraCount,1) = sum(sp.thresholdTime<(StimOn+(750/(1000/CCSeries.starting_time_rate)))) / 0.75;
spTrain.meanFR1000(supraCount,1) = sum(sp.thresholdTime<(StimOn+(1000/(1000/CCSeries.starting_time_rate))));

if length(sp.thresholdTime) >= 2						% skip this sweep if there was only 1 
    peakAdapt = sp.heightTP(end) / sp.heightTP(1);
    ISI = diff(sp.thresholdTime)*(1000/CCSeries.starting_time_rate);
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
	meanISI = NaN;
	cvISI = NaN;
	adaptIndex = NaN;
    adaptIndex2 = NaN;
	delay = NaN;
	burst = NaN;
    peakAdapt2 = NaN;
end

spTrain.latency(supraCount,1) = latency;
spTrain.peakAdapt(supraCount,1) = peakAdapt;
ISIs{1,supraCount} = ISI;

spTrain.meanISI(supraCount,1) = meanISI;
spTrain.cvISI(supraCount,1) = cvISI;
spTrain.adaptIndex(supraCount,1) = adaptIndex;
spTrain.adaptIndex2(supraCount,1) = adaptIndex2;
spTrain.peakAdapt2(supraCount,1) = peakAdapt2;
spTrain.delay(supraCount,1) = delay;
spTrain.burst(supraCount,1) = burst;
