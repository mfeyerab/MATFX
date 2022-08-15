function [cellFile, ICsummary, PlotStruct] = ...
    SPsummary(cellFile, ICsummary, cellNr, params, PlotStruct)

SweepResponseTbl = ...
  cellFile.general_intracellular_ephys_intracellular_recordings.responses.response.data.load;

if isa(cellFile.general_intracellular_ephys_intracellular_recordings.dynamictable.map(...
        'quality_control_pass').vectordata.values{1}.data, 'double')
    
<<<<<<< Updated upstream
    if isa(cellFile.general_intracellular_ephys_intracellular_recordings.dynamictable.map(...
            'protocol_type').vectordata.values{1}.data, 'double')
       IdxPassedSweeps = find(all(...
        [cellFile.general_intracellular_ephys_sweep_table.vectordata.map('QC_total_pass').data, ...
        cellFile.general_intracellular_ephys_sweep_table.vectordata.map('BinaryLP').data],2));  
    else
     IdxPassedSweeps = find(all(...
        [cellFile.general_intracellular_ephys_intracellular_recordings.dynamictable.map(...
        'quality_control_pass').vectordata.values{1}.data', ...
        contains(cellstr(cellFile.general_intracellular_ephys_intracellular_recordings.dynamictable.map(...
            'protocol_type').vectordata.values{1}.data.load), params.SPtags)],2));  
=======
    if ~isempty(PS.SPSwpDat.values{1}.data)
      icSum.latencySP(cellNr,1) = PS.SPSwpDat.map('thresTi').data(1) - ...
       (double(IcephysTab.responses.response.data.load_h5_style.idx_start(PS.SPSwpTbPos))*...
            1000/nwb.resolve(SwpRespTbl(PS.SPSwpTbPos).path).starting_time_rate);        

      icSum.CurrentStepSP(cellNr,1) = tempSPstep;
      icSum.widthTP_SP(cellNr,1) = PS.SPSwpDat.map('wiTP').data(1);
      icSum.peakSP(cellNr,1) = PS.SPSwpDat.map('peak').data(1);    
      icSum.thresholdSP(cellNr,1) = PS.SPSwpDat.map('thres').data(1);
      icSum.fastTroughSP(cellNr,1) = PS.SPSwpDat.map('fTrgh').data(1);
      icSum.slowTroughSP(cellNr,1) = PS.SPSwpDat.map('sTrgh').data(1);
      icSum.peakUpStrokeSP(cellNr,1) = PS.SPSwpDat.map('peakUpStrk').data(1); 
      icSum.peakDownStrokeSP(cellNr,1) = PS.SPSwpDat.map('peakDwStrk').data(1);
      icSum.peakStrokeRatioSP(cellNr,1) = PS.SPSwpDat.map('peakStrkRat').data(1);   
      icSum.heightTP_SP(cellNr,1) = PS.SPSwpDat.map('htTP').data(1);     
      PS.SPSwpSers =  nwb.resolve(SwpPaths(PS.SPSwpTbPos(contains(...
                                    SwpPaths(PS.SPSwpTbPos),'acquisition'))));
>>>>>>> Stashed changes
    end

    SweepPaths = {SweepResponseTbl.timeseries.path};
    
    Sweepnames = cellfun(@(a) str2double(a), ...
        cellfun(@(v)v(1),regexp(SweepPaths,'\d*','Match')));        % inner cellfun necessary if sweep name contains mutliple numbers for example an extra AD01 

    NamesPassedSweeps = Sweepnames(IdxPassedSweeps);  
    
    
       %% find rheobase sweeps and parameters of first spike
        PlotStruct.SPSweepTablePos = [];
        PlotStruct.SPSweep = [];
        
        for s = 1:cellFile.processing.map('AP wave').dynamictable.Count            %% loop through all Sweeps with spike data
            number = regexp(...
                cellFile.processing.map('AP wave').dynamictable.keys{s},'\d*','Match');
            if ismember(str2num(cell2mat(number)), NamesPassedSweeps)                  %% if sweep passed the QC

               if (isempty(PlotStruct.SPSweep) && length(cellFile.processing.map('AP wave' ...
                    ).dynamictable.values{s}.vectordata.values{1}.data) ...
                       <= params.maxRheoSpikes) || (~isempty(PlotStruct.SPSweep)  && ...                        %% if the sweep has less 
                       length(cellFile.processing.map('AP wave').dynamictable.values{...
                         s}.vectordata.values{1}.data) < ...
                             length(PlotStruct.SPSweep.vectordata.values{1}.data))                      

                  PlotStruct.SPSweep = cellFile.processing.map('AP wave').dynamictable.values{s};
                  RheoPos = s;
               end
            end
        end    

        if ~isempty(PlotStruct.SPSweep)

            PlotStruct.SPSweepTablePos = find(endsWith(...
                SweepPaths,cellFile.processing.map('AP wave').dynamictable.keys{RheoPos}));

            ICsummary.CurrentStepSP(cellNr,1) = ...
                  cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data(PlotStruct.SPSweepTablePos);

            ICsummary.latencySP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('thresholdTime').data(1) - ...
                table2array(SweepResponseTbl(PlotStruct.SPSweepTablePos,1))*1000/cellFile.resolve(...
                SweepPaths(PlotStruct.SPSweepTablePos( ...
                contains(SweepPaths(PlotStruct.SPSweepTablePos),'acquisition')))).starting_time_rate;        

            ICsummary.latencySP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('thresholdTime').data(1) - ...
                table2array(SweepResponseTbl(PlotStruct.SPSweepTablePos,1))*1000/cellFile.resolve(...
               SweepPaths(PlotStruct.SPSweepTablePos(contains(...
               SweepPaths(PlotStruct.SPSweepTablePos),'acquisition')))).starting_time_rate;

            
            ICsummary.widthTP_SP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('fullWidthTP').data(1);
            ICsummary.peakSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peak').data(1);
            
            ICsummary.thresholdSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('threshold').data(1) ;
            ICsummary.fastTroughSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('fast_trough').data(1);
            ICsummary.slowTroughSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('slow_trough').data(1);
            ICsummary.peakUpStrokeSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peakUpStroke').data(1);
            ICsummary.peakDownStrokeSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peakDownStroke').data(1);
            ICsummary.peakStrokeRatioSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peakStrokeRatio').data(1);   
            ICsummary.heightTP_SP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('heightTP').data(1);

            PlotStruct.SPSweepSeries =  cellFile.resolve(SweepPaths(PlotStruct.SPSweepTablePos(...
                    contains(SweepPaths(PlotStruct.SPSweepTablePos),'acquisition'))));

        else
            PlotStruct.SPSweepTablePos = [];
            PlotStruct.SPSweepSeries = [];
        end
else
        IdxPassedSweeps = find(all(...
         [cellFile.general_intracellular_ephys_sweep_table.vectordata.map('QC_total_pass').data.load, ...
          cellFile.general_intracellular_ephys_sweep_table.vectordata.map('BinarySP').data.load],2));  
        
        Sweepnames = cellfun(@(a) str2double(a), regexp(SweepPaths,'\d*','Match'));

        NamesPassedSweeps = unique(Sweepnames(IdxPassedSweeps));
        IdxPassedSweeps = IdxPassedSweeps(1:length(NamesPassedSweeps));    
    
    
       %% find rheobase sweeps and parameters of first spike
        PlotStruct.SPSweepTablePos = [];
        PlotStruct.SPSweep = [];
        
        for s = 1:cellFile.processing.map('AP wave').dynamictable.Count            %% loop through all Sweeps with spike data
            number = regexp(...
                cellFile.processing.map('AP wave').dynamictable.keys{s},'\d*','Match');
            if ismember(str2num(cell2mat(number)), NamesPassedSweeps)                  %% if sweep passed the QC

               if (isempty(PlotStruct.SPSweep) && length(cellFile.processing.map('AP wave' ...
                    ).dynamictable.values{s}.vectordata.values{1}.data.load) ...
                       <= params.maxRheoSpikes) || (~isempty(PlotStruct.SPSweep)  && ...                        %% if the sweep has less 
                       length(cellFile.processing.map('AP wave').dynamictable.values{...
                         s}.vectordata.values{1}.data.load) < ...
                             length(PlotStruct.SPSweep.vectordata.values{1}.data.load))                      

                  PlotStruct.SPSweep = cellFile.processing.map('AP wave').dynamictable.values{s};
                  RheoPos = s;
               end
            end
        end    

        if ~isempty(PlotStruct.SPSweep)

            PlotStruct.SPSweepTablePos = find(endsWith(...
                SweepPaths,cellFile.processing.map('AP wave').dynamictable.keys{RheoPos}));

            ICsummary.CurrentStepSP(cellNr,1) = ...
                nanmean(unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                'SweepAmp').data.load(PlotStruct.SPSweepTablePos)));

            ICsummary.latencySP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('thresholdTime').data(1) - ...
                nanmean(cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                'StimOn').data.load(PlotStruct.SPSweepTablePos))*1000/cellFile.resolve(... 
                SweepPaths(PlotStruct.SPSweepTablePos( ...
                contains(SweepPaths(PlotStruct.SPSweepTablePos),'acquisition')))).starting_time_rate;

            ICsummary.widthTP_SP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('fullWidthTP').data.load(1);
            ICsummary.peakSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peak').data.load(1);
            
            ICsummary.thresholdSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('threshold').data.load(1) ;
            ICsummary.fastTroughSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('fast_trough').data.load(1);
            ICsummary.slowTroughSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('slow_trough').data.load(1);
            ICsummary.peakUpStrokeSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peakUpStroke').data.load(1);
            ICsummary.peakDownStrokeSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peakDownStroke').data.load(1);
            ICsummary.peakStrokeRatioSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peakStrokeRatio').data.load(1);   
            ICsummary.heightTP_SP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('heightTP').data.load(1);

            PlotStruct.SPSweepSeries =  cellFile.resolve(SweepPaths(PlotStruct.SPSweepTablePos(...
                    contains(SweepPaths(PlotStruct.SPSweepTablePos),'acquisition'))));

        else
            PlotStruct.SPSweepTablePos = [];
            PlotStruct.SPSweepSeries = [];
        end
end
           