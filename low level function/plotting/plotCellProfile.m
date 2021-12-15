function plotCellProfile(cellFile, PlotStruct, params)

%{
plot characterization
%}
SwpRespTbl = ...
  cellFile.general_intracellular_ephys_intracellular_recordings.responses.response.data.load;
  
SwpAmps = ...
 cellFile.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{1}.data;
%% Initialize plot
figure('Position',[50 50 750 750],'visible','off'); set(gcf,'color','w');
subplot(2,2,1)
hold on

sagSwpSers = PlotStruct.sagSwpSers; 
rheoSwpSers = PlotStruct.rheoSwpSers; 
heroSwpSers = PlotStruct.heroSwpSers;
SPSweepSeries = PlotStruct.SPSweepSeries;

sagSwpTabPos = PlotStruct.sagSwpTabPos;
rheoSwpTabPos = PlotStruct.rheoSwpTabPos;
heroSwpTabPos = PlotStruct.heroSwpTabPos;

    
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

if ~isempty(sagSwpSers.data) 
  sagSwpOn = double(table2array(SwpRespTbl(sagSwpTabPos,1)));
  sagSwpOff = double(sagSwpOn + table2array(SwpRespTbl(sagSwpTabPos,2)));
  p = plot([0:1000/sagSwpSers.starting_time_rate: ...
        (sagSwpOff-sagSwpOn+(0.35*sagSwpSers.starting_time_rate))...
        /sagSwpSers.starting_time_rate*1000],...
        sagSwpSers.data.load(sagSwpOn-0.15*sagSwpSers.starting_time_rate...
          :sagSwpOff+0.2*sagSwpSers.starting_time_rate));
    p.Color = 'black';
    if checkVolts(sagSwpSers.data_unit) && string(sagSwpSers.description) ~= "PLACEHOLDER"
      ylim([-0.115 0.070])
      ylabel('Voltage (V)')
    else
      ylim([-115 70])
      ylabel('Voltage (mV)')
     end
end

if ~isempty(rheoSwpSers.data)
    RheoSweepOn = double(table2array(SwpRespTbl(rheoSwpTabPos,1)));
    RheoSweepOff = RheoSweepOn + ...
                  double(table2array(SwpRespTbl(rheoSwpTabPos,2)));
    p = plot([0:1000/rheoSwpSers.starting_time_rate: ...
        (RheoSweepOff-RheoSweepOn+(0.35*rheoSwpSers.starting_time_rate))...
        /rheoSwpSers.starting_time_rate*1000],...
        rheoSwpSers.data.load(RheoSweepOn-0.15*rheoSwpSers.starting_time_rate...
          :RheoSweepOff+0.2*rheoSwpSers.starting_time_rate));
    p.Color = 'black';
    if checkVolts(rheoSwpSers.data_unit) &&  string(rheoSwpSers.description) ~= "PLACEHOLDER"
      ylim([-0.115 0.080])
      ylabel('Voltage (V)')
    else
      ylim([-115 80])
      ylabel('Voltage (mV)')
     end
end    
 
if isa(SwpAmps, 'double')
   RheoAmp = num2str(unique(SwpAmps(rheoSwpTabPos)));
else
   RheoAmp = num2str(unique(SwpAmps.load(rheoSwpTabPos)));
end
title(['LP rheo (', RheoAmp,' pA) and sag sweep'])
xlabel('time (ms)')
box off

%% Plotting second subfigure: hero sweep
 
subplot(2,2,2)
hold on
if ~isempty(heroSwpSers.data) 
    p = plot([0:1000/heroSwpSers.starting_time_rate: ...
        (RheoSweepOff-RheoSweepOn+(0.35*heroSwpSers.starting_time_rate))...
        /heroSwpSers.starting_time_rate*1000],...
        heroSwpSers.data.load(RheoSweepOn-0.15*heroSwpSers.starting_time_rate...
          :RheoSweepOff+0.2*heroSwpSers.starting_time_rate));
    p.Color = 'black';
    if checkVolts(heroSwpSers.data_unit) && string(heroSwpSers.description) ~= "PLACEHOLDER"
      ylim([-0.115 0.080])
      ylabel('Voltage (V)')
    else
      ylim([-115 80])
      ylabel('Voltage (mV)')
     end
end    

if isa(SwpAmps, 'double')
   HeroAmp = num2str(unique(SwpAmps(heroSwpTabPos)));
else
   HeroAmp = num2str(unique(SwpAmps.load(heroSwpTabPos)));
end

title(['Hero sweep (', num2str(HeroAmp), ' pA)'])
ylabel('Voltage (mV)')
xlabel('time (ms)')
box off
%% Plotting third subfigure: AP waveforms

subplot(2,2,3)
hold on
if ~isempty(rheoSwpSers.data)
    spStart = PlotStruct.rheoSwpDat.map('thresTi').data(1);
    p = plot([0:1000/rheoSwpSers.starting_time_rate: ...
        (0.006*rheoSwpSers.starting_time_rate)...
        /rheoSwpSers.starting_time_rate*1000],...
        rheoSwpSers.data.load(round((spStart/1000)*rheoSwpSers.starting_time_rate) -...
        1*rheoSwpSers.starting_time_rate/1000 ...
          :round((spStart/1000)*rheoSwpSers.starting_time_rate) +...
              5*rheoSwpSers.starting_time_rate/1000));
    p.Color = 'black';
    if checkVolts(rheoSwpSers.data_unit) && string(rheoSwpSers.description) ~= "PLACEHOLDER"
      ylim([-0.075 0.080])
      ylabel('Voltage (V)')
      scatter(1,PlotStruct.rheoSwpDat.map('thres').data(1)/1000,100)
    else
      ylim([-75 80])
      ylabel('Voltage (mV)')
      scatter(1,PlotStruct.rheoSwpDat.map('thres').data(1),100)
    end
end  
if ~isempty(SPSweepSeries)
    spStartSP = PlotStruct.SPSweep.vectordata.map('thresTi').data(1);
     p = plot([0:1000/SPSweepSeries.starting_time_rate: ...
    (0.006*SPSweepSeries.starting_time_rate)...
    /SPSweepSeries.starting_time_rate*1000],...
    SPSweepSeries.data.load(round((spStartSP/1000)*SPSweepSeries.starting_time_rate) -...
    1*SPSweepSeries.starting_time_rate/1000 ...
      :round((spStartSP/1000)*SPSweepSeries.starting_time_rate) +...
          5*SPSweepSeries.starting_time_rate/1000));
          p.Color = 'red';
    scatter(1,PlotStruct.SPSweep.vectordata.map('thres').data(1),100)
end

if isa(SwpAmps, 'double')
   SPAmp = num2str(unique(SwpAmps(PlotStruct.SPSweepTablePos)));
else
   SPAmp = num2str(unique(SwpAmps.load(PlotStruct.SPSweepTablePos)));
end

title(['Waveform SP (', SPAmp,'pA) vs LP (', RheoAmp ,'pA)'])
xlabel('time (ms)')
box off
legend('LP','Thresh_L_P','SP', 'Thresh_S_P')
legend('boxoff')

%% Plotting fourth subfigure: AP phaseplots

subplot(2,2,4)
hold on
if ~isempty(rheoSwpSers.data)
    p =  plot(rheoSwpSers.data.load(round((spStart/1000)*rheoSwpSers.starting_time_rate) -...
        1*rheoSwpSers.starting_time_rate/1000 + 1 ...
          :round((spStart/1000)*rheoSwpSers.starting_time_rate) +...
              5*rheoSwpSers.starting_time_rate/1000),...
      diff(rheoSwpSers.data.load(round((spStart/1000)*rheoSwpSers.starting_time_rate) -...
        1*rheoSwpSers.starting_time_rate/1000 ...
          :round((spStart/1000)*rheoSwpSers.starting_time_rate) +...
              5*rheoSwpSers.starting_time_rate/1000) ...
          /(1000/rheoSwpSers.starting_time_rate)));    
    p.Color = 'black';  
    if checkVolts(rheoSwpSers.data_unit)
      ylabel('dV/dt (V/ms)')
      xlabel('Voltage (V)')
      xlim([-0.075 0.080])
      ylim([-0.80 1])
      scatter(PlotStruct.rheoSwpDat.map('thres').data(1)/1000, ...
       diff(rheoSwpSers.data.load(spStart/1000*rheoSwpSers.starting_time_rate-1 ...
        :spStart/1000*rheoSwpSers.starting_time_rate))/...
       (1000/rheoSwpSers.starting_time_rate),100);
    else
      ylabel('dV/dt (mV/ms)')
      xlabel('Voltage (mV)')
      xlim([-75 80])
      ylim([-800 1000])
      scatter(PlotStruct.rheoSwpDat.map('thres').data(1), ...
       diff(rheoSwpSers.data.load(spStart/1000*rheoSwpSers.starting_time_rate-1 ...
        :spStart/1000*rheoSwpSers.starting_time_rate))/...
       (1000/rheoSwpSers.starting_time_rate),100);
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
if ~isempty(rheoSwpSers.data)
PipCompLP = rheoSwpSers.capacitance_compensation*10^12;
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
export_fig([params.outDest, '/profiles/', params.cellID,' Cell profile'],params.pltForm,'-r100');
close

%% Export LP rheo waveform 4 website
if ~isempty(rheoSwpSers.data)
    figure('visible','off')
    p = plot([0:1000/rheoSwpSers.starting_time_rate: ...
            (0.004*rheoSwpSers.starting_time_rate)...
            /rheoSwpSers.starting_time_rate*1000],...
            rheoSwpSers.data.load(round((spStart/1000)*rheoSwpSers.starting_time_rate) -...
            1*rheoSwpSers.starting_time_rate/1000 ...
              :round((spStart/1000)*rheoSwpSers.starting_time_rate) +...
                  3*rheoSwpSers.starting_time_rate/1000) - ...
                  rheoSwpSers.data.load(round((spStart/1000)*rheoSwpSers.starting_time_rate)...
                  -1*rheoSwpSers.starting_time_rate/1000),'LineWidth',2.5);
        if checkVolts(rheoSwpSers.data_unit) && string(rheoSwpSers.description) ~= "PLACEHOLDER"
          ylim([-0.03 0.12])
        else
          ylim([-30 120])
        end
    p.Color = 'black'; 
    set(gca,'visible','off')
    export_fig(fullfile(params.outDest, '/AP_Waveforms/', params.cellID),'-nocrop', '-transparent','-png','-r50');
end

