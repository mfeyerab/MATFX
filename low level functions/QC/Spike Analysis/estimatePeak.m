function [sp] = estimatePeak(protocol,int4Peak2,k)

% estimate peak of AP
if length(protocol.putSpTimes2)==1
	for i = 1:length(int4Peak2)
		[peak(i), peakTime(i)]= max(protocol.V{k,1}(int4Peak2{i}(1)-1:int4Peak2{i}(end)-1));
	end
elseif length(protocol.putSpTimes2)>1
	maxTPeakMax = round(mean(diff(protocol.putSpTimes2))*.25);
	for i = 1:length(int4Peak2)
		if (int4Peak2{i}(end)-int4Peak2{i}(1))>maxTPeakMax
			[peak(i), peakTime(i)]= max(protocol.V{k,1}...
                (int4Peak2{i}(1)-1:int4Peak2{i}(end)-maxTPeakMax));
		else
			[peak(i), peakTime(i)]= max(protocol.V{k,1}...
                (int4Peak2{i}(1)-1:int4Peak2{i}(end)));
        end
    end
end
peakTime = protocol.putSpTimes2 + peakTime - 2;

sp.peak = peak;
sp.peakTime = peakTime;