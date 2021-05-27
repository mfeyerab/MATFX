function plotCellProfile(cellFile, PlotStruct, outDest, params)

%{
plot characterization
%}

%% Initialize plot
figure('Position',[50 50 750 750]); set(gcf,'color','w');
subplot(2,2,1)
hold on

sagSweepSeries = PlotStruct.sagSweepSeries;
RheoSweepSeries = PlotStruct.RheoSweepSeries;
HeroSweepSeries = PlotStruct.HeroSweepSeries;

SagSweepTablePos = PlotStruct.SagSweepTablePos;
RheoSweepTablePos = PlotStruct.RheoSweepTablePos;
%HeroSweepTablePos = PlotStruct.HeroSweepTablePos;


%% Get stimulus onsets and end for plotting first subfigure: rheo and sag sweep

if ~isempty(sagSweepSeries) 
    sagSweepOn = ...
        unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{3}.data(SagSweepTablePos));
    sagSweepOff = ...
            unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{2}.data(SagSweepTablePos));
    p = plot([0:1000/sagSweepSeries.starting_time_rate: ...
        (sagSweepOff-sagSweepOn+(0.35*sagSweepSeries.starting_time_rate))...
        /sagSweepSeries.starting_time_rate*1000],...
        sagSweepSeries.data.load(sagSweepOn-0.15*sagSweepSeries.starting_time_rate...
          :sagSweepOff+0.2*sagSweepSeries.starting_time_rate));
    p.Color = 'black';
    if convertCharsToStrings(sagSweepSeries.data_unit)=="volts" ||...
        convertCharsToStrings(sagSweepSeries.data_unit)=="Volts"
      ylim([-0.115 0.060])
      ylabel('Voltage (V)')
    else
      ylim([-115 60])
      ylabel('Voltage (mV)')
     end
end

if ~isempty(RheoSweepSeries)
    RheoSweepOn = ...
        unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{3}.data(RheoSweepTablePos));
    RheoSweepOff = ...
        unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{2}.data(RheoSweepTablePos));  
    p = plot([0:1000/RheoSweepSeries.starting_time_rate: ...
        (RheoSweepOff-RheoSweepOn+(0.35*RheoSweepSeries.starting_time_rate))...
        /RheoSweepSeries.starting_time_rate*1000],...
        RheoSweepSeries.data.load(RheoSweepOn-0.15*RheoSweepSeries.starting_time_rate...
          :RheoSweepOff+0.2*RheoSweepSeries.starting_time_rate));
    p.Color = 'black';
    if convertCharsToStrings(RheoSweepSeries.data_unit)=="volts" ||...
        convertCharsToStrings(RheoSweepSeries.data_unit)=="Volts"
      ylim([-0.115 0.060])
      ylabel('Voltage (V)')
    else
      ylim([-115 60])
      ylabel('Voltage (mV)')
     end
end    
 
title('LP rheo and sag sweep')
xlabel('time (ms)')
box off


%% Plotting second subfigure: hero sweep
 
subplot(2,2,2)

if ~isempty(HeroSweepSeries)
    RheoSweepOn = ...
        unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{3}.data(RheoSweepTablePos));
    RheoSweepOff = ...
        unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{2}.data(RheoSweepTablePos));  
    p = plot([0:1000/HeroSweepSeries.starting_time_rate: ...
        (RheoSweepOff-RheoSweepOn+(0.35*HeroSweepSeries.starting_time_rate))...
        /HeroSweepSeries.starting_time_rate*1000],...
        HeroSweepSeries.data.load(RheoSweepOn-0.15*HeroSweepSeries.starting_time_rate...
          :RheoSweepOff+0.2*HeroSweepSeries.starting_time_rate));
    p.Color = 'black';
    if convertCharsToStrings(HeroSweepSeries.data_unit)=="volts" ||...
        convertCharsToStrings(HeroSweepSeries.data_unit)=="Volts"
      ylim([-0.115 0.060])
      ylabel('Voltage (V)')
    else
      ylim([-115 60])
      ylabel('Voltage (mV)')
     end
end    

title('hero sweep')
ylabel('Voltage (mV)')
xlabel('time (ms)')
box off


%% Plotting third subfigure: AP waveforms

% subplot(2,2,3)
% hold on
% if size(IC.wfLP,1) == n
%  p = plot(a.LP.acquireRes(1,k):a.LP.acquireRes(1,k):a.LP.acquireRes(1,k)*226,IC.wfLP(n,:));
%  p.Color = 'black';
% end
% if size(IC.wfSP,1) == n 
%  p = plot(a.SP.acquireRes(1,1):a.SP.acquireRes(1,1):a.SP.acquireRes(1,1)*226,...
%      IC.wfSP(n,:));
%  p.Color = 'red';
%  legend('boxoff')
%  legend('LP','SP')
% end
% title('Waveform SP vs LP')
% ylabel('Voltage (mV)')
% xlabel('time (ms)')
% box off
% ylim([-70 60])

%% Plotting third subfigure: AP phaseplots

% subplot(2,2,4)
% hold on
% if size(IC.wfLP,1) == n
%  p = plot(IC.wfLP(n,2:end),diff(IC.wfLP(n,:))/a.LP.acquireRes(1,k));
%  p.Color = 'black';
% end
% if size(IC.wfSP,1) == n 
%  p = plot(IC.wfSP(n,2:end),diff(IC.wfSP(n,:))/a.SP.acquireRes(1,1));
%  p.Color = 'red';
%  legend('boxoff')
%  legend('LP','SP')
% end
% title('Waveform SP vs LP')
% ylabel('dV/dt (mV/ms)')
% xlabel('Voltage (mV)')
% box off
% xlim([-60 60])
% ylim([-500 900])

%% Saving the figure

export_fig([outDest, cellFile.identifier,' Cell profile', date],params.plot_format,'-r100');
close

