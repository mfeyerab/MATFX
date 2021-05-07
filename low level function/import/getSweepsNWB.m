% getSweepsNWB for NWB 2.0

%% Getting hdf5 structure labels of sweeps
fileName = [cellList(n).folder, '\', cellList(n).name];                    % file name
info = h5info(fileName);                                                   % pull info/hdf5 structure from file   
level.Acquisition = info.Groups(1);                                        % nwb level for acquisition parameters
level.Stimulus = info.Groups(6);                                           % nwb level for stimulus information
for s = 1:length(info.Groups(1).Groups)                                    % for each sweep
    name_fields = extractfield(info.Groups(1).Groups(s).Attributes, 'Name');% extract all the elements of the field name
    idx_stim_name = find(strcmp(name_fields,'stimulus_description'));       % find the index of the cell 'stimulus_description'   
    protocol_name{s,1} = ...
        info.Groups(1).Groups(s).Attributes(idx_stim_name).Value;          % store stimulus name
end
clear s idx_stim_name name_fields

sweep_label = extractfield(info.Groups(1).Groups, 'Name');                  % get the names of all acquired sweeps 

%% Get Metadata on cell hierachy

if ~H5L.exists(H5G.open(H5F.open(fileName), ...
        '/specifications/'),'ndx-mies','H5P_DEFAULT')     

    Metadata.inital_access_resistance = h5read( ...
        fileName,['/general/Initial access resistance']);                      % saves inital access resistance of the cell 

    if ischar(Metadata.inital_access_resistance) || ...
            isstring(Metadata.inital_access_resistance)
       Metadata.inital_access_resistance = ...
           str2double(Metadata.inital_access_resistance);
    end    

    Metadata.temperature = h5read(...
        fileName,['/general/Temperature']);                                    %

    if ischar(Metadata.temperature) || ...
            isstring(Metadata.temperature)
       Metadata.temperature = ...
           str2double(Metadata.temperature);
    end    


    Metadata.membrane_resistance = h5read(...
        fileName,['/general/Membrane resistance']);                            %

    if ischar(Metadata.membrane_resistance) || ...
            isstring(Metadata.membrane_resistance)
       Metadata.membrane_resistance = ...
           str2double(Metadata.membrane_resistance);
    end    

else
    Metadata = struct();
    
end

%% Extracting data of relevant protocols

LP.fullStruct = 1; SP.fullStruct = 1; NONAIBS.fullStruct = 0;

for s = 1:length(protocol_name)     % for each sweep with this cell
    isVC = false;
    if ~contains(protocol_name{s,1},'tuning') && ...                         % tuning protocol will be ignored
            ~contains(protocol_name{s,1},'EXTP') &&...
            ~contains(protocol_name{s,1},'_Search')&&...
            ~contains(protocol_name{s,1},'VC')&&...
            ~contains(protocol_name{s,1},'Rheobase_finder')&&...
            ~contains(protocol_name{s,1},'Blank_pilot')&&...
            ~contains(protocol_name{s,1},'C1SQC')&&...
        exist('sweep_label','var') 
    level.Resp = level.Acquisition.Groups(s).Name;  
    
       if H5L.exists(H5G.open(H5F.open(fileName), ...
        '/specifications/'),'ndx-mies','H5P_DEFAULT')    
         
       level.Stim = ['/stimulus/presentation/', ...
                 level.Resp(14:end)];
         if level.Resp(end-2:end) == 'AD0'
           level.Stim(end-2:end) = 'DA0';
         else   
           level.Stim(end-2:end) = 'DA1';
         end   
       else
    level.Stim = ['/stimulus/presentation/index_' ...
        level.Resp(end+(20-length(level.Resp)):end)];  
       end
    if contains(protocol_name{s,1},'long_pulse')|| ...
           contains(protocol_name{s,1},'LP') || ...
             contains(protocol_name{s,1},'SubThresh') ||...
                contains(protocol_name{s,1},'LS')  ||...                        % checks for all long pulse protocols
                   contains(protocol_name{s,1},'subthreshold') ||...
                     contains(protocol_name{s,1},'SupraThresh')
            parametersNWB_LP
        LP.name = "long pulse";
    elseif contains(protocol_name{s,1},'short_pulse') || ...
              contains(protocol_name{s,1},'SP')  || ...
            contains(protocol_name{s,1},'SS')                     % if short (3ms) current pulse
        parametersNWB_SP
        SP.name = "short pulse";
    elseif  contains(protocol_name{s,1},'gapfree')
        parametersNWB_gapfree
        gapfree.name = "gapfree";
    else
        parametersNWB_NONAIBS
        NONAIBS.name = "NONAIBS"; 
    end
   end
end

if LPcount == 1
    LP.fullStruct = 0;
end
if SPcount == 1
    SP.fullStruct = 0;
end
if NONAIBScount == 1
    NONAIBS.fullStruct = 0;
end

clear protocol_name s LPcount SPcount NONAIBScount sweep_label