% parametersNWB_LP

temp = h5read(fileName,[level.Resp,'/data'])'*1000;
stimFun = h5read(fileName,[level.Stim,'/data']);
if sum(h5readatt(fileName,[level.Stim,'/starting_time'],'unit') == 'Seconds')==7
    LP.acquireRes = 1000/h5readatt(fileName,[level.Stim,'/starting_time'],'rate');
end
tempStimOn = find(stimFun(10000:end,1)~=0,1,'first')+10000-1;                 % offset by 10,000 timepoints to avoid test pulses
LP.stimOff(1,LPcount) = find(stimFun~=0,1,'last')+1;
stimDur = (LP.stimOff(1,LPcount)-tempStimOn)*LP.acquireRes;
if length(unique(stimFun))==3 && ...
        length(findpeaks(stimFun))<=2 && ...
        stimDur==1000 && ...
        length(temp)>=LP.stimOff(1,LPcount)+(postLP/LP.acquireRes)              % errors in curation
    LP.V{1,LPcount} = temp(tempStimOn-(preLP/LP.acquireRes):LP.stimOff(1,LPcount)+(postLP/LP.acquireRes));
    LP.stimOn(1,LPcount) = tempStimOn-(tempStimOn-(preLP/LP.acquireRes));
    LP.stimOff(1,LPcount) = LP.stimOff(1,LPcount)-(tempStimOn-(preLP/LP.acquireRes));
    LP.sweepAmps(LPcount,1) = h5read(fileName,[level.Stim,'/aibs_stimulus_amplitude_pa']);
    LPcount = LPcount + 1;
end
clear stimFun temp stimDur
