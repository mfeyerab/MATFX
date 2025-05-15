function SpPattrn = getAPTrainParams(CCSers , TabIn, PS, SpPattrn)
SPcount = sum(contains(TabIn.ProtoTag,'SP'));
latency = (min(TabIn.thresTi{PS.supraCount+SPcount}) ...
    -PS.SwDat.StimOn)/round(CCSers.starting_time_rate/1000);
TblIdx = sum(~cellfun(@isempty,SpPattrn.spTrainIDs));

for b = 1:13
SpPattrn.BinTbl(TblIdx,b) = sum(...
    PS.SwDat.sampleRT/13*(b-1) < TabIn.thresTi{PS.supraCount + SPcount}-PS.SwDat.StimOn  & ...
    TabIn.thresTi{PS.supraCount + SPcount}-PS.SwDat.StimOn <= (PS.SwDat.sampleRT/13)*b);
end

SpPattrn.Tab.firingRate(PS.supraCount,1) = ...
                                   length(TabIn.thresTi{PS.supraCount + SPcount});

if length(nonzeros(TabIn.thresTi{PS.supraCount + SPcount})) >= 2						% skip this sweep if there was only 1 
    ISI = abs(diff(TabIn.thresTi{PS.supraCount + SPcount})*(1000/CCSers.starting_time_rate));
	meanISI = mean(ISI);
	cvISI = std(ISI) / meanISI;
	if length(ISI) >= 3
		for i = 1:length(ISI)-1
			numer(i) = (ISI(i+1)-ISI(i))/(ISI(i+1)+ISI(i));
		end
		adaptIndex = sum(numer(2:end))/(length(ISI)-2);		           % Adaptation without first ISI
        clear numer
        tempHt = TabIn.htTP{PS.supraCount + SPcount};
        for i = 1:length(ISI)-1
			numer(i) = (tempHt(i+1)-tempHt(i))/...
                       (tempHt(i+1)+tempHt(i));
		end
		peakAdap = sum(numer)/(length(ISI)-1);
    else
        adaptIndex = NaN;
        peakAdap = NaN;
    end
    if length(ISI) > 1
        burst = 1-(sum(ISI(1))/2)/mean(ISI(2:end));
    else
        burst = NaN;
    end
else
    peakAdap = NaN;
    ISI = NaN;
	meanISI = NaN;
	cvISI = NaN;
	adaptIndex = NaN;
	burst = NaN;
    peakAdap = NaN;
end

if ~isnan(ISI)
    SpPattrn.Tab.latency(PS.supraCount,1) = latency;
    SpPattrn.Tab.peakAdapt(PS.supraCount,1) = peakAdap;
    SpPattrn.ISIs{1,PS.supraCount} = ISI;
    SpPattrn.SpTimes{1,PS.supraCount} = TabIn.thresTi{PS.supraCount + SPcount}';
    SpPattrn.Tab.meanISI(PS.supraCount,1) = meanISI;
    if ~isnan(cvISI) && ~cvISI
        SpPattrn.Tab.cvISI(PS.supraCount,1) = NaN;
    else
        SpPattrn.Tab.cvISI(PS.supraCount,1) = cvISI;
    end
    SpPattrn.Tab.adaptIndex(PS.supraCount,1) = adaptIndex;
    SpPattrn.Tab.burst(PS.supraCount,1) = burst;
    SpPattrn.Tab.LastQuiesence(PS.supraCount,1) = ...
       (CCSers.starting_time_rate - (max(TabIn.thresTi{PS.supraCount + SPcount}) ...
       - PS.SwDat.StimOn))*1000/CCSers.starting_time_rate;
    if SpPattrn.Tab.LastQuiesence(PS.supraCount,1) < 0
      SpPattrn.Tab.LastQuiesence(PS.supraCount,1) = 0;
    end
else
    SpPattrn.Tab.latency(PS.supraCount,1) = nan;
    SpPattrn.Tab.peakAdapt(PS.supraCount,1) = nan;   
    SpPattrn.Tab.burst(PS.supraCount,1) = nan;
    SpPattrn.Tab.LastQuiesence(PS.supraCount,1) = nan;
    SpPattrn.Tab.adaptIndex(PS.supraCount,1) = nan;
    SpPattrn.Tab.cvISI(PS.supraCount,1) = NaN;
end

