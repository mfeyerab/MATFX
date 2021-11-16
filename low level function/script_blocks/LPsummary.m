function [cellFile, ICsummary, PlotStruct] = ...
    LPsummary(cellFile, ICsummary, cellNr, params)

SweepResponseTbl = ...
  cellFile.general_intracellular_ephys_intracellular_recordings.responses.response.data.load;

if isa(cellFile.general_intracellular_ephys_intracellular_recordings.dynamictable.map(...
        'quality_control_pass').vectordata.values{1}.data, 'double')
    
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
            'protocol_type').vectordata.values{1}.data.load), params.LPtags)],2));  
    end

    SweepPaths = {SweepResponseTbl.timeseries.path};
    
    Sweepnames = cellfun(@(a) str2double(a), ...
        cellfun(@(v)v(1),regexp(SweepPaths,'\d*','Match')));        % inner cellfun necessary if sweep name contains mutliple numbers for example an extra AD01 

    NamesPassedSweeps = Sweepnames(IdxPassedSweeps);
    
    %% subthreshold summary parameters                              

    [ICsummary.resistanceHD(cellNr,1), ICsummary.resistanceOffset(cellNr,1)] = ...
        inputResistance(cellFile.processing.map('subthreshold parameters').dynamictable,...
        params, NamesPassedSweeps);                    % resistance based on steady state

    ICsummary.resistanceSS(cellNr,1) = inputResistanceSS(...
             cellFile.processing.map('subthreshold parameters').dynamictable, ...
             NamesPassedSweeps, params);   

    ICsummary.rectification(cellNr,1) = rectification(...
        cellFile.processing.map('subthreshold parameters').dynamictable,NamesPassedSweeps);

         if ~isempty(cellFile.processing.map('QC parameter'...
                 ).dynamictable.values{1}.vectordata.map('SweepID').data)

                QCTableIdx = find(ismember(regexp(cell2mat(...
                            cellFile.processing.map('QC parameter'...
                     ).dynamictable.values{1}.vectordata.map('SweepID').data),...
                     '\d*','Match'), cellstr(string(NamesPassedSweeps))));  

                ICsummary.Vrest(cellNr,1) = round(nanmean(...
                    cellFile.processing.map('QC parameter'...
                    ).dynamictable.values{1}.vectordata.map('Vrest').data(QCTableIdx)),2);                            % resting membrane potential
         else
             ICsummary.Vrest(cellNr,1) = NaN;
         end

    tau_vec = zeros(cellFile.processing.map('subthreshold parameters').dynamictable.Count,1);

    for s = 1:cellFile.processing.map('subthreshold parameters').dynamictable.Count
        number = string(regexp(...
           cellFile.processing.map('subthreshold parameters').dynamictable.keys{s},'\d*','Match'));

        if ismember(str2double(cell2mat(number(:,1))), NamesPassedSweeps) && ...
             ~isnan(cellFile.processing.map('subthreshold parameters' ...
               ).dynamictable.values{s}.vectordata.values{11}.data) && ...
                  cellFile.processing.map('subthreshold parameters' ...
                     ).dynamictable.values{s}.vectordata.values{11}.data
               tau_vec(s) =  cellFile.processing.map('subthreshold parameters'...
                   ).dynamictable.values{s}.vectordata.map('tauMin').data;
        end
    end    
    tau_vec(tau_vec==0) = [];
    tau_vec = sort(tau_vec);
    if length(tau_vec) < 3 && ~isempty(tau_vec)
        ICsummary.tau(cellNr,1) = round(mean(tau_vec(length(tau_vec))),2);
    elseif ~isempty(tau_vec)
       ICsummary.tau(cellNr,1) = round(mean(tau_vec(1:3)),2);
    else
       ICsummary.tau(cellNr,1) = NaN;
    end
    %% Maximum firing rate 
    
     MaxRate = 1;

     for s =1:length(NamesPassedSweeps)
              if any(strcmpi({num2str(NamesPassedSweeps(s))},...
                    cellFile.processing.map('AP Pattern').dynamictable.values{1}.vectordata.values{2}.data))
                 Idx = find(strcmpi({num2str(NamesPassedSweeps(s))},...
                    cellFile.processing.map('AP Pattern').dynamictable.values{1}.vectordata.values{2}.data));     
                 Rate = table2array(getRow(cellFile.processing.map('AP Pattern'...
                          ).dynamictable.values{1}, Idx, "columns", {'firingRate'}));
                      if Rate > MaxRate
                          MaxRate = Rate;
                      end
              end
     end

     ICsummary.maxFiringRate(cellNr,1) = MaxRate;  

    %% dynamic frequency range and adaptation
    if cellFile.processing.map('AP Pattern').dynamictable.isKey('ISIs') && ...
         ~isempty(cellFile.processing.map('AP Pattern').dynamictable.map('ISIs'...
         ).vectordata.values{1}.data)

       ISIs = cellFile.processing.map('AP Pattern').dynamictable.map('ISIs'...
         ).vectordata.values{1}.data;

       prunedISIs = ISIs;
       prunedISIs(ISIs==0) = [];
       ICsummary.medInstaRate(cellNr,1) = round(1000/nanmedian(prunedISIs),2);      
       ICsummary.ISIs_P90(cellNr,1) = round(prctile(ISIs, 90),2);           
       ICsummary.ISIs_P10(cellNr,1) = round(prctile(ISIs, 10),2); 
       ICsummary.ISIs_IQR(cellNr,1) = round(prctile(ISIs, 75) - ...
                                          prctile(ISIs, 25),2);

     if length(cellFile.processing.map('AP Pattern').dynamictable.map('ISIs'...
         ).vectordata.values{1}.data) == ...
            length(cellFile.processing.map('AP Pattern').dynamictable.map('ISIs'...
         ).vectordata.values{1}.data)

         TrueISIs = cellFile.processing.map('AP Pattern'...
             ).dynamictable.map('ISIs').vectordata.values{1}.data(~isnan(...
             cellFile.processing.map('AP Pattern').dynamictable.map('ISIs'...
                   ).vectordata.values{1}.data));

         if length(TrueISIs) == 1
             ICsummary.maxFiringRate(cellNr,1) = 2;
         end
     end

     if params.plot_all == 1
       figure('visible','off');
       cdfplot(1000./ISIs);
       grid off
       xlabel('instantenous frequency (Hz)')
       title('Dynamic frequency range')
       xlim([0 200])
       box off
       export_fig([params.outDest, '\firingPattern\', ...
           params.cellID , '_DFR'],params.plot_format,'-r100');
     end            
    ICsummary.AdaptRatioB1B2(cellNr,1) = ...
    round(sum(cellFile.processing.map('AP Pattern').dynamictable.values{2}.vectordata.map('B2').data)/ ...
    sum(cellFile.processing.map('AP Pattern').dynamictable.values{2}.vectordata.map('B1').data),2);

   ICsummary.AdaptRatioB1B10(cellNr,1) = ...
    round(sum(cellFile.processing.map('AP Pattern').dynamictable.values{2}.vectordata.map('B20').data)/ ...
    sum(cellFile.processing.map('AP Pattern').dynamictable.values{2}.vectordata.map('B1').data),2);

   ICsummary.AdaptRatioB1B20(cellNr,1) = ...
    round(sum(cellFile.processing.map('AP Pattern').dynamictable.values{2}.vectordata.map('B10').data)/ ...
    sum(cellFile.processing.map('AP Pattern').dynamictable.values{2}.vectordata.map('B1').data),2);

   if ~isempty(cellFile.processing.map('AP Pattern').dynamictable.values{2}.vectordata.values{1}.data)

       temp = table2array(getRow(cellFile.processing.map('AP Pattern'...
        ).dynamictable.values{2},1))./table2array(getRow(cellFile.processing.map(...
        'AP Pattern').dynamictable.values{2},length(cellFile.processing.map(...
        'AP Pattern').dynamictable.values{2}.id.data)));

      ICsummary.StimAdaptation(cellNr,1) = round(sum(temp(~isinf(temp)),'omitnan')/nnz(~isinf(temp)),3);

      ICsummary.MinLastQui(cellNr,1) = ...
          min(cellFile.processing.map('AP Pattern').dynamictable.values{1}.vectordata.values{1}.data);

      APPNames = cellFile.processing.map('AP Pattern').dynamictable.values{1}.vectordata.map('SweepIDs').data;

      APPIdx = find(ismember(cellfun(@(v)v(1), regexp(...
          SweepPaths,'\d*','Match')), cellstr(APPNames)));

      if isa(cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
              1}.data,'double')
         I = cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data(APPIdx);
      else
         I = cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data.load(APPIdx);
      end

      P = polyfit(I, cellFile.processing.map('AP Pattern'...
          ).dynamictable.values{1}.vectordata.map('firingRate').data,1);

      ICsummary.fI_slope(cellNr,1) = round(P(1),3);

      if params.plot_all == 1
           figure('visible','off');
           plot(I, cellFile.processing.map('AP Pattern'...
               ).dynamictable.values{1}.vectordata.map('firingRate').data)
           yfit = P(1)*I+P(2);
           hold on
           plot(I,yfit,'r-.');
           xlabel('input current (pA)')
           ylabel('firing frequency (Hz)')
           title('f/I curve')
           box off
           axis tight 
           export_fig([params.outDest, '\firingPattern\', ...
               params.cellID , ' fI_curve'],params.plot_format,'-r100');
      end
     end
    end
    %% finding sag sweep
    runs = 1;
    sagSweep = []; sagPos = [];
    PrefeSagAmps = [-90, -70, -110, -50, -30];
    PlotStruct.SagSweepTablePos = [];

    while isempty(sagSweep) && runs < 6
        for s = 1:cellFile.processing.map('subthreshold parameters').dynamictable.Count 

          number =  string(regexp(cellFile.processing.map('subthreshold parameters' ...
                 ).dynamictable.keys{s},'\d*','Match'));

          if ismember(str2double(cell2mat(number(:,1))), NamesPassedSweeps) && ...
               round(cellFile.processing.map('subthreshold parameters'...
               ).dynamictable.values{s}.vectordata.values{2}.data) == PrefeSagAmps(runs)  
             sagSweep = cellFile.processing.map('subthreshold parameters').dynamictable.values{s};
             sagPos = s;
          end    
        end
        if ~isempty(sagPos)
          PlotStruct.SagSweepTablePos = find(strcmp(SweepPaths,...
                    ['/acquisition/',cellFile.processing.map(...
                      'subthreshold parameters').dynamictable.keys{sagPos}]));
        end
        runs= runs +1;
    end

    if ~isempty(sagSweep)
        ICsummary.sagAmp(cellNr,1) = round(sagSweep.vectordata.map('SweepAmp').data,2);
        ICsummary.sag(cellNr,1) = round(sagSweep.vectordata.map('sag').data,2);
        ICsummary.sag_ratio(cellNr,1) = round(sagSweep.vectordata.map('sagRatio').data,2);  
        QCIdx = find(strcmp(cellFile.processing.map(...
            'QC parameter').dynamictable.values{1}.vectordata.map('SweepID').data, ...
                     cellFile.processing.map(...
                      'subthreshold parameters').dynamictable.keys{sagPos}));

        ICsummary.sagVrest(cellNr,1) = ...
             round(cellFile.processing.map('QC parameter'...
             ).dynamictable.values{1}.vectordata.map('Vrest').data(QCIdx),2);

        PlotStruct.sagSweepSeries = cellFile.resolve(SweepPaths(PlotStruct.SagSweepTablePos));
    else
        PlotStruct.sagSweepSeries = [];
    end

    %% find rheobase sweeps and parameters of first spike
    PlotStruct.RheoSweepTablePos = [];
    PlotStruct.RheoSweep = [];

    for s = 1:cellFile.processing.map('AP wave').dynamictable.Count            %% loop through all Sweeps with spike data
       number = string(regexp(...
            cellFile.processing.map('AP wave').dynamictable.keys{s},'\d*','Match'));

        if ismember(str2double(cell2mat(number(:,1))), NamesPassedSweeps)                  %% if sweep passed the QC

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
            SweepPaths,cellFile.processing.map('AP wave').dynamictable.keys{RheoPos}));

        ICsummary.Rheo(cellNr,1) = ...
          round(cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data(PlotStruct.RheoSweepTablePos));

        ICsummary.latency(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('thresholdTime').data(1) - ...
            table2array(SweepResponseTbl(PlotStruct.RheoSweepTablePos,1))*1000/cellFile.resolve(...
            SweepPaths(PlotStruct.RheoSweepTablePos( ...
            contains(SweepPaths(PlotStruct.RheoSweepTablePos),'acquisition')))).starting_time_rate;

        ICsummary.widthTP_LP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('fullWidthTP').data(1);
        ICsummary.peakLP(cellNr,1) = round(PlotStruct.RheoSweep.vectordata.map('peak').data(1),2);

        ICsummary.thresholdLP(cellNr,1) = round(PlotStruct.RheoSweep.vectordata.map('threshold').data(1),2);
        ICsummary.fastTroughLP(cellNr,1) = round(PlotStruct.RheoSweep.vectordata.map('fast_trough').data(1),2);
        ICsummary.slowTroughLP(cellNr,1) = round(PlotStruct.RheoSweep.vectordata.map('slow_trough').data(1),2);
        ICsummary.peakUpStrokeLP(cellNr,1) = round(PlotStruct.RheoSweep.vectordata.map('peakUpStroke').data(1),2);
        ICsummary.peakDownStrokeLP(cellNr,1) = round(PlotStruct.RheoSweep.vectordata.map('peakDownStroke').data(1),2);
        ICsummary.peakStrokeRatioLP(cellNr,1) = round(PlotStruct.RheoSweep.vectordata.map('peakStrokeRatio').data(1),2);   
        ICsummary.heightTP_LP(cellNr,1) = round(PlotStruct.RheoSweep.vectordata.map('heightTP').data(1),2);

        PlotStruct.RheoSweepSeries =  cellFile.resolve(SweepPaths(PlotStruct.RheoSweepTablePos(...
                contains(SweepPaths(PlotStruct.RheoSweepTablePos),'acquisition'))));

    else
        PlotStruct.RheoSweepSeries = [];
    end

    %% Hero sweep selection
    HeroSweep = [];            
    PlotStruct.HeroSweepPos = [];
    PlotStruct.HeroSweepTablePos = [];
    diff2target = [];
    if ~isnan(ICsummary.Rheo(cellNr,1))
        if ICsummary.Rheo(cellNr,1) <= 80
          target = ICsummary.Rheo(cellNr,1)+40;
        else
          target = ICsummary.Rheo(cellNr,1)+60;
        end
        if isa(...
            cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data, 'double')

           sweepAmps = cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data;
        else  
           sweepAmps = cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data.load;  
        end
        while isempty(HeroSweep) && all(target <= max(sweepAmps(IdxPassedSweeps))) && ...
                length(diff2target) < 10000

            target = target(~(target < ICsummary.Rheo(cellNr,1)));

            diff2target = min(abs(sweepAmps-target));

            [PlotStruct.HeroSweepPos , ~] = find(any(abs(sweepAmps-target)==diff2target,2));

            PosHeroNames = str2double(cellfun(@(v)v(1), ...
                regexp(cellstr(SweepPaths(PlotStruct.HeroSweepPos(...
                   contains(SweepPaths(PlotStruct.HeroSweepPos),'acquisition')))), ...
                   '\d*','Match')));

            for h = 1:length(PosHeroNames)  
                 check = find(str2double(cellFile.processing.map('AP Pattern'...
                    ).dynamictable.values{1}.vectordata.map('SweepIDs').data)==PosHeroNames(h));
                if isempty(check)
                   PosSpTrain(h) = NaN;
                else
                   PosSpTrain(h) = check;
                end
            end

            if ~isempty(PosSpTrain) && ~isempty(PosSpTrain(~isnan(PosSpTrain)))
                PosSpTrain = PosSpTrain(~isnan(PosSpTrain));
                mem = 10000;
                for i = 1:length(PosSpTrain)
                    RheoName = str2double(cell2mat(regexp(...
                        cellFile.processing.map('AP wave').dynamictable.keys{RheoPos},'\d*','Match')));
                    dist = abs(PosSpTrain(i) -RheoName); 
                    if any(ismember(PosHeroNames, NamesPassedSweeps)) && ...
                            mem > dist
                        HeroSweep = getRow(cellFile.processing.map('AP Pattern'...
                                        ).dynamictable.values{1}, PosSpTrain(i));     
                        mem = dist;            
                    end
                end
                if isempty(HeroSweep)
                    target = [target - 20, target + 20];
                end
            else
                  target = [target - 20, target + 20];
            end
        end

        if ~isempty(HeroSweep)
          temp =  cellfun(@(v)v(1),regexp(SweepPaths,'\d*','Match'));
          PlotStruct.HeroSweepTablePos =  find(strcmp(temp,HeroSweep.SweepIDs));

          PlotStruct.HeroSweepTablePos = PlotStruct.HeroSweepTablePos(contains(...
              SweepPaths(PlotStruct.HeroSweepTablePos), 'acquisition'));

          PlotStruct.HeroSweepSeries = cellFile.resolve(...
                                    SweepPaths(PlotStruct.HeroSweepTablePos));

            ICsummary.cvISI(cellNr,1) = round(HeroSweep.cvISI,3);
            ICsummary.HeroRate(cellNr,1) = HeroSweep.firingRate;
            ICsummary.HeroAmp(cellNr,1) = ...
                unique(cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data(find(Sweepnames==str2double(HeroSweep.SweepIDs)))) ;
            ICsummary.heroLatency(cellNr,1) = HeroSweep.latency;
            ICsummary.peakAdapt(cellNr,1) = round(HeroSweep.peakAdapt,3);
            ICsummary.adaptIndex(cellNr,1) = round(HeroSweep.adaptIndex2,3);
            ICsummary.burst(cellNr,1) = round(HeroSweep.burst,2);           

            if length(PlotStruct.HeroSweepSeries) > 1
             PlotStruct.HeroSweepSeries = PlotStruct.HeroSweepSeries{2};
            end

        elseif length(PlotStruct.RheoSweep.vectordata.map('heightTP').data) > 1
            PlotStruct.HeroSweepSeries = PlotStruct.RheoSweepSeries;
            PlotStruct.HeroSweepTablePos = PlotStruct.RheoSweepTablePos;
        else
            PlotStruct.HeroSweepSeries = [];
            PlotStruct.HeroSweepTablePos = [];
        end
    else
        PlotStruct.HeroSweepSeries = [];
        PlotStruct.HeroSweepTablePos = [];
    end
else  % required for runSummary because data format changes from double to DataStub
        IdxPassedSweeps = find(all(...
            [cellFile.general_intracellular_ephys_sweep_table.vectordata.map('QC_total_pass').data.load, ...
            cellFile.general_intracellular_ephys_sweep_table.vectordata.map('BinaryLP').data.load],2));  
        
        Sweepnames = cellfun(@(a) str2double(a), regexp(SweepPaths,'\d*','Match'));

        NamesPassedSweeps = unique(Sweepnames(IdxPassedSweeps));
        IdxPassedSweeps = IdxPassedSweeps(1:length(NamesPassedSweeps));

        %% subthreshold summary parameters                              

        [ICsummary.resistanceHD(cellNr,1), ICsummary.resistanceOffset(cellNr,1)] = ...
            inputResistance(cellFile.processing.map('subthreshold parameters').dynamictable,...
            params , NamesPassedSweeps);              % resistance based on steady state
        
        ICsummary.resistanceSS(cellNr,1) = inputResistanceSS(...
                 cellFile.processing.map('subthreshold parameters').dynamictable, ...
                 NamesPassedSweeps, params);    
             
        ICsummary.rectification(cellNr,1) = rectification(...
            cellFile.processing.map('subthreshold parameters').dynamictable,NamesPassedSweeps);
        
             if ~isempty(cellFile.processing.map('QC parameter'...
                     ).dynamictable.values{1}.vectordata.map('SweepID').data.load)
                 
                    QCTableIdx = find(ismember(regexp(cell2mat(...
                                cellFile.processing.map('QC parameter'...
                         ).dynamictable.values{1}.vectordata.map('SweepID').data.load),...
                         '\d*','Match'), cellstr(string(NamesPassedSweeps))));  

                    ICsummary.Vrest(cellNr,1) = nanmean(...
                        cellFile.processing.map('QC parameter'...
                        ).dynamictable.values{1}.vectordata.map('Vrest').data.load(QCTableIdx));                            % resting membrane potential
             else
                 ICsummary.Vrest(cellNr,1) = NaN;
             end
        tau_vec = [];

        for s = 1:cellFile.processing.map('subthreshold parameters').dynamictable.Count
            number = regexp(...
               cellFile.processing.map('subthreshold parameters').dynamictable.keys{s},'\d*','Match');

            if ismember(str2double(cell2mat(number)), NamesPassedSweeps) && ...
                 ~isnan(cellFile.processing.map('subthreshold parameters' ...
                   ).dynamictable.values{s}.vectordata.values{11}.data.load) && ...
                      cellFile.processing.map('subthreshold parameters' ...
                         ).dynamictable.values{s}.vectordata.values{11}.data.load

                   tau_vec =  [tau_vec, ...
                       cellFile.processing.map('subthreshold parameters').dynamictable.values{s}.vectordata.values{10}.data.load];
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
             ~isempty(cellFile.processing.map('All_ISIs').dynamictable.values{1}.vectordata.values{2}.data.load)
                                             
           ICsummary.medInstaRate(cellNr,1) = 1000/nanmedian(...
                  cellFile.processing.map('All_ISIs'...
                  ).dynamictable.values{1}.vectordata.values{1}.data.load);  
          
         if length(cellFile.processing.map('All_ISIs'...
             ).dynamictable.values{1}.vectordata.values{2}.data.load) == ...
             length(cellFile.processing.map('All_ISIs').dynamictable.values{1 ...
                                        }.vectordata.values{1}.data.load)
            
             TrueISIs = cellFile.processing.map('All_ISIs'...
               ).dynamictable.values{1}.vectordata.values{2}.data.load(~isnan(...
               cellFile.processing.map('All_ISIs').dynamictable.values{1 ...
                                        }.vectordata.values{1}.data.load));
                                                                     
             if length(TrueISIs) == 1
                 ICsummary.maxFiringRate(cellNr,1) = 2;
             end
         else
            ICsummary.maxFiringRate(cellNr,1) = max(diff(...
                cellFile.processing.map('All_ISIs'...
             ).dynamictable.values{1}.vectordata.values{2}.data.load));
            for s = 1:length(IdxPassedSweeps)
                
            end
         
         
         end   
      else            
          ICsummary.maxFiringRate(cellNr,1) = 0;
          ICsummary.medInstaRate(cellNr,1) = 0;         
      end
        %% finding sag sweep
        runs = 1;
        sagSweep = []; sagPos = [];
        PrefeSagAmps = [-90, -70, -110, -50, -30];
        PlotStruct.SagSweepTablePos = [];

        while isempty(sagSweep) && runs < 5
            for s = 1:cellFile.processing.map('subthreshold parameters').dynamictable.Count 

              number = regexp(cellFile.processing.map('subthreshold parameters' ...
                     ).dynamictable.keys{s},'\d*','Match');

              if ismember(str2double(cell2mat(number)), NamesPassedSweeps) && ...
                   round(cellFile.processing.map('subthreshold parameters'...
                   ).dynamictable.values{s}.vectordata.values{2}.data.load) == PrefeSagAmps(runs)  
                 sagSweep = cellFile.processing.map('subthreshold parameters').dynamictable.values{s};
                 sagPos = s;
              end    
            end
            if ~isempty(sagPos)
              PlotStruct.SagSweepTablePos = find(strcmp(SweepPaths,...
                        ['/acquisition/',cellFile.processing.map(...
                          'subthreshold parameters').dynamictable.keys{sagPos}]));
            end
            runs= runs +1;
        end

        if ~isempty(sagSweep)
            ICsummary.sagAmp(cellNr,1) = sagSweep.vectordata.values{2}.data.load;
            ICsummary.sag(cellNr,1) = sagSweep.vectordata.values{8}.data.load;
            ICsummary.sag_ratio(cellNr,1) = sagSweep.vectordata.values{9}.data.load;    
            QCIdx = find(strcmp(cellFile.processing.map(...
                'QC parameter').dynamictable.values{1}.vectordata.map('SweepID').data.load, ...
                         cellFile.processing.map(...
                          'subthreshold parameters').dynamictable.keys{sagPos}));
            
            ICsummary.sagVrest(cellNr,1) = ...
                 cellFile.processing.map('QC parameter'...
                 ).dynamictable.values{1}.vectordata.map('Vrest').data.load(QCIdx);
             
            PlotStruct.sagSweepSeries = cellFile.resolve(SweepPaths(PlotStruct.SagSweepTablePos));
        else
            PlotStruct.sagSweepSeries = [];
        end

        %% find rheobase sweeps and parameters of first spike
        PlotStruct.RheoSweepTablePos = [];
        PlotStruct.RheoSweep = [];
        
        for s = 1:cellFile.processing.map('AP wave').dynamictable.Count            %% loop through all Sweeps with spike data
            number = regexp(...
                cellFile.processing.map('AP wave').dynamictable.keys{s},'\d*','Match');
            if ismember(str2double(cell2mat(number)), NamesPassedSweeps)                  %% if sweep passed the QC

               if (isempty(PlotStruct.RheoSweep) && length(cellFile.processing.map('AP wave' ...
                    ).dynamictable.values{s}.vectordata.values{1}.data.load) ...
                       <= params.maxRheoSpikes) || (~isempty(PlotStruct.RheoSweep)  && ...                        %% if the sweep has less 
                       length(cellFile.processing.map('AP wave').dynamictable.values{...
                         s}.vectordata.values{1}.data.load) < ...
                             length(PlotStruct.RheoSweep.vectordata.values{1}.data.load))                      

                  PlotStruct.RheoSweep = cellFile.processing.map('AP wave').dynamictable.values{s};
                  RheoPos = s;
               end
            end
        end    

        if ~isempty(PlotStruct.RheoSweep)

            PlotStruct.RheoSweepTablePos = find(endsWith(...
                SweepPaths,cellFile.processing.map('AP wave').dynamictable.keys{RheoPos}));

            ICsummary.Rheo(cellNr,1) = ...
                round(nanmean(unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                'SweepAmp').data.load(PlotStruct.RheoSweepTablePos))));

            ICsummary.latency(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('thresholdTime').data.load(1) - ...
                nanmean(cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                'StimOn').data.load(PlotStruct.RheoSweepTablePos))*1000/cellFile.resolve(...
                SweepPaths(PlotStruct.RheoSweepTablePos( ...
                contains(SweepPaths(PlotStruct.RheoSweepTablePos),'acquisition')))).starting_time_rate;

            ICsummary.widthTP_LP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('fullWidthTP').data.load(1);
            ICsummary.peakLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('peak').data.load(1);
            
            ICsummary.thresholdLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('threshold').data.load(1) ;
            ICsummary.fastTroughLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('fast_trough').data.load(1);
            ICsummary.slowTroughLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('slow_trough').data.load(1);
            ICsummary.peakUpStrokeLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('peakUpStroke').data.load(1);
            ICsummary.peakDownStrokeLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('peakDownStroke').data.load(1);
            ICsummary.peakStrokeRatioLP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('peakStrokeRatio').data.load(1);   
            ICsummary.heightTP_LP(cellNr,1) = PlotStruct.RheoSweep.vectordata.map('heightTP').data.load(1);

            PlotStruct.RheoSweepSeries =  cellFile.resolve(SweepPaths(PlotStruct.RheoSweepTablePos(...
                    contains(SweepPaths(PlotStruct.RheoSweepTablePos),'acquisition'))));

        else
            PlotStruct.RheoSweepSeries = [];
        end




        %% Hero sweep selection
        HeroSweep = [];            
        PlotStruct.HeroSweepPos = [];
        PlotStruct.HeroSweepTablePos = [];
        diff2target = [];
        if ~isnan(ICsummary.Rheo(cellNr,1))
            target = ICsummary.Rheo(cellNr,1)+60;
           
            if isa(...
                cellFile.general_intracellular_ephys_sweep_table.vectordata.map('SweepAmp').data.load, 'double')
            
               sweepAmps = cellFile.general_intracellular_ephys_sweep_table.vectordata.map('SweepAmp').data.load;
            else  
               sweepAmps = cellFile.general_intracellular_ephys_sweep_table.vectordata.map('SweepAmp').data.load.load;  
            end
            while isempty(HeroSweep) && all(target <= max(sweepAmps(IdxPassedSweeps))) && ...
                    length(diff2target) < 100000

                target = target(~(target < ICsummary.Rheo(cellNr,1)));

                diff2target = min(abs(sweepAmps-target));

                [PlotStruct.HeroSweepPos , ~] = find(any(abs(sweepAmps-target)==diff2target,2));

                PosHeroNames = str2double(cellfun(@(v)v(1), ...
                    regexp(cellstr(SweepPaths(PlotStruct.HeroSweepPos(...
                       contains(SweepPaths(PlotStruct.HeroSweepPos),'acquisition')))), ...
                       '\d*','Match')));

                for h = 1:length(PosHeroNames)  
                     check = find(cellFile.processing.map('AP Pattern'...
                        ).dynamictable.values{1}.vectordata.values{1}.data.load==PosHeroNames(h));
                    if isempty(check)
                       PosSpTrain(h) = NaN;
                    else
                       PosSpTrain(h) = check;
                    end
                end

                if ~isempty(PosSpTrain) && ~isempty(PosSpTrain(~isnan(PosSpTrain)))
                    PosSpTrain = PosSpTrain(~isnan(PosSpTrain));
                    mem = 10000;
                    for i = 1:length(PosSpTrain)
                        RheoName = str2double(cell2mat(regexp(...
                            cellFile.processing.map('AP wave').dynamictable.keys{RheoPos},'\d*','Match')));
                        dist = abs(PosSpTrain(i) -RheoName); 
                        if any(ismember(PosHeroNames, NamesPassedSweeps)) && ...
                                mem > dist
                            HeroSweep = getRow(cellFile.processing.map('AP Pattern'...
                                            ).dynamictable.values{1}, PosSpTrain(i));     
                            mem = dist;            
                        end
                    end
                    if isempty(HeroSweep)
                        target = [target - 20, target + 20];
                    end
                else
                      target = [target - 20, target + 20];
                end
            end

            if ~isempty(HeroSweep)
               temp = regexp(SweepPathsAll,'\d*','Match');
               temp = [temp{:}];
              PlotStruct.HeroSweepTablePos =  find(strcmp(temp,num2str(HeroSweep.SweepIDs)));
            
              PlotStruct.HeroSweepTablePos = PlotStruct.HeroSweepTablePos(contains(...
                  SweepPathsAll(PlotStruct.HeroSweepTablePos), 'acquisition'));
              
              PlotStruct.HeroSweepSeries = cellFile.resolve(...
                                        SweepPathsAll(PlotStruct.HeroSweepTablePos));

                ICsummary.cvISI(cellNr,1) = HeroSweep.cvISI;
                ICsummary.HeroRate(cellNr,1) = HeroSweep.meanFR1000;
                ICsummary.HeroAmp(cellNr,1) = ...
                    unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                    'SweepAmp').data.load(find(Sweepnames==HeroSweep.SweepIDs))) ;
                ICsummary.heroLatency(cellNr,1) = HeroSweep.latency;
                ICsummary.peakAdapt(cellNr,1) = HeroSweep.peakAdapt;
                ICsummary.adaptIndex(cellNr,1) = HeroSweep.adaptIndex2;
                ICsummary.burst(cellNr,1) = HeroSweep.burst;           
                ICsummary.delay(cellNr,1) = HeroSweep.delay;           

                if length(PlotStruct.HeroSweepSeries) > 1
                 PlotStruct.HeroSweepSeries = PlotStruct.HeroSweepSeries{2};
                end
            
            elseif length(PlotStruct.RheoSweep.vectordata.map('heightTP').data.load) > 1
                PlotStruct.HeroSweepSeries = PlotStruct.RheoSweepSeries;
                PlotStruct.HeroSweepTablePos = PlotStruct.RheoSweepTablePos;
            else
                PlotStruct.HeroSweepSeries = [];
                PlotStruct.HeroSweepTablePos = [];
            end
        else
            PlotStruct.HeroSweepSeries = [];
            PlotStruct.HeroSweepTablePos = [];
        end
end