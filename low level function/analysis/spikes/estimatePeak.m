function [sp] = estimatePeak(startInt4Peak,int4Peak,CCSeries)

% estimate peak of AP
if length(startInt4Peak)==1 && length(int4Peak{:}) < length(CCSeries.data.load())
	for i = 1:length(int4Peak)
		[peak(i), peakTime(i)]= max(CCSeries.data.load(int4Peak{i}(1)-1:int4Peak{i}(end)-1));
	end
elseif length(startInt4Peak)>1
	maxTPeakMax = round(mean(diff(startInt4Peak))*.25);
	for i = 1:length(int4Peak)
		if (int4Peak{i}(end)-int4Peak{i}(1))>maxTPeakMax
			[peak(i), peakTime(i)]= max(CCSeries.data.load...
                (int4Peak{i}(1)-1:int4Peak{i}(end)-maxTPeakMax));
		else
			[peak(i), peakTime(i)]= max(CCSeries.data.load...
                (int4Peak{i}(1)-1:int4Peak{i}(end)));
        end
    end
end

if exist('peakTime')
peakTime = startInt4Peak + peakTime - 2;
sp.peak = peak;
sp.peakTime = peakTime;
else
sp = [];    
end    