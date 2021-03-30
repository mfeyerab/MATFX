RAMP1.acquireRes = h.fADCSampleInterval/1000;                                     % resolution of acquisition
RAMP1.stimOn = preRAMP1/RAMP1.acquireRes;                                         % stimulus turns on
RAMP1.stimOff = postRAMP1/RAMP1.acquireRes;                     % stimulus turns off

RAMP1.V{1} = squeeze(d)';
tempC = length(RAMP1.V);
RAMP1.input = h.DACEpoch.fEpochInitLevel(1);
RAMP1.inputInc = h.DACEpoch.fEpochLevelInc(1);
RAMP1.sweepAmps = RAMP1.input+(0:tempC-1)*RAMP1.inputInc;
RAMP1.filenames = fileList(k).name;
RAMP1count = RAMP1count + 1;

clear d h constantShift tempC temp
