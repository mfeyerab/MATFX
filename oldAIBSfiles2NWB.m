clear

mainfolder = 'D:\conversion\Allen\First_release\cell_types\'; %fullfile(cd, '\test_cell\');
outputfolder = 'D:\output_MATNWB\'; %[cd, '\'];
cellList = dir([mainfolder,'*.nwb']);
T = struct2table(load('cell_types_specimen_details.mat'));
alignSamplingMode = 1;
SamplingTarget = 20000;

for n = 1:length(cellList)
    
    cellID = regexp(cellList(n).name,'\d*','Match');
    disp(cellID)  
    idx = find(strcmp(num2str(T.specimen__id1), cellID));
    %% Initializing variables for Sweep table construction
    
    noManuTag = 0;
    sweepCount = 1;
    sweep_series_objects_ch1 = []; sweep_series_objects_ch2 = [];
    filename = [mainfolder,cellList(n).name];
    SweepAmp = [];StimOff = []; StimOn = [];
    %%   Initializing nwb file 
    nwb = NwbFile();
    nwb.identifier = cellList(n,1).name;
    nwb.session_description = ...
      'Characterizing intrinsic biophysical properties of cortical neurons; First release from AIBS';

    if isempty(idx)
        disp('Manual entry data not found')
        noManuTag = 1;
         nwb.general_subject = types.core.Subject( ...
      'description', 'NA', 'age', 'NA', ...
      'sex', 'NA', 'species', 'NA');
       corticalArea = 'NA'; 
       initAccessResistance = 'NA';
    else    
      nwb.general_subject = types.core.Subject( ...
        'subject_id', char(T.donor__id(idx)), 'age', num2str(T.donor__age(idx)), ...
        'sex', char(T.donor__sex(idx)), 'species', char(T.donor__species1(idx)), ...
         'genotype', char(T.line_name1(idx)) );      
    end
     nwb.general_institution = 'Allen Institute of Brain Science';
     device_name = 'unknown device';

     nwb.general_devices.set(device_name, types.core.Device());     
     nwb.general_source_script = 'custom matlab script using MATNWB';
     nwb.general_source_script_file_name = mfilename;
     
     
     %% Add anatomical data from histological processing
     
     anatomy = types.core.ProcessingModule(...
                         'description', 'Histological processing',...
                         'dynamictable', []  ...
                               );     
     T.Properties.VariableNames{49}= 'SomaLayerLoc';
     T.Properties.VariableNames{54}= 'DendriticType';
     T.Properties.VariableNames{1} = 'ReporterStatus';
     T.Properties.VariableNames{44} = 'Hemisphere';
     
     T.SomaLayerLoc = cellstr(T.SomaLayerLoc);
     T.DendriticType = cellstr(T.DendriticType);
     T.ReporterStatus = cellstr(T.ReporterStatus);
     T.Hemisphere = cellstr(T.Hemisphere);
     
     table = table2nwb(T(idx,[1, 49, 44, 54]));  
     anatomy.dynamictable.set('Anatomical data', table);
     nwb.processing.set('Anatomical data', anatomy);
                           
    %% Getting start date from 1st recording of cell and checking for new session start 
%     date =  h5read(filename, '/session_start_time'); 
%     
%     if length(date) ~= 20
%          date = date(find(date==' ', 1,'first')+1:find(date==' ', 1,'first')+17);
%          nwb.session_start_time = datetime(date, 'InputFormat', ...
%                                     'dd MMM yyyy HH:mm','TimeZone', 'GMT');
%     else
%         nwb.session_start_time =  datetime(date(1:end-1), 'InputFormat', ...
%                                     'yyyy-MM-dd HH:mm:ss','TimeZone', 'UTC');       
%     end       
       nwb.session_start_time = datetime(2018, 1, 21, 2, 30, 3);
   %% Getting run and electrode associated properties  
    device_link = types.untyped.SoftLink(['/general/devices/', device_name]); % lets see if that works
    
    initialRa = h5read(filename, ...
                  '/general/intracellular_ephys/Electrode 1/initial_access_resistance');
              
    initialRa = cell2mat(regexp(initialRa,'\d+\.?\d*','match'));          
    
    ic_elec = types.core.IntracellularElectrode( ...
            'device', device_link, ...
            'description', 'Properties of electrode and run associated to it',...
            'filtering', h5read(filename, ...
                 '/general/intracellular_ephys/Electrode 1/filtering'),...
            'initial_access_resistance', initialRa,...
            'location', h5read(filename, ...
                   '/general/intracellular_ephys/Electrode 1/location')...
               );
     info = h5info(filename);                                                % pull info from file
     icElecPath = info.Groups(4).Groups(2).Groups.Name;
     ic_elec_name = ...
        icElecPath(find(icElecPath=='/', 1,'last')+1:length(icElecPath));
           
     nwb.general_intracellular_ephys.set(ic_elec_name, ic_elec);
     ic_elec_link = types.untyped.SoftLink(['/general/intracellular_ephys/' ic_elec_name]);       
    %% Getting the data

    for s = 1:length(info.Groups(1).Groups(2).Groups)
    
    sweepPath = info.Groups(1).Groups(2).Groups(s).Name; 
    sweepName = sweepPath(...
                     find(sweepPath=='/', 1,'last')+1:length(sweepPath));
  
    stimPath = ['/stimulus/presentation/', sweepName] ;
    
    stimName = h5read(filename,[stimPath,'/aibs_stimulus_name']);
         
    if string(stimName)== "Short Square" || string(stimName)== "Long Square"              
                      
        %% Import Sweeps with potential alignment of sampling rates       
        [nwb, SweepAmp, StimOn, StimOff]  = importSweeps(nwb, ...
                 SweepAmp, StimOn, StimOff, ...
                 alignSamplingMode, SamplingTarget, stimName,...
                 sweepCount, filename, stimPath, sweepPath, sweepName, ...
                    ic_elec_link);  
              
        %% Save sweep info for Sweep table
        sweep_ch2 = types.untyped.ObjectView(['/acquisition/', sweepName]);
        sweep_ch1 = types.untyped.ObjectView(['/stimulus/presentation/', sweepName]);
        sweep_series_objects_ch1 = [sweep_series_objects_ch1, sweep_ch1]; 
        sweep_series_objects_ch2 = [sweep_series_objects_ch2, sweep_ch2];
        
        sweepCount = sweepCount + 1;
       end
   end
  
    
%% Sweep table
           
    sweep_nums_vec = [[0:sweepCount-2],[0:sweepCount-2]];
    
    sweep_nums = types.hdmf_common.VectorData('data', sweep_nums_vec, ...
                                  'description','sweep numbers');                                     
    series_ind = types.hdmf_common.VectorIndex(...
          'data', [0:length(sweep_nums_vec)-1],...                                      % 0-based indices to sweep_series_objects
           'target', types.untyped.ObjectView('/general/intracellular_ephys/sweep_table/series'));
    series_data = types.hdmf_common.VectorData(...
                      'data', [sweep_series_objects_ch1, sweep_series_objects_ch2],...
                      'description', 'Jagged Array of Patch Clamp Series Objects');

    sweepTable = types.core.SweepTable(...
        'colnames', {'series', 'sweep_number'},...
        'description', 'Sweep table for single electrode aquisitions; traces from current injection are reconstructed',...
        'id', types.hdmf_common.ElementIdentifiers('data',  [0:length(sweep_nums_vec)-1]),...
        'series_index', series_ind,...
        'series', series_data,...
        'sweep_number', sweep_nums...
        );
    
    nwb.general_intracellular_ephys_sweep_table = sweepTable;

    nwb.general_intracellular_ephys_sweep_table.vectordata.map(...
        'SweepAmp') = ...
          types.hdmf_common.VectorData(...
           'description', 'amplitdue of the current step injected (if square pulse)',...
           'data', [[SweepAmp]', [SweepAmp]']...
              ); 
          
    nwb.general_intracellular_ephys_sweep_table.vectordata.map(...
        'StimOn') = ...
          types.hdmf_common.VectorData(...
           'description', 'Index of stimulus onset',...
           'data', [[StimOn]', [StimOn]']...
              );   
              
    nwb.general_intracellular_ephys_sweep_table.vectordata.map(...
        'StimOff') = ...
          types.hdmf_common.VectorData(...
           'description', 'Index of end of stimulus',...
           'data', [[StimOff]', [StimOff]']...
              );   

%%    
    filename = fullfile([outputfolder ,nwb.identifier]);
    nwbExport(nwb, filename);
end    