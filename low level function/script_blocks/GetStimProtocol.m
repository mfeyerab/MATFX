        %% if there are no information on stimulus structure in sweep table
           
if isnan(cellFile.general_intracellular_ephys_sweep_table.vectordata.map('StimOn').data(AquiSwTabIdx))
    [StimOn,StimOff] = GetSquarePulse(CCStimSeries, params);     
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
    if StimLength/CCStimSeries.starting_time_rate == params.LPlength
        
    cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
        find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
        'BinaryLP'))}.data(SwTabIdxAll) = 1;
    
    cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
        find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
        'BinarySP'))}.data(SwTabIdxAll) = 0;
    
    elseif StimLength/CCStimSeries.starting_time_rate == params.SPlength
    
       cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
         find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
         'BinarySP'))}.data(SwTabIdxAll) = 1;
            
      cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
        find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
        'BinaryLP'))}.data(SwTabIdxAll) = 0;
    else
        cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
          find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
             'BinaryLP'))}.data(SwTabIdxAll) = 0;
    
        cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
          find(contains(cellFile.general_intracellular_ephys_sweep_table.vectordata.keys(),...
             'BinarySP'))}.data(SwTabIdxAll) = 0;
    end
else
 StimOn = unique(...
    cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
    'StimOn').data.load(SwTabIdxAll));
 StimOff = unique(...
    cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
    'StimOff').data.load(SwTabIdxAll));
 sweepAmp = round(unique(...
    cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
    'SweepAmp').data.load(SwTabIdxAll)));     
 StimLength = unique(...
    cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
    'StimLength').data.load(SwTabIdxAll));
end
                
if isa(cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                    'BinaryLP').data, 'double')   
                
      if isnan(cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                    'BinaryLP').data(SwTabIdxAll))             
                QC_parameter.Protocol(SweepCount) = {'NA'};
                QCpass.Protocol(SweepCount) = {'NA'};

      elseif cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                    'BinarySP').data(SwTabIdxAll)
                QC_parameter.Protocol(SweepCount) = {'SP'};
                QCpass.Protocol(SweepCount) = {'SP'};
      elseif cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                    'BinaryLP').data(SwTabIdxAll)
                QC_parameter.Protocol(SweepCount) = {'LP'};
                QCpass.Protocol(SweepCount) = {'LP'};
      end
 else
      if isnan(cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                    'BinaryLP').data.load(SwTabIdxAll))              
                QC_parameter.Protocol(SweepCount) = {'NA'};
                QCpass.Protocol(SweepCount) = {'NA'};

      elseif cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                    'BinarySP').data.load(SwTabIdxAll)
                QC_parameter.Protocol(SweepCount) = {'SP'};
                QCpass.Protocol(SweepCount) = {'SP'};
      elseif cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                    'BinaryLP').data.load(SwTabIdxAll)
              QC_parameter.Protocol(SweepCount) = {'LP'};
              QCpass.Protocol(SweepCount) = {'LP'};
      end
 end