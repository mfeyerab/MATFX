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
            else
                QC_parameter.Protocol(SweepCount) = {'NA'};
                QCpass.Protocol(SweepCount) = {'NA'};
            end  
        end