%{
plot characterization
%}
plot_onset_LP = a.LP.stimOn(1,1)-(100/a.LP.acquireRes(1,1));
plot_stop_LP = a.LP.stimOff(1,1)+(200/a.LP.acquireRes(1,1));

figure('Position',[50 50 750 750]); set(gcf,'color','w');
subplot(2,2,1)
hold on
for k = 1:length(a.LP.sweepAmps)
  if length(IC.subamp) == n && a.LP.sweepAmps(k,1)==IC.subamp(n,1)  && ...
          sum(a.LP.stats{k, 1}.qc.logicVec)==0  
    p = plot(a.LP.acquireRes(1,k):a.LP.acquireRes(1,k):(plot_stop_LP-plot_onset_LP)*a.LP.acquireRes(1,k), ...
          a.LP.V{1,k}(plot_onset_LP:plot_stop_LP-1));
    p.Color = 'black';
  end  
  if length(IC.rheobaseLP) == n && a.LP.sweepAmps(k,1) >= IC.rheobaseLP(n,1) -10 && ...
        a.LP.sweepAmps(k,1) <= IC.rheobaseLP(n,1) + 5 && ... 
       isfield(a.LP.stats{k,1},'spTimes') ...
       && any(~isnan(a.LP.stats{k, 1}.peak)) &&...
       sum(a.LP.stats{k, 1}.qc.logicVec)==0 
   
    p = plot(a.LP.acquireRes(1,k):a.LP.acquireRes(1,k):(plot_stop_LP-plot_onset_LP)*a.LP.acquireRes(1,k), ...
          a.LP.V{1,k}(plot_onset_LP:plot_stop_LP-1));
    p.Color = 'black';
  end
end
title('LP rheo and sag sweep')
xlabel('time (ms)')
ylabel('Voltage (mV)')
box off
ylim([-100 60])



subplot(2,2,2)
hold on
for k = 1:length(a.LP.sweepAmps)
  if length(IC.hero_amp) == n && a.LP.sweepAmps(k,1)==IC.hero_amp(n,1)
    p = plot(a.LP.acquireRes(1,k):a.LP.acquireRes(1,k):(plot_stop_LP-plot_onset_LP)*a.LP.acquireRes(1,k), ...
          a.LP.V{1,k}(plot_onset_LP:plot_stop_LP-1));
    p.Color = 'black';
  end
end
title('hero sweep')
ylabel('Voltage (mV)')
xlabel('time (ms)')
box off
ylim([-100 60])

subplot(2,2,3)
hold on
if size(IC.wfLP,1) == n
 p = plot(a.LP.acquireRes(1,k):a.LP.acquireRes(1,k):a.LP.acquireRes(1,k)*226,IC.wfLP(n,:));
 p.Color = 'black';
end
if size(IC.wfSP,1) == n 
 p = plot(a.SP.acquireRes(1,1):a.SP.acquireRes(1,1):a.SP.acquireRes(1,1)*226,...
     IC.wfSP(n,:));
 p.Color = 'red';
 legend('boxoff')
 legend('LP','SP')
end
title('Waveform SP vs LP')
ylabel('Voltage (mV)')
xlabel('time (ms)')
box off
ylim([-70 60])


subplot(2,2,4)
hold on
if size(IC.wfLP,1) == n
 p = plot(IC.wfLP(n,2:end),diff(IC.wfLP(n,:))/a.LP.acquireRes(1,k));
 p.Color = 'black';
end
if size(IC.wfSP,1) == n 
 p = plot(IC.wfSP(n,2:end),diff(IC.wfSP(n,:))/a.SP.acquireRes(1,1));
 p.Color = 'red';
 legend('boxoff')
 legend('LP','SP')
end
title('Waveform SP vs LP')
ylabel('dV/dt (mV/ms)')
xlabel('Voltage (mV)')
box off
xlim([-60 60])
ylim([-500 900])

export_fig([save_path, cellID,' Cell profile', date],plot_format,'-r100');
close

