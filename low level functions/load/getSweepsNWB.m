% getSweepsNWB

fileName = [fileList(k).folder,'/','ephys.nwb'];                                   % file name
info = h5info(fileName);                                                % pull info from file
level.Acquisition = info.Groups(1);                                     % nwb level for acquisition parameters
level.Epochs = info.Groups(3);                                          % nwb level for epoch information
for s = 1:length(level.Epochs.Groups)/3                                     % for each experiment
    level.Exp = level.Epochs.Groups(s).Groups(2).Groups(1).Name;            % get stimulus protocol name level
    stimulus_name{s,1} = h5read(fileName,[level.Exp,'/aibs_stimulus_name']);% store stimulus name
end
clear s nExperiments
N.sweeps = length(stimulus_name);                                       % count of sweeps recorded

LP.fullStruct = 1; SP.fullStruct = 1;
for s = 1:N.sweeps                                                      % for each sweep with this cell
    level.Stim = cell2mat(info.Groups(6).Groups(1).Links(s).Value);         % stimulus level
    level.Resp = level.Acquisition.Groups(2).Groups(s).Name;                % response level
    if length(stimulus_name{s,1}) == 11 && ...
        sum(stimulus_name{s,1} == 'Long Square')==length(stimulus_name{s,1})                                          % if long current pulse
        parametersNWB_LP
    elseif length(stimulus_name{s,1}) == 12 && ...
        sum(stimulus_name{s,1} == 'Short Square')==length(stimulus_name{s,1})                                        % if short (3ms) current pulse
        parametersNWB_SP
    end
    
    
    %%% Here we are going to add various other types of stimulus protocols
    
    
    
end
if LPcount == 1
    LP.fullStruct = 0;
end
if SPcount == 1
    SP.fullStruct = 0;
end
clear LPcount SPcount stimulus_name s
