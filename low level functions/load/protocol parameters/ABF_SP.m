% parametersABF_SP

SP.acquireRes = h.fADCSampleInterval/1000;                                     % resolution of acquisition
if SP.acquireRes == 0.1
    constantShift = 0;                                                   % shift for input versus response
elseif SP.acquireRes == 0.05
    constantShift = 626;
    if sum(fileList(k).name(1:4)=='2018')==4 ...
            || sum(fileList(k).name(1:2)=='18')==2 ...
            || sum(fileList(k).name(1:4)=='2019')==4 ...
            || sum(fileList(k).name(1:2)=='19')==2 
        constantShift = 32;
    end
end

if ismember(cellList(n).name,listToCorrect)
    temp(1,1:size(d,2)) = h.DACEpoch.lEpochInitDuration(1)+constantShift-(150/SP.acquireRes);                    % stimulus turns on
    SP.stimOff(1,1:size(d,2)) = temp+h.DACEpoch.lEpochInitDuration(2);                        % stimulus turns off
else
    temp(1,1:size(d,2)) = h.DACEpoch.lEpochInitDuration(1)+constantShift;                    % stimulus turns on
    SP.stimOff(1,1:size(d,2)) = temp + h.DACEpoch.lEpochInitDuration(2);                        % stimulus turns off
end
for swp = 1:size(d,2)
    SP.V{swp,1} = d(temp(1,swp)-(preSP/SP.acquireRes):SP.stimOff(1,swp)+(postSP/SP.acquireRes),swp)';
    SPcount = SPcount + 1;
end
SP.stimOn = temp-(temp-(preSP/SP.acquireRes));
SP.stimOff = SP.stimOff-(temp-(preSP/SP.acquireRes));
tempC = length(SP.V);
SP.input = h.DACEpoch.fEpochInitLevel(2);
SP.inputInc = h.DACEpoch.fEpochLevelInc(2);
SP.sweepAmps(1:size(d,2),1) = SP.input+(0:tempC-1)*SP.inputInc;
SP.filenames = fileList(k).name;
clear d h constantShift tempC
