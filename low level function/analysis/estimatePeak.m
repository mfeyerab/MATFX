function [sp] = estimatePeak(LP,int4Peak2,k)

% estimate peak of AP
if length(LP.putSpTimes2)==1
	for i = 1:length(int4Peak2)
		[peak(i), peakTime(i)]= max(LP.V{1,k}(int4Peak2{i}(1)-1:int4Peak2{i}(end)-1));
	end
elseif length(LP.putSpTimes2)>1
	maxTPeakMax = round(mean(diff(LP.putSpTimes2))*.25);
	for i = 1:length(int4Peak2)
		if (int4Peak2{i}(end)-int4Peak2{i}(1))>maxTPeakMax
			[peak(i), peakTime(i)]= max(LP.V{1,k}...
                (int4Peak2{i}(1)-1:int4Peak2{i}(end)-maxTPeakMax));
		else
			[peak(i), peakTime(i)]= max(LP.V{1,k}...
                (int4Peak2{i}(1)-1:int4Peak2{i}(end)));
        end
    end
end
peakTime = LP.putSpTimes2 + peakTime - 2;

sp.peak = peak;
sp.peakTime = peakTime;