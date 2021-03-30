% parametersABF_LP

clear temp

LP.acquireRes = h.fADCSampleInterval/1000;                                     % resolution of acquisition
if LP.acquireRes == 0.1
    constantShift = 3126; 
elseif LP.acquireRes == 0.2                % shift for input versus response
    constantShift = 3124*0.5;
elseif LP.acquireRes == 0.05
    constantShift = 6268;
    if sum(fileList(k).name(1:4)=='2018')==4 ...
            || sum(fileList(k).name(1:2)=='18')==2 ...
            || sum(fileList(k).name(1:4)=='2019')==4 ...
            || sum(fileList(k).name(1:2)=='19')==2                    % brutal 
        constantShift = 3126;        
    end
end
if ismember(cellList(n).name,listToCorrect)
    temp(1,1:size(d,2)) = h.DACEpoch.lEpochInitDuration(1)+constantShift-(150/LP.acquireRes);                    % stimulus turns on
    LP.stimOff(1,1:size(d,2)) = temp+h.DACEpoch.lEpochInitDuration(2);                        % stimulus turns off
else
    temp(1,1:size(d,2)) = h.DACEpoch.lEpochInitDuration(1)+constantShift;                    % stimulus turns on
    LP.stimOff(1,1:size(d,2)) = temp + h.DACEpoch.lEpochInitDuration(2);                        % stimulus turns off
end
for swp = 1:size(d,2)
    LP.V{swp,1} = d(temp(1,swp)-(preLP/LP.acquireRes):LP.stimOff(1,swp)+(postLP/LP.acquireRes),swp)';
    LPcount = LPcount + 1;
end
LP.stimOn = temp-(temp-(preLP/LP.acquireRes));
LP.stimOff = LP.stimOff-(temp-(preLP/LP.acquireRes));
tempC = length(LP.V);
LP.input = h.DACEpoch.fEpochInitLevel(2);
LP.inputInc = h.DACEpoch.fEpochLevelInc(2);
LP.sweepAmps(1:size(d,2),1) = LP.input+(0:tempC-1)*LP.inputInc;
LP.filenames = fileList(k).name;
clear d h constantShift tempC temp
