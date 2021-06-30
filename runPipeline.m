function ICsummary = runPipeline(varargin) %{

%{ 
Runs analysis pipeline on all nwb file in the path indicated as first input argument.
Second input argument is the path at which nwb files with additional processing moduls are saved. 
If only one input argument is used nwb files will be overwritten.
In addition there are two different modes of between Sweep QC: Mode 1, in
which the cell has a target membrane potential which is the average of the
prestimulus membrane potential of the first three sweeps. And Mode 2, in
which there is no set membrane potential and the between sweep QC is assessed 
by deviations from the grand average. To set the between sweep mode also add
a 1 or 2 as input argument.
%}

check1 = 0;
check2 = 0;
for v = 1:nargin
    if check1 == 0 && (isa(varargin{v}, 'char') || isa(varargin{v}, 'string'))
        mainFolder = varargin{v};
        check1 = 1;
    elseif (isa(varargin{v}, 'char') || isa(varargin{v}, 'string'))
        outDest = varargin{v};
        disp('No overwrite mode')
    elseif isa(varargin{v}, 'double') 
        BwSweepMode = varargin{v};    
        check2 = 1;
        if BwSweepMode == 1
            disp('between sweep QC with a set target value')
        elseif BwSweepMode == 2
            disp('between sweep QC without a set target value')
        else
            error('Please use 1 or 2 as input for respective between sweep mode ')
        end
    end
    if check2 == 0
        error('No number inputed for between sweep QC')
    end
end
cellList = dir([mainFolder,'*.nwb']);                                      % list of cell data files
params = loadParams;                                                       % load parameters to workspace
tic
%% Set to overwrite or delete nwb files from output folder 

overwrite = 0;
if length(mainFolder) == length(outDest) && mainFolder == outDest
    overwrite = 1;
else    
    for k = 1 : length(cellList)
      baseFileName = cellList(k).name;
      fullFileName = fullfile(outDest, baseFileName);
      fprintf(1, 'Now deleting %s\n', fullFileName);
      delete(fullFileName);
    end
    clear fullFileName baseFileName
end    

%% Initialize feature and QC summary tables

ICsummary = initICSummary(cellList); 

qc_tags = {'SweepsTotal' 'QC_total_pass' 'stRMSE_pre' 'stRMSE_post' ...
        'ltRMSE_pre' 'ltRMSE_post' 'diffVrest' ...
        'Vrest'  'holdingI' 'betweenSweep' ...
        'bridge_balance_abs' 'bridge_balance_rela' 'bad_spikes' ...
         };
     
QC_removalsPerTag = array2table(NaN(length(cellList),length(qc_tags)), ...
    'VariableNames', qc_tags,'RowNames', {cellList.name});

QCparameterTotal = struct();
QCpassTotal = struct();

QCcellWide = {};

%% Looping through nwb files
for n = 1:length(cellList)                                             % for all cells in directory
    cellFile = nwbRead([mainFolder,cellList(n).name]);                     % load nwb file    
    cellID = cellList(n).name(1:length(cellList(n).name)-4);               % cell ID (used for saving data)   
    
    if ~isempty(cellFile.general_experiment_description) &&...
            contains(cellFile.general_experiment_description,'PatchMaster')
      cellID =  cellID(1:31);
      cellID(cellID=='-') = '_';
      cellFile.identifier = cellID;
    end
    
    disp(cellID)                                                           % display ID number
    %% Initialize processing moduls and new columns for Sweep table 
    initProceModules 
    
    cellFile  = addColumns2SwTabl(cellFile,qc_tags);    
    %% Setting up two QC tables and initializing Variables for counts and temproray storage    
    QC_parameter = table();
    QC_parameter.SweepID = repmat({''},length(cellFile.acquisition.keys),1);
    QC_parameter.Protocol = repmat({''},length(cellFile.acquisition.keys),1);
    QC_parameter(:,3:length(qc_tags(2:end))+1) = array2table(NaN(...
               length(cellFile.acquisition.keys), length(qc_tags)-2));  
    QC_parameter.Properties.VariableNames(3:width(QC_parameter)) = [qc_tags(3:end)];  
    QCpass = QC_parameter;     
    ISIs = {}; SpQC = struct(); spTrain = struct();
    SweepCount = 1;  subCount = 1; supraCount = 1;   
    sagSweep= []; RheoSweep = []; spTrainIDs = {};
    %% Looping through sweeps 
    SweepPathsAll = {cellFile.general_intracellular_ephys_sweep_table.series.data.path};
    SweepPathsStim = {SweepPathsAll{find(contains(SweepPathsAll,'stimulus'))}};
    SweepPathsAqui = {SweepPathsAll{find(contains(SweepPathsAll,'acquisition'))}};
   
    for s = 1:length(SweepPathsStim)                      % loop through sweeps        

        CCStimSeries = cellFile.resolve(SweepPathsStim(s)); 
        
        if ~contains(CCStimSeries.stimulus_description, 'Ramp') 
        
        CurrentStimPath = cell2mat(SweepPathsStim(s));
        CurrentStimName = CurrentStimPath(find(CurrentStimPath=='/',1,'last')+1:length(CurrentStimPath));        
              
        [AquiSwTabIdx, SwTabIdxAll] = getAquisitionIndex(cellFile, CCStimSeries.sweep_number);
        
        CurrentPath = cellFile.general_intracellular_ephys_sweep_table.series.data(AquiSwTabIdx).path;
        CurrentName = CurrentPath(find(CurrentPath=='/',1,'last')+1:length(CurrentPath));
                
        [QC_parameter.SweepID(SweepCount), QCpass.SweepID(SweepCount)] = ...
          deal({CurrentName});
        
        CCSeries = cellFile.resolve(CurrentPath);
         
        %% if there are no information on stimulus structure in sweep table
        if isnan(cellFile.general_intracellular_ephys_sweep_table.vectordata.map('StimOn').data(AquiSwTabIdx))
            [StimOn,StimOff] = GetSquarePulse(CCStimSeries);     
            if isempty(StimOn) || isnan(StimOn)
                  A=(cellFile.general_intracellular_ephys_sweep_table.vectordata.map('StimOn'...
                      ).data(~isnan(cellFile.general_intracellular_ephys_sweep_table.vectordata.map('StimOn').data)));
                 StimOn = A(length(A));
                 A=(cellFile.general_intracellular_ephys_sweep_table.vectordata.map('StimOff'...
                      ).data(~isnan(cellFile.general_intracellular_ephys_sweep_table.vectordata.map('StimOff').data)));
                 StimOff = A(length(A));
                 disp(['No input current detected in ', char(SweepPathsStim(s)),...
                     ' taking StimOn: ', num2str(StimOn),' and StimOff: ', num2str(StimOff),...
                     ' from last available sweep']);
            end 
        
            sweepAmp = round(mean(CCStimSeries.data.load(StimOn:StimOff)),-1);            
            cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
                'SweepAmp'))}.data(SwTabIdxAll) = sweepAmp;
            cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
                'StimOn'))}.data(SwTabIdxAll) = StimOn;
            cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
                'StimOff'))}.data(SwTabIdxAll) = StimOff;
            StimLength = StimOff-StimOn;
            cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
                'StimLength'))}.data(SwTabIdxAll) = StimLength;
        else
         StimOn = unique(...
            cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
            'StimOn').data.load(SwTabIdxAll));
         StimOff = unique(...
            cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
            'StimOff').data.load(SwTabIdxAll));
         sweepAmp = unique(...
            cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
            'SweepAmp').data.load(SwTabIdxAll));     
         StimLength = unique(...
            cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
            'StimLength').data.load(SwTabIdxAll));
        end           

        %% Determining Stimulus Protocol and saving it
        if ~cellFile.general_intracellular_ephys_sweep_table.vectordata.isKey('BinaryLP')
            if round(StimLength) == round(CCSeries.starting_time_rate) 
                QC_parameter.Protocol(SweepCount) = {'LP'};
                QCpass.Protocol(SweepCount) = {'LP'};
                cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                    find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
                    'BinaryLP'))}.data(SwTabIdxAll) = 1;
                cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                    find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
                    'BinarySP'))}.data(SwTabIdxAll) = 0;
             elseif StimLength == round(CCSeries.starting_time_rate*0.003)
                QC_parameter.Protocol(SweepCount) = {'SP'};
                QCpass.Protocol(SweepCount) = {'SP'};
                cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                    find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
                    'BinarySP'))}.data(SwTabIdxAll) = 1;
                cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                    find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
                    'BinaryLP'))}.data(SwTabIdxAll) = 0;
             else
                 disp(['Unknown stimulus type with duration of '...
                            , num2str(StimLength/CCSeries.starting_time_rate), ' s'])
            end
        else
            if cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                    'BinaryLP').data.load(SweepCount)
                QC_parameter.Protocol(SweepCount) = {'LP'};
                QCpass.Protocol(SweepCount) = {'LP'};
            elseif cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                    'BinarySP').data.load(SweepCount)
                QC_parameter.Protocol(SweepCount) = {'SP'};
                QCpass.Protocol(SweepCount) = {'SP'};
            end
        end
            %% Analysis
            [QC_parameter, QCpass]  = SweepwiseQC(CCSeries, StimOn, StimOff, ...
                                   SweepCount, QC_parameter, QCpass, params);

             if sweepAmp > 0                                                                % if current input > 0

                      [module_spikes, sp, SpQC, QCpass] = ...
                         processSpikes(CCSeries, StimOn, StimOff, params, ...
                                         supraCount, module_spikes, SpQC, ...
                                           QCpass, SweepCount, CurrentName);

                       if ~isempty(sp) && length(sp.peak) > 1
                           [spTrain, ISIs] = estimateAPTrainParams(...
                               sp,StimOn,CCSeries, supraCount, ISIs, spTrain);
                           spTrainIDs(supraCount,1) = {CurrentName};
                       end
                       supraCount = supraCount + 1;

               elseif sweepAmp < 0 
                       module_subStats = subThresFeatures(CCSeries,...
                                              StimOn, StimOff, sweepAmp, ...
                                               CurrentName, module_subStats, ...
                                               params);
                       subCount = subCount +1;
               end
               SweepCount = SweepCount + 1;    
        end
    end
   %% save AP wave and subthreshold parameters
   module_spTrain = makeSpTrainModule(spTrain, spTrainIDs); 
   cellFile.processing.set('AP Pattern', module_spTrain); 
   cellFile.processing.set('subthreshold parameters', module_subStats);
   cellFile.processing.set('AP wave', module_spikes);

   %% QC bridge balance relative to input resistance
   Ri_preqc = inputResistance(...
       cellFile.processing.get('subthreshold parameters').dynamictable);
   QCpass.bridge_balance_rela = ...
       QC_parameter.bridge_balance_rela < Ri_preqc*params.factorRelaRa;
   
   %% Between Sweep QC
   [BwSweepPass, BwSweepParameter] = BetweenSweepQC(...
                                        QC_parameter, BwSweepMode, params);
   QCpass.betweenSweep = BwSweepPass;
   QC_parameter.betweenSweep = BwSweepParameter;
   
   %% save SpikeQC in ragged array    
   [data_vector, data_index] = create_indexed_column(ISIs, 'path');
   ISI_table = types.hdmf_common.DynamicTable(...
                    'colnames', 'ISIs',...
                    'description', 'ISI table',...
                    'id', types.hdmf_common.ElementIdentifiers('data', ...
                                           [0:length(data_vector.data)]) ,...
                    'ISIs', types.hdmf_common.VectorData(...
                                            'data', data_vector.data,...
                                            'description', 'Interspike Intervals'...
                                        ),...
                    'ISIs_index', types.hdmf_common.VectorIndex(...
                                            'data', data_index.data,...
                                            'target', types.untyped.ObjectView(...
                                              '/processing/All_ISIs/ISI_table/ISIs')...
                                                  )...
                                                    );
   module_ISIs.dynamictable.set('ISI_table', ISI_table);      
   cellFile.processing.set('All_ISIs', module_ISIs); 
      
   %% Save QC results in Sweeptable and external 
   
   QC_parameter = rmmissing(QC_parameter);
   QCpass = rmmissing(QCpass,'MinNumMissing',2);

   QCparameterTotal.(['ID_' cellID ]) = QC_parameter;  
   QCpassTotal.(['ID_' cellID ]) = QCpass;  
   QCpass.bad_spikes(isnan(QCpass.bad_spikes)) = 1; 
   tbl = table2nwb(QC_parameter, 'QC parameter table');  
   module_QC.dynamictable.set('QC_parameter_table', tbl);
   cellFile.processing.set('QC parameter', module_QC);
    
   for t = 8:cellFile.general_intracellular_ephys_sweep_table.vectordata.Count      %loop trhough QC pass columns in sweep table CHANGED
     key = cellFile.general_intracellular_ephys_sweep_table.vectordata.keys{t};     
     cellFile.general_intracellular_ephys_sweep_table.vectordata.values{t}.data =  ...
       QCpass.(key);                                                                    % fill with the respective value   
   end
   
   for s = 1:height(QCpass)
              
        SweepPos = find(endsWith(SweepPathsAll,QCpass.SweepID(s)));            
        
        if sum(table2array(getRow(cellFile.general_intracellular_ephys_sweep_table,...
              s,'columns', qc_tags(3:end)))) == 11

           cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
               3}.data(SweepPos) = true; 
        else       
           cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
               3}.data(SweepPos) = false;       
        end 
   end
   
   temp = varfun(@sum, QCpass(:,3:end));
   QC_removalsPerTag(n,3:end) = num2cell(-(temp{:,:}-height(QCpass)));
   QC_removalsPerTag(n,2) = {sum(...
     cellFile.general_intracellular_ephys_sweep_table.vectordata.values{1}.data(...
       1:length(SweepPathsAqui)), 'omitnan')};
   QC_removalsPerTag(n,1) = {height(QCpass)};
   
   %% save ISIs in ragged array  
   [data_vector, data_index] = create_indexed_column(ISIs, 'path');
   ISI_table = types.hdmf_common.DynamicTable(...
                    'colnames', 'ISIs',...
                    'description', 'ISI table',...
                    'id', types.hdmf_common.ElementIdentifiers('data', ...
                                           [0:length(data_vector.data)]) ,...
                    'ISIs', types.hdmf_common.VectorData(...
                                            'data', data_vector.data,...
                                            'description', 'Interspike Intervals'...
                                        ),...
                    'ISIs_index', types.hdmf_common.VectorIndex(...
                                            'data', data_index.data,...
                                            'target', types.untyped.ObjectView(...
                                              '/processing/All_ISIs/ISI_table/ISIs')...
                                                  )...
                                                    );
   module_ISIs.dynamictable.set('ISI_table', ISI_table);      
   cellFile.processing.set('All_ISIs', module_ISIs); 
   
   %% Feature Extraction and Summary
   if  ~isempty(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) && ...
           (string(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ~= "NaN" && ...
               string(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ~= ...
                   "has to be entered manually")
      
       if str2double(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ...
                 <= params.cutoffInitRa 
           if  str2double(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ...
                 <= Ri_preqc*params.factorRelaRa
                [cellFile, ICsummary, PlotStruct] = ...
                            LPsummary(cellFile, ICsummary, n, params);
                [cellFile, ICsummary, PlotStruct] = ...
                            SPsummary(cellFile, ICsummary, n, params, PlotStruct);
                plotCellProfile(cellFile, PlotStruct, outDest, params)
           else
              display(['    was excluded by cell-wide QC for Ra higher than ', ...
                  num2str(Ri_preqc*params.factorRelaRa)]);
                  QCcellWide{end+1} = cellID;
           end
       else
              display(['    was excluded by cell-wide QC for Ra higher than ', ...
                  num2str(params.cutoffInitRa )])
                  QCcellWide{end+1} = cellID;
      end              
   else
       [cellFile, ICsummary, PlotStruct] = ...
                            LPsummary(cellFile, ICsummary, n, params);
       [cellFile, ICsummary, PlotStruct] = ...
                            SPsummary(cellFile, ICsummary, n, params, PlotStruct);
       plotCellProfile(cellFile, PlotStruct, outDest, params)
   end    
   if isnan(ICsummary.thresholdLP(n)) && params.noSupra == 1
         disp('     was excluded by cell-wide QC for no suprathreshold data') 
         ICsummary(n,1:7) = {NaN};
         QCcellWide{end+1} = cellID;
   end
  
   %% Add subject data, dendritic type and reporter status   
   if ~isempty(cellFile.processing.values{4}.dynamictable.values{1}.vectordata.values{1}.data)     
    ICsummary.dendriticType(n) = ...
       {cellFile.processing.values{4}.dynamictable.values{1}.vectordata.values{1}.data.load};
    ICsummary.SomaLayerLoc(n) = ...
       {cellFile.processing.values{4}.dynamictable.values{1}.vectordata.map('SomaLayerLoc').data.load};
    ICsummary.Weight(n) = {cellFile.general_subject.weight};
    ICsummary.Sex(n) = {cellFile.general_subject.sex};
    ICsummary.Age(n) = {cellFile.general_subject.age};  
    
    if ~isempty(cellFile.general_intracellular_ephys.values{1}.slice)
        temperature = regexp(...
        cellFile.general_intracellular_ephys.values{1}.slice, '(\d+,)*\d+(\.\d*)?', 'match');
        if isempty(temperature)
           ICsummary.Temperature(n) = NaN;
        else
            ICsummary.Temperature(n) = str2num(cell2mat(temperature));
        end
    end
    
    if string(cellFile.general_institution) == "Allen Institute of Brain Science" 
      ICsummary.brainOrigin(n) = {cellFile.general_intracellular_ephys.values{1}.location(...
          1:find(cellFile.general_intracellular_ephys.values{1}.location==',')-1)};
    else
      ICsummary.brainOrigin(n) = {cellFile.general_intracellular_ephys.values{1}.location};
    end
    
    if string(cellFile.general_subject.species) == "Mus musculus" && ...
        string(cellFile.processing.values{4}.dynamictable.values{1}.vectordata.values{3}.data.load) == "positive"

       ICsummary.ReporterTag(n) = {cellFile.general_subject.genotype};
    else
       ICsummary.ReporterTag(n) = {'None'} ;
    end       
   end
   ICsummary.species(n) = {cellFile.general_subject.species};
   %% Export
   if overwrite == 1
      delete(fullfile(outDest, cellList(n).name)) 
   end    
   nwbExport(cellFile, fullfile(outDest, cellList(n).name));
end                                                                        % end cell level for loop

%% Output summary fiels and figures 

Summary_output_files
% QC_plots
toc

