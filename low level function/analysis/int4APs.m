function [int4Peak2,putSpTimes2] = int4APs(putSpTimes)

% interval for APs

diffPutAPTime = diff(putSpTimes);                                           % intervals between putative APs
putSpTimes2 = [];
tag = 1;
dCount = 1;
for i = 1:length(putSpTimes)-1
	if diffPutAPTime(i) ~= 1
		int4Peak{dCount} = putSpTimes(tag):putSpTimes(i);
		putSpTimes2(dCount) = putSpTimes(tag);
		tag = i+1;
		dCount = dCount + 1;                                                % count of intervals
	end
end
int4Peak{dCount} = putSpTimes(tag):putSpTimes(end);
putSpTimes2(dCount) = putSpTimes(tag);
clear diffPutAPTime tag dCount i

inds2remove = [];
Z = 1:length(putSpTimes2);
ind2keep = find(~ismember(Z,inds2remove)==1);

putSpTimes2 = putSpTimes2(ind2keep);

dCount = 1;
int4Peak2 = [];
for i = ind2keep
	int4Peak2{dCount} = int4Peak{i};
	dCount = dCount + 1;
end
clear ind2keep int4Peak dCount ind2keep