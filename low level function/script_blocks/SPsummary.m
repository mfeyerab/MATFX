function [cellFile, ICsummary, PlotStruct] = ...
    SPsummary(cellFile, BinSP, ICsummary, cellNr, params, PlotStruct)

SweepPathsAll = {cellFile.general_intracellular_ephys_sweep_table.series.data.path};

if isa(cellFile.general_intracellular_ephys_sweep_table.vectordata.map('QC_total_pass').data, 'double')
    
        IdxPassedSweeps = find(all(...
            [cellFile.general_intracellular_ephys_sweep_table.vectordata.map('QC_total_pass').data, ...
            BinSP'],2));  
        
        Sweepnames = cellfun(@(a) str2double(a), regexp(SweepPathsAll,'\d*','Match'));

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
                SweepPathsAll,cellFile.processing.map('AP wave').dynamictable.keys{RheoPos}));

            ICsummary.CurrentStepSP(cellNr,1) = ...
                nanmean(unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                'SweepAmp').data(PlotStruct.SPSweepTablePos)));

            ICsummary.latencySP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('thresholdTime').data(1) - ...
                nanmean(cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                'StimOn').data(PlotStruct.SPSweepTablePos))*1000/cellFile.resolve(... 
                SweepPathsAll(PlotStruct.SPSweepTablePos( ...
                contains(SweepPathsAll(PlotStruct.SPSweepTablePos),'acquisition')))).starting_time_rate;

            ICsummary.widthTP_SP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('fullWidthTP').data(1);
            ICsummary.peakSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peak').data(1);
            
            ICsummary.thresholdSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('threshold').data(1) ;
            ICsummary.fastTroughSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('fast_trough').data(1);
            ICsummary.slowTroughSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('slow_trough').data(1);
            ICsummary.peakUpStrokeSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peakUpStroke').data(1);
            ICsummary.peakDownStrokeSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peakDownStroke').data(1);
            ICsummary.peakStrokeRatioSP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('peakStrokeRatio').data(1);   
            ICsummary.heightTP_SP(cellNr,1) = PlotStruct.SPSweep.vectordata.map('heightTP').data(1);

            PlotStruct.SPSweepSeries =  cellFile.resolve(SweepPathsAll(PlotStruct.SPSweepTablePos(...
                    contains(SweepPathsAll(PlotStruct.SPSweepTablePos),'acquisition'))));

        else
            PlotStruct.SPSweepTablePos = [];
            PlotStruct.SPSweepSeries = [];
        end
end           
           