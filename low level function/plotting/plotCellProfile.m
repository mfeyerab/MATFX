function plotCellProfile(nwb, PS, icSum)

%{
plot characterization
%}
SwpRespTbl = ...
  nwb.general_intracellular_ephys_intracellular_recordings.responses.response.data.load;
SwpAmps = ...
 nwb.general_intracellular_ephys_intracellular_recordings.stimuli.vectordata.values{1}.data.load     ;
CellNr = contains(icSum.Row, PS.cellID);
%% Initialize plot
figure('Position',[50 50 750 750],'visible','off'); set(gcf,'color','w');
subplot(2,2,1)
hold on

%% Get stimulus onsets and end for plotting first subfigure: rheo and sag sweep
if length(PS.sagSwpSers) > 1 && length(PS.sagSwpSers) < 3
   data = mean([PS.sagSwpSers{1}.data.load, ...
                              PS.sagSwpSers{2}.data.load],2);
   sagSwpOn = double(table2array(SwpRespTbl(PS.sagSwpTabPos(1),1)));
   sagSwpOff = double(sagSwpOn + ...
                    double(table2array(SwpRespTbl(PS.sagSwpTabPos(1),2))));
   p = plot([0:1000/PS.sagSwpSers{1}.starting_time_rate: ...
        (sagSwpOff-sagSwpOn+(0.3*PS.sagSwpSers{1}.starting_time_rate))...
        /PS.sagSwpSers{1}.starting_time_rate*1000],...
        data(sagSwpOn-0.1*PS.sagSwpSers{1}.starting_time_rate...
          :sagSwpOff+0.2*PS.sagSwpSers{1}.starting_time_rate));                                          
elseif length(PS.sagSwpSers) > 1 && length(PS.sagSwpSers) < 4
   data = mean([PS.sagSwpSers{1}.data.load, ...
                              PS.sagSwpSers{2}.data.load, ...
                                 PS.sagSwpSers{3}.data.load],2);
   sagSwpOn = double(table2array(SwpRespTbl(PS.sagSwpTabPos(1),1))); % Changed sagSwpTabPos[1} into sagSwpTabPos(1) to circumvent an error
   sagSwpOff = double(sagSwpOn + ...
                    double(table2array(SwpRespTbl(PS.sagSwpTabPos(1),2))));
   p = plot([0:1000/PS.sagSwpSers{1}.starting_time_rate: ...
        (sagSwpOff-sagSwpOn+(0.3*PS.sagSwpSers{1}.starting_time_rate))...
        /PS.sagSwpSers{1}.starting_time_rate*1000],...
        data(sagSwpOn-0.1*PS.sagSwpSers{1}.starting_time_rate...
          :sagSwpOff+0.2*PS.sagSwpSers{1}.starting_time_rate));
else   
 if ~isempty(PS.sagSwpSers) && ~isempty(PS.sagSwpSers.data) 
  sagSwpOn = double(table2array(SwpRespTbl(PS.sagSwpTabPos,1)));
  sagSwpOff = double(sagSwpOn + double(table2array(SwpRespTbl(PS.sagSwpTabPos,2))));
  p = plot([0:1000/PS.sagSwpSers.starting_time_rate: ...
        (sagSwpOff-sagSwpOn+(0.3*PS.sagSwpSers.starting_time_rate))...
        /PS.sagSwpSers.starting_time_rate*1000],...
        PS.sagSwpSers.data.load(sagSwpOn-0.1*PS.sagSwpSers.starting_time_rate...
          :sagSwpOff+0.2*PS.sagSwpSers.starting_time_rate));
 end
end

if exist('p') && length(PS.sagSwpSers)>1
  p.Color = 'black';
  if checkVolts(PS.sagSwpSers{1}.data_unit) && ...
                     string(PS.sagSwpSers{1}.description) ~= "PLACEHOLDER"
    ylim([-0.115 0.070])
    ylabel('Voltage (V)')
  else
    ylim([-115 70])
    ylabel('Voltage (mV)')
  end
elseif exist('p') && length(PS.sagSwpSers)==1
  p.Color = 'black';
  if checkVolts(PS.sagSwpSers.data_unit) && ...
                     string(PS.sagSwpSers.description) ~= "PLACEHOLDER"
    ylim([-0.115 0.070])
    ylabel('Voltage (V)')
  else
    ylim([-115 70])
    ylabel('Voltage (mV)')
  end  
end

%% Subfigure 1 Rheo
if ~isempty(PS.rheoSwpSers)
    RheoSweepOn = double(table2array(SwpRespTbl(PS.rheoSwpTabPos,1)));
    RheoSweepOff = RheoSweepOn + ...
                  double(table2array(SwpRespTbl(PS.rheoSwpTabPos,2)));
    p = plot([0:1000/PS.rheoSwpSers.starting_time_rate: ...
        (RheoSweepOff-RheoSweepOn+(0.3*PS.rheoSwpSers.starting_time_rate))...
        /PS.rheoSwpSers.starting_time_rate*1000],...
        PS.rheoSwpSers.data.load(RheoSweepOn-0.1*PS.rheoSwpSers.starting_time_rate...
          :RheoSweepOff+0.2*PS.rheoSwpSers.starting_time_rate));
    p.Color = 'black';
    if checkVolts(PS.rheoSwpSers.data_unit) &&  string(PS.rheoSwpSers.description) ~= "PLACEHOLDER"
      ylim([-0.115 0.080])
      ylabel('Voltage (V)')
    else
      ylim([-115 80])
      ylabel('Voltage (mV)')
     end
end    
 
if isempty(PS.rheoSwpTabPos)
  RheoAmp = [];
elseif length(PS.rheoSwpTabPos)==1
  RheoAmp = num2str(unique(SwpAmps(PS.rheoSwpTabPos)));
end
if isempty(PS.sagSwpTabPos)
  sagAmp = [];
elseif length(PS.sagSwpTabPos)==1
  sagAmp = num2str(unique(SwpAmps(PS.sagSwpTabPos)));
end
title(['LP rheo (', RheoAmp,' pA) and sag sweep (', sagAmp,'pA)'])
xlabel('time (ms)')
box off

%% Plotting second subfigure: hero sweep
 
subplot(2,2,2)
hold on
if ~isempty(PS.heroSwpSers) 
     HeroSweepOn = unique(double(table2array(SwpRespTbl(...
                       PS.heroSwpTabPos,1))));
     HeroSweepOff = unique(double(HeroSweepOn+double(table2array(...
                         SwpRespTbl(PS.heroSwpTabPos,2)))));
    p = plot([0:1000/PS.heroSwpSers.starting_time_rate: ...
        (HeroSweepOff-HeroSweepOn+(0.3*PS.heroSwpSers.starting_time_rate))...
        /PS.heroSwpSers.starting_time_rate*1000],...
        PS.heroSwpSers.data.load(HeroSweepOn-0.1*PS.heroSwpSers.starting_time_rate...
          :HeroSweepOff+0.2*PS.heroSwpSers.starting_time_rate));
    p.Color = 'black';
    if checkVolts(PS.heroSwpSers.data_unit) && string(PS.heroSwpSers.description) ~= "PLACEHOLDER"
      ylim([-0.115 0.080])
      ylabel('Voltage (V)')
    else
      ylim([-115 80])
      ylabel('Voltage (mV)')
     end
end    

if isa(SwpAmps, 'single') || isa(SwpAmps, 'double')
   HeroAmp = num2str(unique(round(SwpAmps(PS.heroSwpTabPos))));
elseif isempty(PS.heroSwpTabPos)
   HeroAmp =[];
else
   HeroAmp = num2str(unique(round(SwpAmps.load(PS.heroSwpTabPos))));
end

title(['Hero sweep (', num2str(HeroAmp), ' pA)'])
ylabel('Voltage (mV)')
xlabel('time (ms)')
box off
%% Plotting third subfigure: AP waveforms

subplot(2,2,3)
hold on
if ~isempty(PS.rheoSwpSers)
    RheoStart = PS.RheoStart + (...
        icSum.lat(CellNr)*PS.rheoSwpSers.starting_time_rate/1000);
    p = plot([0:1000/PS.rheoSwpSers.starting_time_rate: ...
        (0.006*PS.rheoSwpSers.starting_time_rate)...
        /PS.rheoSwpSers.starting_time_rate*1000],...
        PS.rheoSwpSers.data.load(...
           RheoStart - 0.001*PS.rheoSwpSers.starting_time_rate ...
          :RheoStart + 0.005*PS.rheoSwpSers.starting_time_rate));
    p.Color = 'black';
    if checkVolts(PS.rheoSwpSers.data_unit) && string(PS.rheoSwpSers.description) ~= "PLACEHOLDER"
      ylim([-0.075 0.080])
      ylabel('Voltage (V)')
      scatter(1,icSum.thresLP(CellNr)/1000,100)
    else
      ylim([-75 80])
      ylabel('Voltage (mV)')
      scatter(1,icSum.thresLP(CellNr),100)
    end
end  
if ~isempty(PS.SPSwpSers)

    spStartSP = (icSum.latencySP(CellNr)*...
                   PS.SPSwpSers.starting_time_rate/1000) + PS.SPStart;
     p = plot([0:1000/PS.SPSwpSers.starting_time_rate: ...
    (0.006*PS.SPSwpSers.starting_time_rate)...
    /PS.SPSwpSers.starting_time_rate*1000],...
    PS.SPSwpSers.data.load(spStartSP - ...
                            (0.001*PS.SPSwpSers.starting_time_rate) ...
                           :spStartSP + ...
                            (0.005*PS.SPSwpSers.starting_time_rate)));
    p.Color = 'red';
    scatter(1,icSum.thresholdSP(CellNr),100)
end

if isa(SwpAmps, 'double') || isa(SwpAmps, 'single')
   SPAmp = num2str(unique(SwpAmps(PS.SPSwpTbPos)));
elseif isempty(PS.SPSwpTbPos)
    SPAmp = [];
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
if ~isempty(PS.rheoSwpSers)
    p =  plot(PS.rheoSwpSers.data.load(...
           RheoStart - 0.001*PS.rheoSwpSers.starting_time_rate ...
          :RheoStart + 0.005*PS.rheoSwpSers.starting_time_rate),...
      diff(        PS.rheoSwpSers.data.load(...
           RheoStart - 0.001*PS.rheoSwpSers.starting_time_rate ...
          :RheoStart + 0.005*PS.rheoSwpSers.starting_time_rate+1))/...
          (1000/PS.rheoSwpSers.starting_time_rate));    
    p.Color = 'black';  
    if checkVolts(PS.rheoSwpSers.data_unit)
      ylabel('dV/dt (V/ms)')
      xlabel('Voltage (V)')
      xlim([-0.075 0.080])
      ylim([-0.60 0.8])
      scatter(icSum.thresLP(CellNr)/1000, ...
       diff(PS.rheoSwpSers.data.load(RheoStart:RheoStart+1))/...
       (1000/PS.rheoSwpSers.starting_time_rate),100);
    else
      ylabel('dV/dt (mV/ms)')
      xlabel('Voltage (mV)')
      xlim([-75 80])
      ylim([-600 800])
      scatter(icSum.thresLP(CellNr), ...
       diff(PS.rheoSwpSers.data.load(RheoStart-1:RheoStart))/...
       (1000/PS.rheoSwpSers.starting_time_rate));
      plot([-75 80],ones(2,1)*icSum.peakUpStrkLP(CellNr), ...
          'Color','k','LineStyle','--')
      plot([-75 80],ones(2,1)*icSum.peakDwStrkLP(CellNr), ...
          'Color','k','LineStyle','--')
    end
end 
if ~isempty(PS.SPSwpSers) && ~isempty(PS.SPSwpSers.data)
     p = plot(    PS.SPSwpSers.data.load(spStartSP - ...
                            (0.001*PS.SPSwpSers.starting_time_rate) ...
                           :spStartSP + ...
                            (0.005*PS.SPSwpSers.starting_time_rate)),...
     diff(    PS.SPSwpSers.data.load(spStartSP - ...
                            (0.001*PS.SPSwpSers.starting_time_rate) ...
                           :spStartSP + ...
                            (0.005*PS.SPSwpSers.starting_time_rate)+1))/...
                            (1000/PS.SPSwpSers.starting_time_rate));  
         p.Color = 'red';  
     plot([-75 80],ones(2,1)*icSum.peakUpStrkLP(CellNr), ...
          'Color','r','LineStyle','--')
     plot([-75 80],ones(2,1)*icSum.peakDwStrkLP(CellNr), ...
          'Color','r','LineStyle','--')                 
end
title('Waveform phaseplots SP vs LP')
if ~isempty(PS.rheoSwpSers) && ~isempty(PS.rheoSwpSers.data)
PipCompLP = PS.rheoSwpSers.capacitance_compensation*10^12;
end
if ~isempty(PS.SPSwpSers)
PipCompSP = PS.SPSwpSers.capacitance_compensation*10^12;
end

%% Saving the figure
F=getframe(gcf);
imwrite(F.cdata,fullfile(PS.outDest, 'profiles', ...
                                 [PS.cellID,' Cell profile',PS.pltForm]))
%% Export LP rheo waveform 4 website
if ~isempty(PS.rheoSwpSers) && ~isempty(PS.rheoSwpSers.data) && PS.Webexport==1
    figure('visible','off')
    p = plot([0:1000/PS.rheoSwpSers.starting_time_rate: ...
            (0.004*PS.rheoSwpSers.starting_time_rate)...
            /PS.rheoSwpSers.starting_time_rate*1000],...
            PS.rheoSwpSers.data.load(round((spStart/1000)*PS.rheoSwpSers.starting_time_rate) -...
            1*PS.rheoSwpSers.starting_time_rate/1000 ...
              :round((spStart/1000)*PS.rheoSwpSers.starting_time_rate) +...
                  3*PS.rheoSwpSers.starting_time_rate/1000) - ...
                  PS.rheoSwpSers.data.load(round((spStart/1000)*PS.rheoSwpSers.starting_time_rate)...
                  -1*PS.rheoSwpSers.starting_time_rate/1000),'LineWidth',2.5);
        if checkVolts(PS.rheoSwpSers.data_unit) && string(PS.rheoSwpSers.description) ~= "PLACEHOLDER"
          ylim([-0.03 0.12])
        else
          ylim([-30 120])
        end
    p.Color = 'black'; 
    set(gca,'visible','off')
    exportgraphics(gcf,fullfile(PS.outDest, 'AP_Waveforms', [PS.cellID, '.pdf']),'BackgroundColor','none');
end

