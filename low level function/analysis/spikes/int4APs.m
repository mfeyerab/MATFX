function [int4Peak,putSpTimes2] = int4APs(putSpTimes, PS)

% interval for APs

diffPutAPTi = diff(putSpTimes);                                           % intervals between putative APs
diffPutAPTiStarts= find(diffPutAPTi~=1);
diffPutAPTiStarts = [1; diffPutAPTiStarts+1];
putSpTimes2 = [];
dCount = 1;
int4Peak = {};

for i = 1:length(diffPutAPTiStarts)
    if i==length(diffPutAPTiStarts) && length(diffPutAPTi) - diffPutAPTiStarts(i) > ...
                PS.ThresHFNoise/(1000/PS.sampleRT) 
        int4Peak{dCount} = putSpTimes(diffPutAPTiStarts(i)):...
        putSpTimes(end);
        putSpTimes2(dCount) = putSpTimes(diffPutAPTiStarts(i));
        dCount = dCount + 1; 
    elseif i~=length(diffPutAPTiStarts) && ...
            length(diffPutAPTiStarts(i):diffPutAPTiStarts(i+1)-1) > ...
                PS.ThresHFNoise/(1000/PS.sampleRT) 
		int4Peak{dCount} = putSpTimes(diffPutAPTiStarts(i)):...
            putSpTimes(diffPutAPTiStarts(i+1)-1);
        putSpTimes2(dCount) = putSpTimes(diffPutAPTiStarts(i));
        dCount = dCount + 1; 
    end
end

if ~isempty(int4Peak)
   inds2remove = [false, ...
    diff(cellfun(@(x) x(1,1),int4Peak))< PS.minISI/(1000/PS.sampleRT)];
   if any(inds2remove)
     disp(['Potential spikes removed due to ISI violation of <',...
        num2str(PS.minISI), ' ms' ])
    int4Peak(inds2remove) = [];
    putSpTimes2(inds2remove) = [];
   end
end