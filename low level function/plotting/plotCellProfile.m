function plotCellProfile(nwb, PS)

%{
plot characterization
%}
SwpRespTbl = ...
  nwb.general_intracellular_ephys_intracellular_recordings.responses.response.data.load;
  
SwpAmps = ...
 nwb.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{1}.data;
%% Initialize plot
figure('Position',[50 50 750 750],'visible','off'); set(gcf,'color','w');
subplot(2,2,1)
hold on

sagSwpSers = PS.sagSwpSers; 
rheoSwpSers = PS.rheoSwpSers; 
heroSwpSers = PS.heroSwpSers;
SPSwpSers = PS.SPSwpSers;

sagSwpTabPos = PS.sagSwpTabPos;
rheoSwpTabPos = PS.rheoSwpTabPos;
heroSwpTabPos = PS.heroSwpTabPos;

    
if ~isempty(nwb.general_intracellular_ephys.values{1}.slice)
    temp = regexp(...
    nwb.general_intracellular_ephys.values{1}.slice, '(\d+,)*\d+(\.\d*)?', 'match');
    if isempty(temp)
       Temperature = NaN;
    else
       Temperature = str2num(cell2mat(temp));
    end
end

%% Get stimulus onsets and end for plotting first subfigure: rheo and sag sweep

if ~isempty(sagSwpSers) && ~isempty(sagSwpSers.data) 
  sagSwpOn = double(table2array(SwpRespTbl(sagSwpTabPos,1)));
  sagSwpOff = double(sagSwpOn + table2array(SwpRespTbl(sagSwpTabPos,2)));
  p = plot([0:1000/sagSwpSers.starting_time_rate: ...
        (sagSwpOff-sagSwpOn+(0.3*sagSwpSers.starting_time_rate))...
        /sagSwpSers.starting_time_rate*1000],...
        sagSwpSers.data.load(sagSwpOn-0.1*sagSwpSers.starting_time_rate...
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

if ~isempty(rheoSwpSers) && ~isempty(rheoSwpSers.data)
    RheoSweepOn = double(table2array(SwpRespTbl(rheoSwpTabPos,1)));
    RheoSweepOff = RheoSweepOn + ...
                  double(table2array(SwpRespTbl(rheoSwpTabPos,2)));
    p = plot([0:1000/rheoSwpSers.starting_time_rate: ...
        (RheoSweepOff-RheoSweepOn+(0.3*rheoSwpSers.starting_time_rate))...
        /rheoSwpSers.starting_time_rate*1000],...
        rheoSwpSers.data.load(RheoSweepOn-0.1*rheoSwpSers.starting_time_rate...
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
if ~isempty(heroSwpSers)&& ~isempty(heroSwpSers.data) 
     HeroSweepOn = double(table2array(SwpRespTbl(heroSwpTabPos,1)));
    p = plot([0:1000/heroSwpSers.starting_time_rate: ...
        (RheoSweepOff-HeroSweepOn+(0.3*heroSwpSers.starting_time_rate))...
        /heroSwpSers.starting_time_rate*1000],...
        heroSwpSers.data.load(HeroSweepOn-0.1*heroSwpSers.starting_time_rate...
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
if ~isempty(rheoSwpSers) && ~isempty(rheoSwpSers.data)
    spStart = PS.rheoSwpDat.map('thresTi').data(1);
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
      scatter(1,PS.rheoSwpDat.map('thres').data(1)/1000,100)
    else
      ylim([-75 80])
      ylabel('Voltage (mV)')
      scatter(1,PS.rheoSwpDat.map('thres').data(1),100)
    end
end  
if ~isempty(SPSwpSers) && ~isempty(SPSwpSers.data)
    spStartSP =  PS.SPSwpDat.map('thresTi').data;
     p = plot([0:1000/SPSwpSers.starting_time_rate: ...
    (0.006*SPSwpSers.starting_time_rate)...
    /SPSwpSers.starting_time_rate*1000],...
    SPSwpSers.data.load(round((spStartSP/1000)*SPSwpSers.starting_time_rate) -...
    1*SPSwpSers.starting_time_rate/1000 ...
      :round((spStartSP/1000)*SPSwpSers.starting_time_rate) +...
          5*SPSwpSers.starting_time_rate/1000));
          p.Color = 'red';
    scatter(1,PS.SPSwpDat.map('thres').data,100)
end

if isa(SwpAmps, 'double')
   SPAmp = num2str(unique(SwpAmps(PS.SPSwpTbPos)));
else
   SPAmp = num2str(unique(SwpAmps.load(PS.SPSwpTbPos)));
end

title(['Waveform SP (', SPAmp,'pA) vs LP (', RheoAmp ,'pA)'])
xlabel('time (ms)')
box off
legend('LP','Thresh_L_P','SP', 'Thresh_S_P')
legend('boxoff')

%% Plotting fourth subfigure: AP phaseplots

subplot(2,2,4)
hold on
if ~isempty(rheoSwpSers) && ~isempty(rheoSwpSers.data)
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
      scatter(PS.rheoSwpDat.map('thres').data(1)/1000, ...
       diff(rheoSwpSers.data.load(spStart/1000*rheoSwpSers.starting_time_rate-1 ...
        :spStart/1000*rheoSwpSers.starting_time_rate))/...
       (1000/rheoSwpSers.starting_time_rate),100);
    else
      ylabel('dV/dt (mV/ms)')
      xlabel('Voltage (mV)')
      xlim([-75 80])
      ylim([-800 1000])
      scatter(PS.rheoSwpDat.map('thres').data(1), ...
       diff(rheoSwpSers.data.load(spStart/1000*rheoSwpSers.starting_time_rate-1 ...
        :spStart/1000*rheoSwpSers.starting_time_rate))/...
       (1000/rheoSwpSers.starting_time_rate),100);
    end
end 
if ~isempty(SPSwpSers) && ~isempty(SPSwpSers.data)
     p = plot(SPSwpSers.data.load(round((spStartSP/1000)*SPSwpSers.starting_time_rate) -...
        1*SPSwpSers.starting_time_rate/1000 + 1 ...
          :round((spStartSP/1000)*SPSwpSers.starting_time_rate) +...
              5*SPSwpSers.starting_time_rate/1000),...
     diff(SPSwpSers.data.load(round((spStartSP/1000)*SPSwpSers.starting_time_rate) -...
        1*SPSwpSers.starting_time_rate/1000 ...
          :round((spStartSP/1000)*SPSwpSers.starting_time_rate) +...
              5*SPSwpSers.starting_time_rate/1000) ...
          /(1000/SPSwpSers.starting_time_rate)));  
         p.Color = 'red';  
end
title('Waveform phaseplots SP vs LP')
if ~isempty(rheoSwpSers) && ~isempty(rheoSwpSers.data)
PipCompLP = rheoSwpSers.capacitance_compensation*10^12;
end
if ~isempty(PS.SPSwpSers)
PipCompSP = SPSwpSers.capacitance_compensation*10^12;
end
% if ~isempty(PS.SPSwpSers) && ~isempty(PipCompSP) && ...
%         PipCompSP==PipCompLP
% subtitle(['Temperature = ' ,num2str(round(Temperature,1)), '°C ,CapaComp = ', num2str(round(PipCompLP,2)), 'pF'])
% box off
% end
%% Saving the figure
export_fig([PS.outDest, '/profiles/', PS.cellID,' Cell profile'],PS.pltForm,'-r100');
close

%% Export LP rheo waveform 4 website
if ~isempty(rheoSwpSers) && ~isempty(rheoSwpSers.data)
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
    export_fig(fullfile(PS.outDest, '/AP_Waveforms/', PS.cellID),'-nocrop', '-transparent','-png','-r50');
end

