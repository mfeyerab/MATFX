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
        IdxPassedSweeps = IdxPassedSweeps(1:length(NamesPassedSweeps));

        %% subthreshold summary parameters                              

        [ICsummary.resistanceHD(cellNr,1), ICsummary.resistanceOffset(cellNr,1)] = ...
            inputResistance(cellFile.processing.map('subthreshold parameters').dynamictable,NamesPassedSweeps);              % resistance based on steady state
        
        ICsummary.resistanceSS(cellNr,1) = inputResistanceSS(...
                 cellFile.processing.map('subthreshold parameters').dynamictable,NamesPassedSweeps);   
             
        ICsummary.rectification(cellNr,1) = rectification(...
            cellFile.processing.map('subthreshold parameters').dynamictable,NamesPassedSweeps);
        
             if ~isempty(cellFile.processing.map('QC parameter'...
                     ).dynamictable.values{1}.vectordata.map('SweepID').data)
                 
                    QCTableIdx = find(ismember(regexp(cell2mat(...
                                cellFile.processing.map('QC parameter'...
                         ).dynamictable.values{1}.vectordata.map('SweepID').data),...
                         '\d*','Match'), cellstr(string(NamesPassedSweeps))));  

                    ICsummary.Vrest(cellNr,1) = nanmean(...
                        cellFile.processing.map('QC parameter'...
                        ).dynamictable.values{1}.vectordata.map('Vrest').data(QCTableIdx));                            % resting membrane potential
             else
                 ICsummary.Vrest(cellNr,1) = NaN;
             end
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
        tau_vec = sort(tau_vec);
        if length(tau_vec) < 3 && ~isempty(tau_vec)
            ICsummary.tau(cellNr,1) = mean(tau_vec(length(tau_vec)));
        elseif ~isempty(tau_vec)
           ICsummary.tau(cellNr,1) = mean(tau_vec(1:3));
        else
           ICsummary.tau(cellNr,1) = NaN;
        end
        %% Maximum firing rate and  median instantanous rate

        if cellFile.processing.isKey('All_ISIs') && ...
             ~isempty(cellFile.processing.map('All_ISIs').dynamictable.values{1}.vectorindex.values{1}.data)
          
           TrueISIs = cellFile.processing.map('All_ISIs'...
             ).dynamictable.values{1}.vectorindex.values{1}.data(~isnan(...
             cellFile.processing.map('All_ISIs').dynamictable.values{1 ...
                                        }.vectordata.values{1}.data));
        
           ICsummary.medInstaRate(cellNr,1) = 1000/nanmedian(...
                  cellFile.processing.map('All_ISIs'...
                  ).dynamictable.values{1}.vectordata.values{1}.data);                            
                                   
             if length(TrueISIs) == 1
                 ICsummary.maxFiringRate(cellNr,1) = 2;
             else
                 ICsummary.maxFiringRate(cellNr,1) = max(diff(TrueISIs));
             end
        else  
          ICsummary.maxFiringRate(cellNr,1) = 0;
          ICsummary.medInstaRate(cellNr,1) = 0;
        end  

        %% finding sag sweep
        runs = 1;
        sagSweep = []; sagPos = [];
        PrefeSagAmps = [-90, -70, -110, -50];
        PlotStruct.SagSweepTablePos = [];

        while isempty(sagSweep) && runs < 5
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
            ICsummary.sagAmp(cellNr,1) = sagSweep.vectordata.values{2}.data;
            ICsummary.sag(cellNr,1) = sagSweep.vectordata.values{8}.data;
            ICsummary.sag_ratio(cellNr,1) = sagSweep.vectordata.values{9}.data;    
            QCIdx = find(strcmp(cellFile.processing.map(...
                'QC parameter').dynamictable.values{1}.vectordata.values{1}.data, ...
                         cellFile.processing.map(...
                          'subthreshold parameters').dynamictable.keys{sagPos}));
            
            ICsummary.sagVrest(cellNr,1) = ...
                 cellFile.processing.map('QC parameter'...
                 ).dynamictable.values{1}.vectordata.map('Vrest').data(QCIdx);
             
            PlotStruct.sagSweepSeries = cellFile.resolve(SweepPathsAll(PlotStruct.SagSweepTablePos));
        else
            PlotStruct.sagSweepSeries = [];
        end

        %% find rheobase sweeps and parameters of first spike
        PlotStruct.RheoSweepTablePos = [];
        PlotStruct.RheoSweep = [];
        
        for s = 1:cellFile.processing.map('AP wave').dynamictable.Count            %% loop through all Sweeps with spike data
            number = regexp(...
                cellFile.processing.map('AP wave').dynamictable.keys{s},'\d*','Match');
            if ismember(str2num(cell2mat(number)), NamesPassedSweeps)                  %% if sweep passed the QC

               if (isempty(PlotStruct.RheoSweep) && length(cellFile.processing.map('AP wave' ...
                    ).dynamictable.values{s}.vectordata.values{1}.data) ...
                       <= params.maxRheoSpikes) || (~isempty(PlotStruct.RheoSweep)  && ...                        %% if the sweep has less 
                       length(cellFile.processing.map('AP wave').dynamictable.values{...
                         s}.vectordata.values{1}.data) < ...
                             length(PlotStruct.RheoSweep.vectordata.values{1}.data))                      

                  PlotStruct.RheoSweep = cellFile.processing.map('AP wave').dynamictable.values{s};
                  RheoPos = s;
               end
            end
        end    

        if ~isempty(PlotStruct.RheoSweep)

            PlotStruct.RheoSweepTablePos = find(endsWith(...
                SweepPathsAll,cellFile.processing.map('AP wave').dynamictable.keys{RheoPos}));

            ICsummary.Rheo(cellNr,1) = ...
                unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
                4}.data(PlotStruct.RheoSweepTablePos));

            ICsummary.latency(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('thresholdTime').data(1) - ...
                unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{3}.data(PlotStruct.RheoSweepTablePos))...
                *1000/cellFile.resolve(SweepPathsAll(PlotStruct.RheoSweepTablePos( ...
                contains(SweepPathsAll(PlotStruct.RheoSweepTablePos),'acquisition')))).starting_time_rate;

            ICsummary.widthTP_LP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('fullWidthTP').data(1);
            ICsummary.peakLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('peak').data(1);
            
            ICsummary.thresholdLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('threshold').data(1) ;
            ICsummary.fastTroughLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('fast_trough').data(1);
            ICsummary.slowTroughLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('slow_trough').data(1);
            ICsummary.peakUpStrokeLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('peakUpStroke').data(1);
            ICsummary.peakDownStrokeLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('peakDownStroke').data(1);
            ICsummary.peakStrokeRatioLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('peakStrokeRatio').data(1);   
            ICsummary.heightTP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('heightTP').data(1);

            PlotStruct.RheoSweepSeries =  cellFile.resolve(SweepPathsAll(PlotStruct.RheoSweepTablePos(...
                    contains(SweepPathsAll(PlotStruct.RheoSweepTablePos),'acquisition'))));

        else
            PlotStruct.RheoSweepSeries = [];
        end




        %% Hero sweep selection
        HeroSweep = [];            
        PlotStruct.HeroSweepPos = [];
        diff2target = [];
        if ~isnan(ICsummary.Rheo(cellNr,1))
            target = ICsummary.Rheo(cellNr,1)*1.5;
            sweepAmps = cellFile.general_intracellular_ephys_sweep_table.vectordata.values{4 ...
                    }.data.load;  

            if max(sweepAmps(IdxPassedSweeps)) < target
                target = max(sweepAmps(IdxPassedSweeps));
            end

            while isempty(HeroSweep) && all(target <= max(sweepAmps(IdxPassedSweeps))) && ...
                    length(diff2target) < 100000

                target = target(~(target < ICsummary.Rheo(cellNr,1)));

                diff2target = min(abs(sweepAmps-target));

                [PlotStruct.HeroSweepPos , ~] = find(any(abs(sweepAmps-target)==diff2target,2));

                HeroName = str2double(regexp(cell2mat(SweepPathsAll(PlotStruct.HeroSweepPos(...
                            contains(SweepPathsAll(PlotStruct.HeroSweepPos),'acquisition')))),'\d*','Match'));

                for h = 1:length(HeroName)        
                    PosSpTrain = find(cellFile.processing.map('AP Pattern'...
                        ).dynamictable.values{1}.vectordata.values{1}.data==HeroName(h));
                end

                PlotStruct.HeroSweepPos  = PlotStruct.HeroSweepPos(h:h:2*h);

                if any(ismember(HeroName, NamesPassedSweeps)) && ~isempty(PosSpTrain) 

                          HeroSweep = getRow(cellFile.processing.map('AP Pattern'...
                                        ).dynamictable.values{1}, PosSpTrain);                                    
                else
                      target = [target - 20, target + 20];
                end
            end

            if ~isempty(HeroSweep)

                ICsummary.cvISI(cellNr,1) = HeroSweep.cvISI;
                ICsummary.HeroRate(cellNr,1) = HeroSweep.meanFR1000;
                ICsummary.heroLatency(cellNr,1) = HeroSweep.latency;
                ICsummary.peakAdapt(cellNr,1) = HeroSweep.peakAdapt;
                ICsummary.adaptIndex(cellNr,1) = HeroSweep.adaptIndex2;
                ICsummary.burst(cellNr,1) = HeroSweep.burst;           

                PlotStruct.HeroSweepSeries = cellFile.resolve(SweepPathsAll(PlotStruct.HeroSweepPos(...
                        contains(SweepPathsAll(PlotStruct.HeroSweepPos),'acquisition'))));
            else
                PlotStruct.HeroSweepSeries = [];
            end
        else
            PlotStruct.HeroSweepSeries = [];
        end
else
    disp("Under construction")

end