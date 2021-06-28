function [nwb,  SweepAmp, StimOn, StimOff]  = importSweeps(...
                  nwb, SweepAmp, StimOn, StimOff, alignSamplingMode, SamplingTarget,  stimName, sweepCount, filename, stimPath, sweepPath, sweepName, ic_elec_link)
             
SweepAmp(sweepCount,1) =  round(h5read( ...
filename, [sweepPath, '/aibs_stimulus_amplitude_pa']));

stimData = h5read( filename, [stimPath, '/data']);

if H5L.exists(H5G.open(H5F.open(filename), sweepPath),'bias_current','H5P_DEFAULT')
   biasCurrent = h5read(filename, [sweepPath, '/bias_current']);
else
   biasCurrent = 0;
end

if H5L.exists(H5G.open(H5F.open(filename), sweepPath),...
        'capacitance_compensation','H5P_DEFAULT')
   CapaComp = h5read(filename, [sweepPath, '/capacitance_compensation']);
else
   CapaComp = 0;
end


if SweepAmp(sweepCount,1)  < 0
  [~,temp] = findpeaks(-stimData); 
    if length(temp) < 2
      StimOn(sweepCount,1) = temp-1 ;
    else
      StimOn(sweepCount,1) = temp(2)-1;
    end
  StimOff(sweepCount,1) = find(stimData~=0, 1,'last');
else
    [~,temp] = findpeaks(stimData); 
    if length(temp) < 2
       StimOn(sweepCount,1) = temp-1 ;
    else
       StimOn(sweepCount,1) = temp(2)-1;
    end
    StimOff(sweepCount,1) = find(stimData~=0, 1,'last'); 
end

if alignSamplingMode== 1
   if h5readatt(filename, [stimPath, '/starting_time'], 'rate') < SamplingTarget
       disp('No alignment of sampling rate possible since sampling rate is below target')    
   else
      scaleFactor = round(h5readatt(...
                filename, [stimPath, '/starting_time'], 'rate')/SamplingTarget);
      newRate = h5readatt(...
                filename, [stimPath, '/starting_time'], 'rate')/scaleFactor;
      StimOn(sweepCount,1) = StimOn(sweepCount,1)/scaleFactor;
      StimOff(sweepCount,1) = StimOff(sweepCount,1)/scaleFactor;
      Data = h5read(filename, [sweepPath, '/data']);
      Data = Data(1:scaleFactor:length(Data)-1);
      
      nwb.acquisition.set( sweepName, types.core.CurrentClampSeries( ...
            'bias_current', biasCurrent, ... % Unit: Amp
            'bridge_balance', h5read(...
            filename, [sweepPath, '/bridge_balance']), ... % Unit: Ohm
            'capacitance_compensation', CapaComp, ... % Unit: Farad
            'data', Data, ...
            'data_unit', h5readatt(...
                     filename, [sweepPath, '/data'], 'unit'), ...
            'electrode', ic_elec_link, ...
            'stimulus_description', stimName,...
            'sweep_number', sweepCount-1,... 
            'starting_time', h5read(...
                filename, [stimPath, '/starting_time']),...
            'starting_time_rate', newRate ...
         ));
             
      stimData = stimData(1:scaleFactor:length(stimData));
      
      nwb.stimulus_presentation.set(sweepName,...
        types.core.CurrentClampStimulusSeries(...
            'electrode', ic_elec_link, ...
            'gain', NaN, ...
            'stimulus_description', stimName,...
            'data_unit', h5readatt(...
                     filename, [stimPath, '/data'], 'unit'), ...
            'data', stimData, ...
            'sweep_number', sweepCount-1,...                     
            'starting_time', h5read(...
                filename, [stimPath, '/starting_time']),...
            'starting_time_rate', newRate...
          ));
   end
else
      nwb.acquisition.set( sweepName, types.core.CurrentClampSeries( ...
            'bias_current', biasCurrent, ... % Unit: Amp
            'bridge_balance', h5read(...
            filename, [sweepPath, '/bridge_balance']), ... % Unit: Ohm
            'capacitance_compensation', CapaComp, ... % Unit: Farad
            'data', h5read(filename, [sweepPath, '/data']), ...
            'data_unit', h5readatt(...
                     filename, [sweepPath, '/data'], 'unit'), ...
            'electrode', ic_elec_link, ...
            'stimulus_description', stimName,...
            'sweep_number', sweepCount-1,... 
            'starting_time', h5read(...
                filename, [stimPath, '/starting_time']),...
            'starting_time_rate', h5readatt(...
                filename, [sweepPath, '/starting_time'], 'rate') ...
         ));
                        
      nwb.stimulus_presentation.set(sweepName,...
        types.core.CurrentClampStimulusSeries(...
            'electrode', ic_elec_link, ...
            'gain', NaN, ...
            'stimulus_description', stimName,...
            'data_unit', h5readatt(...
                     filename, [stimPath, '/data'], 'unit'), ...
            'data', stimData, ...
            'sweep_number', sweepCount-1,...                     
            'starting_time', h5read(...
                filename, [stimPath, '/starting_time']),...
            'starting_time_rate', h5readatt(...
                filename, [stimPath, '/starting_time'], 'rate')...
          ));
    
end