%{
processICsweepsParFor
- analysis of intracellular hyperpolarizing and depolarizing sweeps
%}
clear; tic

mainFolder = 'D:\output_MATNWB\';            % main folder (EDIT HERE)
start = 1;
outDest = 'D:\output_MATNWB\QC\';                                          % general path
cellList = dir([mainFolder,'*.nwb']);                                      % list of cell data files
BwSweepMode = 2;                                                           % NeuroNex = 1, Choline macaque = 2
params = loadParams;                                                       % load parameters to workspace

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

QCcellWide = {};

%% Looping through nwb files
for n = start:length(cellList)                                             % for all cells in directory
    cellID = cellList(n).name(1:length(cellList(n).name)-4);               % cell ID (used for saving data)
    disp(cellID)                                                           % display ID number
    cellFile = nwbRead([mainFolder,cellList(n).name]);                     % load nwb file
   
    %% Initialize processing moduls and new columns for Sweep table 
    initProceModules 
    
    cellFile  = addColumns2SwTabl(cellFile,qc_tags);    
    %% Setting up two QC tables and initializing Variables for counts and temproray storage    
    QC_parameter = table();
    QC_parameter.SweepID = repmat({''},length(cellFile.acquisition.keys),1);
    QC_parameter(:,2:length(qc_tags(2:end))) = array2table(NaN(...
               length(cellFile.acquisition.keys), length(qc_tags)-2));            
    QC_parameter.Properties.VariableNames(2:width(QC_parameter)) = [qc_tags(3:end)];    
    QCpass =  QC_parameter;
    ISIs = {}; SpQC = struct(); spTrain = struct();
    SweepCount = 1;  subCount = 1; supraCount = 1;   
    sagSweep= []; RheoSweep = []; spTrainIDs = {};
    
    %% Looping through sweeps 
    SweepPathsAll = {cellFile.general_intracellular_ephys_sweep_table.series.data.path};
    SweepPathsStim = {SweepPathsAll{find(contains(SweepPathsAll,'stimulus'))}};
    SweepPathsAqui = {SweepPathsAll{find(contains(SweepPathsAll,'acquisition'))}};
   
    for s = 1:length(SweepPathsStim)                      % loop through sweeps        

        CCStimSeries = cellFile.resolve(SweepPathsStim(s));               
        CurrentPath = cell2mat(SweepPathsStim(s));
        CurrentName = CurrentPath(find(CurrentPath=='/',1,'last')+1:length(CurrentPath));        
        
        [QC_parameter.SweepID(SweepCount), QCpass.SweepID(SweepCount)] = ...
          deal({CurrentName});
      
        AquiSwTabIdx = getAquisitionIndex(cellFile, CCStimSeries.sweep_number);
                      
        CCSeries = cellFile.resolve(...
             cellFile.general_intracellular_ephys_sweep_table.series.data(AquiSwTabIdx).path);
         
        if CCStimSeries.data.dims/CCStimSeries.starting_time_rate > 0.25 &&...
            ~contains(CCStimSeries.stimulus_description, 'Ramp') &&...
             ~contains(CCStimSeries.stimulus_description, 'Short') 
                         
            if ~cellFile.general_intracellular_ephys_sweep_table.vectordata.isKey('StimOn')
              [StimOn,StimOff] = GetSquarePulse(CCStimSeries.data);     

              if isempty(StimOn) || StimOff/CCStimSeries.starting_time_rate < 0.1
                 display(['No input current detected in ', char(SweepPathsStim(s))])
    %                    StimOn = CCStimSeries.data.dims/3;
    %                    StimOffset = 2*CCStimSeries.data.dims/3;              
              end    

             [QC_parameter, QCpass] = SweepwiseQC(CCSeries, ...
                                       StimOn, SweepCount,QC_parameter, ...
                                               QCpass, params);

              sweepAmp = mean(CCStimSeries.data.load(StimOn:StimOff));
              cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                    4}.data(AquiSwTabIdx) = sweepAmp;

              if ~isempty(StimOn)
                   cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                    3}.data(AquiSwTabIdx) = StimOn;
                   cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                    2}.data(AquiSwTabIdx) = StimOff;
              end

           else
                StimOn = unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                    3}.data(AquiSwTabIdx));
                StimOff = unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                    2}.data(AquiSwTabIdx));
                sweepAmp = unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                    4}.data(AquiSwTabIdx));
            end           

            [QC_parameter, QCpass]  = SweepwiseQC(CCSeries, StimOn, ...
                                   SweepCount, QC_parameter, QCpass, params);

             if sweepAmp > 0                                                                % if current input > 0

                      [module_spikes, sp, SpQC, QCpass] = ...
                         processSpikes(CCSeries, StimOn, StimOff, params, ...
                                         supraCount, module_spikes, SpQC, ...
                                           QCpass, SweepCount, CurrentName);

                       if ~isempty(sp)
                           [spTrain, ISIs] = estimateAPTrainParams(...
                               sp,StimOn,CCSeries, supraCount, ISIs, spTrain);
                           spTrainIDs(supraCount,1) = {CurrentName};
                       end
                       supraCount = supraCount + 1;

               elseif sweepAmp < 0 
                       module_subStats = subThresFeatures(CCSeries,...
                                              StimOn, StimOff, sweepAmp, ...
                                               CurrentName, module_subStats, ...
                                               params, QC_parameter);
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
   Ri_preqc = inputResistance(cellFile.processing.values{4}.dynamictable);
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
   QCparameterTotal.(['AI_' cellID ]) = QC_parameter;  
   QCpass.bad_spikes(isnan(QCpass.bad_spikes)) = 1; 
   tbl = table2nwb(QC_parameter, 'QC parameter table');  
   module_QC.dynamictable.set('QC_parameter_table', tbl);
   cellFile.processing.set('QC parameter', module_QC);
    
   for t = 5:cellFile.general_intracellular_ephys_sweep_table.vectordata.Count      %loop trhough QC pass columns in sweep table
     key = cellFile.general_intracellular_ephys_sweep_table.vectordata.keys{t};     
     cellFile.general_intracellular_ephys_sweep_table.vectordata.values{t}.data =  ...
       QCpass.(key);                                                                    % fill with the respective value   
   end
   
   for s = 1:height(QCpass)
              
        SweepPos = endsWith(SweepPathsAll,QCpass.SweepID(s));            
        
        if sum(table2array(getRow(...
            cellFile.general_intracellular_ephys_sweep_table,...
              s,'columns', qc_tags(3:end)))) == 11

           cellFile.general_intracellular_ephys_sweep_table.vectordata.values{1}.data(SweepPos) = true; 
        else       
           cellFile.general_intracellular_ephys_sweep_table.vectordata.values{1}.data(SweepPos) = false;       
        end 
   end
   
   temp = varfun(@sum, QCpass(:,2:end));
   QC_removalsPerTag(n,3:end) = num2cell(-(temp{:,:}-height(QCpass)));
   QC_removalsPerTag(n,2) = {sum(...
     cellFile.general_intracellular_ephys_sweep_table.vectordata.values{1}.data(...
       1:length(SweepPathsAqui)))};
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
                plotCellProfile(cellFile, PlotStruct, outDest, params)
                 %SP_summary
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
       plotCellProfile(cellFile, PlotStruct, outDest, params)
       %SP_summary

   end    
   if isnan(ICsummary.thresholdLP(n)) && params.noSupra == 1
         display('     was excluded by cell-wide QC for no suprathreshold data') 
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

%% Cleaning up workspace

clear adaptIndex adaptIndex2 burst BwSweepParameter BwSweepPass c CCSeries ...
    CCStimSeries cell File cellID cvISI data_index data_vector ...
    delay diffV_b_e f holdingI i idx idxPassedSweeps instaRate ...
    instaRateCells ISI ISI_linVec ISI_table ISIs k key ...
    latency loc meanISI moduleISIs module_QC module_spike module_subStats ...
    peakAdapt peakAdapt2 QC_parameter QCpass restVPost restVPre RheoSweep ...
    Ri_preqc rmse_post rmse_post_st rmse_pre rmse_pre_st s sagSweep spTrain ...
    startInt4Peak StimOff StimOn stWin subCount subStats supraCount ...
    sweepAmp SweepCount SweepIDsPassed table ...
    

%% Output summary fiels and figures 

Summary_output_files
% QC_plots
% QC_output_files
toc

