function SpPattrn = estimateAPTrainParams(sp,StimOn,CCSeries,supraCount, SpPattrn)

latency = (sp.thresholdTime(1)-StimOn)/round(CCSeries.starting_time_rate/1000);

TblIdx = sum(~cellfun(@isempty,SpPattrn.spTrainIDs));

for b = 1:13
SpPattrn.BinTbl(TblIdx,b) = sum(...
    76.9*(b-1)/(1000/CCSeries.starting_time_rate) < sp.thresholdTime - StimOn ...
    & sp.thresholdTime - StimOn < 76.9*b/(1000/CCSeries.starting_time_rate));
end

SpPattrn.spTrain.firingRate(supraCount,1) = sum(sp.thresholdTime<(StimOn+(1000/(1000/CCSeries.starting_time_rate))));
SpPattrn.RowNames{TblIdx} = char(SpPattrn.spTrainIDs(supraCount));

if length(nonzeros(sp.thresholdTime)) >= 2						% skip this sweep if there was only 1 
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
        burst = (sum(ISI(1:2))/2)/meanISI;
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

SpPattrn.spTrain.latency(supraCount,1) = latency;
SpPattrn.spTrain.peakAdapt(supraCount,1) = peakAdapt;
SpPattrn.ISIs{1,supraCount} = ISI;

SpPattrn.spTrain.meanISI(supraCount,1) = meanISI;
if ~isnan(cvISI) && ~cvISI
    SpPattrn.spTrain.cvISI(supraCount,1) = NaN;
else
    SpPattrn.spTrain.cvISI(supraCount,1) = cvISI;
end
SpPattrn.spTrain.adaptIndex(supraCount,1) = adaptIndex;
SpPattrn.spTrain.adaptIndex2(supraCount,1) = adaptIndex2;
SpPattrn.spTrain.peakAdapt2(supraCount,1) = peakAdapt2;
SpPattrn.spTrain.delay(supraCount,1) = delay;
SpPattrn.spTrain.burst(supraCount,1) = burst;
SpPattrn.spTrain.LastQuiesence(supraCount,1) = ...
   (StimOn + CCSeries.starting_time_rate - sp.thresholdTime(...
   length(sp.thresholdTime)))*1000/CCSeries.starting_time_rate;
if SpPattrn.spTrain.LastQuiesence(supraCount,1) < 0
  SpPattrn.spTrain.LastQuiesence(supraCount,1) = 0;
end
