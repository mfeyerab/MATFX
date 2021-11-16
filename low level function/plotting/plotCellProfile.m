function plotCellProfile(cellFile, PlotStruct, params)

%{
plot characterization
%}
SweepResponseTbl = ...
  cellFile.general_intracellular_ephys_intracellular_recordings.responses.response.data.load;

%% Initialize plot
figure('Position',[50 50 750 750],'visible','off'); set(gcf,'color','w');
subplot(2,2,1)
hold on

sagSweepSeries = PlotStruct.sagSweepSeries;
RheoSweepSeries = PlotStruct.RheoSweepSeries;
HeroSweepSeries = PlotStruct.HeroSweepSeries;
SPSweepSeries = PlotStruct.SPSweepSeries;

SagSweepTablePos = PlotStruct.SagSweepTablePos;
RheoSweepTablePos = PlotStruct.RheoSweepTablePos;
HeroSweepTablePos = PlotStruct.HeroSweepTablePos;

    
if ~isempty(cellFile.general_intracellular_ephys.values{1}.slice)
    temp = regexp(...
    cellFile.general_intracellular_ephys.values{1}.slice, '(\d+,)*\d+(\.\d*)?', 'match');
    if isempty(temp)
       Temperature = NaN;
    else
       Temperature = str2num(cell2mat(temp));
    end
end

%% Get stimulus onsets and end for plotting first subfigure: rheo and sag sweep

if ~isempty(sagSweepSeries) 
    sagSweepOn = double(table2array(SweepResponseTbl(SagSweepTablePos,1)));
    sagSweepOff = double(sagSweepOn + ...
                      table2array(SweepResponseTbl(SagSweepTablePos,2)));
    p = plot([0:1000/sagSweepSeries.starting_time_rate: ...
        (sagSweepOff-sagSweepOn+(0.35*sagSweepSeries.starting_time_rate))...
        /sagSweepSeries.starting_time_rate*1000],...
        sagSweepSeries.data.load(sagSweepOn-0.15*sagSweepSeries.starting_time_rate...
          :sagSweepOff+0.2*sagSweepSeries.starting_time_rate));
    p.Color = 'black';
    if checkVolts(sagSweepSeries.data_unit) && string(sagSweepSeries.description) ~= "PLACEHOLDER"
      ylim([-0.115 0.070])
      ylabel('Voltage (V)')
    else
      ylim([-115 70])
      ylabel('Voltage (mV)')
     end
end

if ~isempty(RheoSweepSeries)
    RheoSweepOn = double(table2array(SweepResponseTbl(RheoSweepTablePos,1)));
    RheoSweepOff = RheoSweepOn + ...
                  double(table2array(SweepResponseTbl(RheoSweepTablePos,2)));
    p = plot([0:1000/RheoSweepSeries.starting_time_rate: ...
        (RheoSweepOff-RheoSweepOn+(0.35*RheoSweepSeries.starting_time_rate))...
        /RheoSweepSeries.starting_time_rate*1000],...
        RheoSweepSeries.data.load(RheoSweepOn-0.15*RheoSweepSeries.starting_time_rate...
          :RheoSweepOff+0.2*RheoSweepSeries.starting_time_rate));
    p.Color = 'black';
    if checkVolts(RheoSweepSeries.data_unit) &&  string(RheoSweepSeries.description) ~= "PLACEHOLDER"
      ylim([-0.115 0.080])
      ylabel('Voltage (V)')
    else
      ylim([-115 80])
      ylabel('Voltage (mV)')
     end
end    
 
if isa(cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data, 'double')
   RheoAmp = num2str(unique(...
        cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data(RheoSweepTablePos)));
else
   RheoAmp = num2str(unique(...
       cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data.load(RheoSweepTablePos)));
end

title(['LP rheo (', RheoAmp,' pA) and sag sweep'])
xlabel('time (ms)')
box off

%% Plotting second subfigure: hero sweep
 
subplot(2,2,2)
hold on
if ~isempty(HeroSweepSeries) 
    p = plot([0:1000/HeroSweepSeries.starting_time_rate: ...
        (RheoSweepOff-RheoSweepOn+(0.35*HeroSweepSeries.starting_time_rate))...
        /HeroSweepSeries.starting_time_rate*1000],...
        HeroSweepSeries.data.load(RheoSweepOn-0.15*HeroSweepSeries.starting_time_rate...
          :RheoSweepOff+0.2*HeroSweepSeries.starting_time_rate));
    p.Color = 'black';
    if checkVolts(HeroSweepSeries.data_unit) && string(HeroSweepSeries.description) ~= "PLACEHOLDER"
      ylim([-0.115 0.080])
      ylabel('Voltage (V)')
    else
      ylim([-115 80])
      ylabel('Voltage (mV)')
     end
end    

if isa(cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data, 'double')
   HeroAmp = num2str(unique(...
        cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data(HeroSweepTablePos)));
else
   HeroAmp = num2str(unique(...
        cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data.load(HeroSweepTablePos)));
end

title(['Hero sweep (', num2str(HeroAmp), ' pA)'])
ylabel('Voltage (mV)')
xlabel('time (ms)')
box off
%% Plotting third subfigure: AP waveforms

subplot(2,2,3)
hold on
if ~isempty(RheoSweepSeries)
    spStart = PlotStruct.RheoSweep.vectordata.map('thresholdTime').data(1);
    p = plot([0:1000/RheoSweepSeries.starting_time_rate: ...
        (0.006*RheoSweepSeries.starting_time_rate)...
        /RheoSweepSeries.starting_time_rate*1000],...
        RheoSweepSeries.data.load(round((spStart/1000)*RheoSweepSeries.starting_time_rate) -...
        1*RheoSweepSeries.starting_time_rate/1000 ...
          :round((spStart/1000)*RheoSweepSeries.starting_time_rate) +...
              5*RheoSweepSeries.starting_time_rate/1000));
    p.Color = 'black';
    if checkVolts(RheoSweepSeries.data_unit) && string(RheoSweepSeries.description) ~= "PLACEHOLDER"
      ylim([-0.075 0.080])
      ylabel('Voltage (V)')
      scatter(1,PlotStruct.RheoSweep.vectordata.map('threshold').data(1)/1000,100)
    else
      ylim([-75 80])
      ylabel('Voltage (mV)')
      scatter(1,PlotStruct.RheoSweep.vectordata.map('threshold').data(1),100)
    end
end  
if ~isempty(SPSweepSeries)
    spStartSP = PlotStruct.SPSweep.vectordata.map('thresholdTime').data(1);
     p = plot([0:1000/SPSweepSeries.starting_time_rate: ...
    (0.006*SPSweepSeries.starting_time_rate)...
    /SPSweepSeries.starting_time_rate*1000],...
    SPSweepSeries.data.load(round((spStartSP/1000)*SPSweepSeries.starting_time_rate) -...
    1*SPSweepSeries.starting_time_rate/1000 ...
      :round((spStartSP/1000)*SPSweepSeries.starting_time_rate) +...
          5*SPSweepSeries.starting_time_rate/1000));
          p.Color = 'red';
    scatter(1,PlotStruct.SPSweep.vectordata.map('threshold').data(1),100)
end

if isa(cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data, 'double')
   SPAmp = num2str(unique(...
        cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data(PlotStruct.SPSweepTablePos)));
else
   SPAmp = num2str(unique(...
        cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{...
             1}.data.load(PlotStruct.SPSweepTablePos)));
end

title(['Waveform SP (', SPAmp,'pA) vs LP (', RheoAmp ,'pA)'])
xlabel('time (ms)')
box off
legend('LP','Thresh_L_P','SP', 'Thresh_S_P')
legend('boxoff')

%% Plotting fourth subfigure: AP phaseplots

subplot(2,2,4)
hold on
if ~isempty(RheoSweepSeries)
    p =  plot(RheoSweepSeries.data.load(round((spStart/1000)*RheoSweepSeries.starting_time_rate) -...
        1*RheoSweepSeries.starting_time_rate/1000 + 1 ...
          :round((spStart/1000)*RheoSweepSeries.starting_time_rate) +...
              5*RheoSweepSeries.starting_time_rate/1000),...
      diff(RheoSweepSeries.data.load(round((spStart/1000)*RheoSweepSeries.starting_time_rate) -...
        1*RheoSweepSeries.starting_time_rate/1000 ...
          :round((spStart/1000)*RheoSweepSeries.starting_time_rate) +...
              5*RheoSweepSeries.starting_time_rate/1000) ...
          /(1000/RheoSweepSeries.starting_time_rate)));    
    p.Color = 'black';  
    if checkVolts(RheoSweepSeries.data_unit)
      ylabel('dV/dt (V/ms)')
      xlabel('Voltage (V)')
      xlim([-0.075 0.080])
      ylim([-0.80 1])
      scatter(PlotStruct.RheoSweep.vectordata.map('threshold').data(1)/1000, ...
       diff(RheoSweepSeries.data.load(spStart/1000*RheoSweepSeries.starting_time_rate-1 ...
        :spStart/1000*RheoSweepSeries.starting_time_rate))/...
       (1000/RheoSweepSeries.starting_time_rate),100);
    else
      ylabel('dV/dt (mV/ms)')
      xlabel('Voltage (mV)')
      xlim([-75 80])
      ylim([-800 1000])
      scatter(PlotStruct.RheoSweep.vectordata.map('threshold').data(1), ...
       diff(RheoSweepSeries.data.load(spStart/1000*RheoSweepSeries.starting_time_rate-1 ...
        :spStart/1000*RheoSweepSeries.starting_time_rate))/...
       (1000/RheoSweepSeries.starting_time_rate),100);
    end
end 
if ~isempty(SPSweepSeries)
     p = plot(SPSweepSeries.data.load(round((spStartSP/1000)*SPSweepSeries.starting_time_rate) -...
        1*SPSweepSeries.starting_time_rate/1000 + 1 ...
          :round((spStartSP/1000)*SPSweepSeries.starting_time_rate) +...
              5*SPSweepSeries.starting_time_rate/1000),...
     diff(SPSweepSeries.data.load(round((spStartSP/1000)*SPSweepSeries.starting_time_rate) -...
        1*SPSweepSeries.starting_time_rate/1000 ...
          :round((spStartSP/1000)*SPSweepSeries.starting_time_rate) +...
              5*SPSweepSeries.starting_time_rate/1000) ...
          /(1000/SPSweepSeries.starting_time_rate)));  
         p.Color = 'red';  
end
title('Waveform phaseplots SP vs LP')
if ~isempty(RheoSweepSeries)
PipCompLP = RheoSweepSeries.capacitance_compensation*10^12;
end
if ~isempty(PlotStruct.SPSweepSeries)
PipCompSP = SPSweepSeries.capacitance_compensation*10^12;
end
% if ~isempty(PlotStruct.SPSweepSeries) && ~isempty(PipCompSP) && ...
%         PipCompSP==PipCompLP
% subtitle(['Temperature = ' ,num2str(round(Temperature,1)), '°C ,CapaComp = ', num2str(round(PipCompLP,2)), 'pF'])
% box off
% end
%% Saving the figure
export_fig([params.outDest, '/profiles/', params.cellID,' Cell profile', date],params.plot_format,'-r100');
close

%% Export LP rheo waveform 4 website
if ~isempty(RheoSweepSeries)
    figure
    p = plot([0:1000/RheoSweepSeries.starting_time_rate: ...
            (0.004*RheoSweepSeries.starting_time_rate)...
            /RheoSweepSeries.starting_time_rate*1000],...
            RheoSweepSeries.data.load(round((spStart/1000)*RheoSweepSeries.starting_time_rate) -...
            1*RheoSweepSeries.starting_time_rate/1000 ...
              :round((spStart/1000)*RheoSweepSeries.starting_time_rate) +...
                  3*RheoSweepSeries.starting_time_rate/1000) - ...
                  RheoSweepSeries.data.load(round((spStart/1000)*RheoSweepSeries.starting_time_rate)...
                  -1*RheoSweepSeries.starting_time_rate/1000),'LineWidth',2.5);
        if checkVolts(RheoSweepSeries.data_unit) && string(RheoSweepSeries.description) ~= "PLACEHOLDER"
          ylim([-0.03 0.12])
        else
          ylim([-30 120])
        end
    p.Color = 'black'; 
    set(gca,'visible','off')
    export_fig([params.outDest, '/AP_Waveforms/', params.cellID],'-nocrop', '-transparent','-png','-r50');
end

