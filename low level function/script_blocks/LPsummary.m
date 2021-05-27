function [cellFile, ICsummary, PlotStruct] = ...
    LPsummary(cellFile, ICsummary, cellNr, params)

%{
summary LP analysis
%}

%% 

SweepPathsAll = {cellFile.general_intracellular_ephys_sweep_table.series.data.path};

if isa(cellFile.general_intracellular_ephys_sweep_table.vectordata.map('QC_total_pass').data, 'double')
    
        IdxPassedSweeps = find(...
            cellFile.general_intracellular_ephys_sweep_table.vectordata.map('QC_total_pass').data);  

        Sweepnames = cellfun(@(a) str2double(a), regexp(SweepPathsAll,'\d*','Match'));

        NamesPassedSweeps = unique(Sweepnames(IdxPassedSweeps));
        IdxPassedSweeps = IdxPassedSweeps(IdxPassedSweeps < ...
            length(cellFile.processing.map('QC parameter').dynamictable.values{1}.vectordata.values{1}.data));

        %% subthreshold summary parameters                              

        ICsummary.resistance(cellNr,1) = inputResistance(...
                 cellFile.processing.map('subthreshold parameters').dynamictable,NamesPassedSweeps);              % resistance based on steady state

        ICsummary.Vrest(cellNr,1) =  nanmean(...
            cellFile.processing.map('QC parameter'...
            ).dynamictable.values{1}.vectordata.map('Vrest').data(IdxPassedSweeps));                            % resting membrane potential

        tau_vec = [];

        for s = 1:cellFile.processing.map('subthreshold parameters').dynamictable.Count
            number = regexp(...
               cellFile.processing.map('subthreshold parameters').dynamictable.keys{s},'\d*','Match');

            if ismember(str2num(cell2mat(number)), NamesPassedSweeps) && ...
                 ~isnan(cellFile.processing.map('subthreshold parameters' ...
                   ).dynamictable.values{s}.vectordata.values{11}.data) && ...
                      cellFile.processing.map('subthreshold parameters' ...
                         ).dynamictable.values{s}.vectordata.values{11}.data

                   tau_vec =  [tau_vec, ...
                       cellFile.processing.map('subthreshold parameters').dynamictable.values{s}.vectordata.values{10}.data];
            end
        end    

        ICsummary.tau(cellNr,1) = mean(tau_vec);

        %% Maximum firing rate and  median instantanous rate

        if cellFile.processing.isKey('All_ISIs') && ...
             ~isempty(cellFile.processing.map('All_ISIs').dynamictable.values{1}.vectorindex.values{1}.data)
          ICsummary.maxFiringRate(cellNr,1) = max(diff(...
              cellFile.processing.map('All_ISIs'...
              ).dynamictable.values{1}.vectorindex.values{1}.data));
          ICsummary.medInstaRate(cellNr,1) = 1000/nanmedian(...
              cellFile.processing.map('All_ISIs'...
              ).dynamictable.values{1}.vectordata.values{1}.data);
        else  
          ICsummary.maxFiringRate(cellNr,1) = 0;
          ICsummary.medInstaRate(cellNr,1) = 0;
        end  

        %% finding sag sweep
        sagSweep = [];
        runs = 1;
        PrefeSagAmps = [-90, -70, -110];
        sagPos = [];
        PlotStruct.SagSweepTablePos = [];

        while isempty(sagSweep) && runs < 4
            for s = 1:cellFile.processing.map('subthreshold parameters').dynamictable.Count 

              number = regexp(cellFile.processing.map('subthreshold parameters' ...
                     ).dynamictable.keys{s},'\d*','Match');

              if ismember(str2num(cell2mat(number)), NamesPassedSweeps) && ...
                   round(cellFile.processing.map('subthreshold parameters'...
                   ).dynamictable.values{s}.vectordata.values{2}.data) == PrefeSagAmps(runs)  
                 sagSweep = cellFile.processing.map('subthreshold parameters').dynamictable.values{s};
                 sagPos = s;
              end    
            end
            if ~isempty(sagPos)
              PlotStruct.SagSweepTablePos = find(strcmp(SweepPathsAll,...
                        ['/acquisition/',cellFile.processing.map(...
                          'subthreshold parameters').dynamictable.keys{sagPos}]));
            end
            runs= runs +1;
        end

        if ~isempty(sagSweep)
            ICsummary.sag(cellNr,1) = sagSweep.vectordata.values{8}.data;
            ICsummary.sag_ratio(cellNr,1) = sagSweep.vectordata.values{9}.data;
            ICsummary.sagAmp(cellNr,1) = sagSweep.vectordata.values{2}.data;
            PlotStruct.sagSweepSeries = cellFile.resolve(SweepPathsAll(PlotStruct.SagSweepTablePos));
        else
            PlotStruct.sagSweepSeries = [];
        end

        %% find rheobase sweeps and parameters of first spike
        RheoSweep = [];            
        PlotStruct.RheoSweepTablePos = [];

        for s = 1:cellFile.processing.map('AP wave').dynamictable.Count            %% loop through all Sweeps with spike data
            number = regexp(...
                cellFile.processing.map('AP wave').dynamictable.keys{s},'\d*','Match');
            if ismember(str2num(cell2mat(number)), NamesPassedSweeps)                  %% if sweep passed the QC

               if (isempty(RheoSweep) && length(cellFile.processing.map('AP wave' ...
                    ).dynamictable.values{s}.vectordata.values{1}.data) ...
                       <= params.maxRheoSpikes) || (~isempty(RheoSweep)  && ...                        %% if the sweep has less 
                       length(cellFile.processing.map('AP wave').dynamictable.values{...
                         s}.vectordata.values{1}.data) < ...
                             length(RheoSweep.vectordata.values{1}.data))                      

                  RheoSweep = cellFile.processing.map('AP wave').dynamictable.values{s};
                  RheoPos = s;
               end
            end
        end    

        if ~isempty(RheoSweep)

            PlotStruct.RheoSweepTablePos = find(endsWith(...
                SweepPathsAll,cellFile.processing.map('AP wave').dynamictable.keys{RheoPos}));

            ICsummary.Rheo(cellNr,1) = ...
                unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                4}.data(PlotStruct.RheoSweepTablePos));

            ICsummary.latency(cellNr,1) = RheoSweep.vectordata.map('thresholdTime').data(1) - ...
                unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{3}.data(PlotStruct.RheoSweepTablePos))...
                *1000/cellFile.resolve(SweepPathsAll(PlotStruct.RheoSweepTablePos( ...
                contains(SweepPathsAll(PlotStruct.RheoSweepTablePos),'acquisition')))).starting_time_rate;

            ICsummary.widthTP_LP(cellNr,1) = RheoSweep.vectordata.map('fullWidthTP').data(1);
            ICsummary.peakLP(cellNr,1) = RheoSweep.vectordata.map('peak').data(1);
            ICsummary.thresholdLP(cellNr,1) = RheoSweep.vectordata.map('fast_trough').data(1);
            ICsummary.fastTroughLP(cellNr,1) = RheoSweep.vectordata.map('threshold').data(1);
            ICsummary.slowTroughLP(cellNr,1) = RheoSweep.vectordata.map('slow_trough').data(1);
            ICsummary.peakUpStrokeLP(cellNr,1) = RheoSweep.vectordata.map('peakUpStroke').data(1);
            ICsummary.peakDownStrokeLP(cellNr,1) = RheoSweep.vectordata.map('peakDownStroke').data(1);
            ICsummary.peakStrokeRatioLP(cellNr,1) = RheoSweep.vectordata.map('peakStrokeRatio').data(1);   
            ICsummary.heightTP(cellNr,1) = RheoSweep.vectordata.map('heightTP').data(1);

            PlotStruct.RheoSweepSeries =  cellFile.resolve(SweepPathsAll(PlotStruct.RheoSweepTablePos(...
                    contains(SweepPathsAll(PlotStruct.RheoSweepTablePos),'acquisition'))));

        else
            PlotStruct.RheoSweepSeries = [];
        end




        %% Hero sweep selection
        HeroSweep = [];            
        PlotStruct.HeroSweepPos = [];
        target = ICsummary.Rheo(cellNr,1)*1.5;
        sweepAmps = cellFile.general_intracellular_ephys_sweep_table.vectordata.values{4 ...
                }.data.load;  
        
           
        while isempty(HeroSweep) && target > ICsummary.Rheo(cellNr,1)
            
            diff2target = min(abs(sweepAmps-target));
            
            [ix , ~] = find(abs(sweepAmps-target)==diff2target);

            PlotStruct.HeroSweepPos = cellFile.general_intracellular_ephys_sweep_table.series_index.data(ix);

            HeroName = str2double(cell2mat(regexp(cell2mat(SweepPathsAll(PlotStruct.HeroSweepPos(...
                        contains(SweepPathsAll(PlotStruct.HeroSweepPos),'acquisition')))),'\d*','Match')));

            PosSpTrain = find(...
                cellFile.processing.map('AP Pattern').dynamictable.values{1}.vectordata.values{1}.data==HeroName);

            if ismember(HeroName, NamesPassedSweeps)  

                      HeroSweep = getRow(cellFile.processing.map('AP Pattern'...
                                    ).dynamictable.values{1}, PosSpTrain);
            else
                if target > 150
                  target = target - 20;
                else
                  target = target + 20;
                end
            end
        end

        if ~isempty(HeroSweep)

            ICsummary.Hero_cv_ISI(cellNr,1) = HeroSweep.cvISI;
            ICsummary.Hero_rate(cellNr,1) = HeroSweep.meanFR1000;
            PlotStruct.HeroSweepSeries = cellFile.resolve(SweepPathsAll(PlotStruct.HeroSweepPos(...
                    contains(SweepPathsAll(PlotStruct.HeroSweepPos),'acquisition'))));
        else
            PlotStruct.HeroSweepSeries = [];
        end
        
else
    
        IdxPassedSweeps = find(...
            cellFile.general_intracellular_ephys_sweep_table.vectordata.map('QC_total_pass').data.load);  

        Sweepnames = cellfun(@(a) str2double(a), regexp(SweepPathsAll,'\d*','Match'));

        NamesPassedSweeps = unique(Sweepnames(IdxPassedSweeps));
        IdxPassedSweeps = IdxPassedSweeps(IdxPassedSweeps < ...
            length(cellFile.processing.map('QC parameter').dynamictable.values{1}.vectordata.values{1}.data));

        %% subthreshold summary parameters                              

        ICsummary.resistance(cellNr,1) = inputResistance(...
                 cellFile.processing.map('subthreshold parameters').dynamictable,NamesPassedSweeps);              % resistance based on steady state

        ICsummary.Vrest(cellNr,1) =  nanmean(...
            cellFile.processing.map('QC parameter'...
            ).dynamictable.values{1}.vectordata.map('Vrest').data.load(IdxPassedSweeps));                            % resting membrane potential

        tau_vec = [];

        for s = 1:cellFile.processing.map('subthreshold parameters').dynamictable.Count
            number = regexp(...
               cellFile.processing.map('subthreshold parameters').dynamictable.keys{s},'\d*','Match');

            if ismember(str2num(cell2mat(number)), NamesPassedSweeps) && ...
                 ~isnan(cellFile.processing.map('subthreshold parameters' ...
                   ).dynamictable.values{s}.vectordata.values{11}.data.load) && ...
                      cellFile.processing.map('subthreshold parameters' ...
                         ).dynamictable.values{s}.vectordata.values{11}.data.load

                   tau_vec =  [tau_vec, ...
                       cellFile.processing.map('subthreshold parameters').dynamictable.values{s}.vectordata.values{10}.data.load];
            end
        end    

        ICsummary.tau(cellNr,1) = mean(tau_vec);

        %% Maximum firing rate and  median instantanous rate

        if cellFile.processing.isKey('All_ISIs') && ...
             ~isempty(cellFile.processing.map('All_ISIs').dynamictable.values{1}.vectorindex.values{1}.data.load)
          ICsummary.maxFiringRate(cellNr,1) = max(diff(...
              cellFile.processing.map('All_ISIs'...
              ).dynamictable.values{1}.vectorindex.values{1}.data.load));
          ICsummary.medInstaRate(cellNr,1) = 1000/nanmedian(...
              cellFile.processing.map('All_ISIs'...
              ).dynamictable.values{1}.vectordata.values{1}.data.load);
        else  
          ICsummary.maxFiringRate(cellNr,1) = 0;
          ICsummary.medInstaRate(cellNr,1) = 0;
        end  

        %% finding sag sweep
        sagSweep = [];
        runs = 1;
        PrefeSagAmps = [-90, -70, -110];
        sagPos = [];
        PlotStruct.SagSweepTablePos = [];

        while isempty(sagSweep) && runs < 4
            for s = 1:cellFile.processing.map('subthreshold parameters').dynamictable.Count 

              number = regexp(cellFile.processing.map('subthreshold parameters' ...
                     ).dynamictable.keys{s},'\d*','Match');

              if ismember(str2num(cell2mat(number)), NamesPassedSweeps) && ...
                   round(cellFile.processing.map('subthreshold parameters'...
                   ).dynamictable.values{s}.vectordata.values{2}.data.load) == PrefeSagAmps(runs)  
                 sagSweep = cellFile.processing.map('subthreshold parameters').dynamictable.values{s};
                 sagPos = s;
              end    
            end
            if ~isempty(sagPos)
              PlotStruct.SagSweepTablePos = find(strcmp(SweepPathsAll,...
                        ['/acquisition/',cellFile.processing.map(...
                          'subthreshold parameters').dynamictable.keys{sagPos}]));
            end
            runs= runs +1;
        end

        if ~isempty(sagSweep)
            ICsummary.sag(cellNr,1) = sagSweep.vectordata.values{8}.data.load;
            ICsummary.sag_ratio(cellNr,1) = sagSweep.vectordata.values{9}.data.load;
            ICsummary.sagAmp(cellNr,1) = sagSweep.vectordata.values{2}.data.load;
            PlotStruct.sagSweepSeries = cellFile.resolve(SweepPathsAll(PlotStruct.SagSweepTablePos));
        else
            PlotStruct.sagSweepSeries = [];
        end

        %% find rheobase sweeps and parameters of first spike
        RheoSweep = [];            
        PlotStruct.RheoSweepTablePos = [];

        for s = 1:cellFile.processing.map('AP wave').dynamictable.Count            %% loop through all Sweeps with spike data
            number = regexp(...
                cellFile.processing.map('AP wave').dynamictable.keys{s},'\d*','Match');
            if ismember(str2num(cell2mat(number)), NamesPassedSweeps)                  %% if sweep passed the QC

               if (isempty(RheoSweep) && length(cellFile.processing.map('AP wave' ...
                    ).dynamictable.values{s}.vectordata.values{1}.data.load) ...
                       <= params.maxRheoSpikes) || (~isempty(RheoSweep)  && ...                        %% if the sweep has less 
                       length(cellFile.processing.map('AP wave').dynamictable.values{...
                         s}.vectordata.values{1}.data) < ...
                             length(RheoSweep.vectordata.values{1}.data.load))                      

                  RheoSweep = cellFile.processing.map('AP wave').dynamictable.values{s};
                  RheoPos = s;
               end
            end
        end    

        if ~isempty(RheoSweep)

            PlotStruct.RheoSweepTablePos = find(endsWith(...
                SweepPathsAll,cellFile.processing.map('AP wave').dynamictable.keys{RheoPos}));

            ICsummary.Rheo(cellNr,1) = ...
                unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                4}.data(PlotStruct.RheoSweepTablePos));

            ICsummary.latency(cellNr,1) = RheoSweep.vectordata.map('thresholdTime').data(1) - ...
                unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{3}.data(PlotStruct.RheoSweepTablePos))...
                *1000/cellFile.resolve(SweepPathsAll(PlotStruct.RheoSweepTablePos( ...
                contains(SweepPathsAll(PlotStruct.RheoSweepTablePos),'acquisition')))).starting_time_rate;

            ICsummary.widthTP_LP(cellNr,1) = RheoSweep.vectordata.map('fullWidthTP').data.load(1);
            ICsummary.peakLP(cellNr,1) = RheoSweep.vectordata.map('peak').data.load(1);
            ICsummary.thresholdLP(cellNr,1) = RheoSweep.vectordata.map('fast_trough').data.load(1);
            ICsummary.fastTroughLP(cellNr,1) = RheoSweep.vectordata.map('threshold').data.load(1);
            ICsummary.slowTroughLP(cellNr,1) = RheoSweep.vectordata.map('slow_trough').data.load(1);
            ICsummary.peakUpStrokeLP(cellNr,1) = RheoSweep.vectordata.map('peakUpStroke').data.load(1);
            ICsummary.peakDownStrokeLP(cellNr,1) = RheoSweep.vectordata.map('peakDownStroke').data.load(1);
            ICsummary.peakStrokeRatioLP(cellNr,1) = RheoSweep.vectordata.map('peakStrokeRatio').data.load(1);   
            ICsummary.heightTP(cellNr,1) = RheoSweep.vectordata.map('heightTP').data.load(1);

            PlotStruct.RheoSweepSeries =  cellFile.resolve(SweepPathsAll(PlotStruct.RheoSweepTablePos(...
                    contains(SweepPathsAll(PlotStruct.RheoSweepTablePos),'acquisition'))));

        else
            PlotStruct.RheoSweepSeries = [];
        end




        %% Hero sweep selection
 
        HeroSweep = [];            
        PlotStruct.HeroSweepPos = [];
        target = ICsummary.Rheo(cellNr,1)*1.5;
        sweepAmps = cellFile.general_intracellular_ephys_sweep_table.vectordata.values{4 ...
                }.data.load;
            
        while isempty(HeroSweep) || diff2target < 40

            diff2target = min(abs(sweepAmps-target));

            [ix , ~] = find(abs(sweepAmps-target)==diff2target);

            PlotStruct.HeroSweepPos = cellFile.general_intracellular_ephys_sweep_table.series_index.data.load(ix);

            HeroName = str2double(cell2mat(regexp(cell2mat(SweepPathsAll(PlotStruct.HeroSweepPos(...
                        contains(SweepPathsAll(PlotStruct.HeroSweepPos),'acquisition')))),'\d*','Match')));

            PosSpTrain = find(...
                cellFile.processing.map('AP Pattern').dynamictable.values{1}.vectordata.values{1}.data.load==HeroName);

            if ismember(HeroName, NamesPassedSweeps)  

                      HeroSweep = getRow(cellFile.processing.map('AP Pattern'...
                                    ).dynamictable.values{1}, PosSpTrain);
            else
                  diff2target = diff2target + 20;
            end
        end

        if ~isempty(HeroSweep)

            ICsummary.Hero_cv_ISI(cellNr,1) = HeroSweep.cvISI;
            ICsummary.Hero_rate(cellNr,1) = HeroSweep.meanFR1000;
            PlotStruct.HeroSweepSeries = cellFile.resolve(SweepPathsAll(PlotStruct.HeroSweepPos(...
                    contains(SweepPathsAll(PlotStruct.HeroSweepPos),'acquisition'))));
        else
            PlotStruct.HeroSweepSeries = [];
        end

end