
for f = 1:length(noise_files)
[d_temp,~,h] = abfload(strcat(fileList(k).folder,'/', noise_files(f)), ...
    'sweeps','a','channels','a');   
meta_data(f) = h;
NOISE1.V{f,1} = d_temp';
end
NOISE1.acquireRes = meta_data(1).fADCSampleInterval/1000;  

for f = 1:length(noise_files)
NOISE1.stimOn(1,f) = preNOISE1/NOISE1.acquireRes;                    % stimulus turns on
NOISE1.stimOff(1,f) = NOISE1.stimOn(1,f) + 1000/NOISE1.acquireRes;                        % stimulus turns off 
NOISE1.input{f,1} = meta_data(f).DACEpoch.fEpochInitLevel(1);
NOISE1.inputInc{f,1} = meta_data(f).DACEpoch.fEpochLevelInc(1);
NOISE1.sweepAmps(f,1) = str2double(meta_data(f).protocolName(end-7:end-6));
NOISE1.filenames{f,1} = noise_files(f);
end
                                   % resolution of acquisition
NOISE1count = NOISE1count + 1;
clear d h constantShift tempC temp meta_data d_temp
