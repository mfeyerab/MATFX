function plotCellProfile(RheoSweepSeries, sagSweepSeries, cellFile, ...
    RheoSweepTablePos, SagSweepTablePos, outDest, params)

%{
plot characterization
%}

%% Initialize plot
figure('Position',[50 50 750 750]); set(gcf,'color','w');
subplot(2,2,1)
hold on

%% Get stimulus onsets and end for plotting first subfigure: rheo and sag sweep

if ~isempty(sagSweepSeries) 
    sagSweepOn = ...
        unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{3}.data(SagSweepTablePos));
    sagSweepOff = ...
            unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{2}.data(SagSweepTablePos));
    p = plot(sagSweepSeries.data.load(sagSweepOn-0.15*sagSweepSeries.starting_time_rate...
          :sagSweepOff+0.2*sagSweepSeries.starting_time_rate));
    p.Color = 'black';
end    

if ~isempty(RheoSweepSeries)
    RheoSweepOn = ...
        unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{3}.data(RheoSweepTablePos));
    RheoSweepOff = ...
        unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{2}.data(RheoSweepTablePos));  
    p = plot(RheoSweepSeries.data.load(RheoSweepOn-0.15*RheoSweepSeries.starting_time_rate...
          :RheoSweepOff+0.2*RheoSweepSeries.starting_time_rate));
    p.Color = 'black';
end    

  
title('LP rheo and sag sweep')
xlabel('time (ms)')
box off
if convertCharsToStrings(RheoSweepSeries.data_unit)=="volts" ||...
        convertCharsToStrings(RheoSweepSeries.data_unit)=="Volts"

ylim([-0.115 0.060])
ylabel('Voltage (V)')
else
ylim([-115 60])
ylabel('Voltage (mV)')
end
%% Plotting second subfigure: hero sweep
 

% subplot(2,2,2)
% hold on
% for k = 1:length(a.LP.sweepAmps)
%   if length(IC.hero_amp) == n && a.LP.sweepAmps(k,1)==IC.hero_amp(n,1)
%     p = plot(a.LP.acquireRes(1,k):a.LP.acquireRes(1,k):(plot_stop_LP-plot_onset_LP)*a.LP.acquireRes(1,k), ...
%           a.LP.V{1,k}(plot_onset_LP:plot_stop_LP-1));
%     p.Color = 'black';
%   end
% end
% title('hero sweep')
% ylabel('Voltage (mV)')
% xlabel('time (ms)')
% box off
% ylim([-100 60])

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

