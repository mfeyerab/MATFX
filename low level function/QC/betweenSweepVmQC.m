function [LP] = betweenSweepVmQC(LP,cellID,folder,params)
%{
betweenSweepVmQC
%}
for k = 1:length(LP.V)                                                    % for each sweep
    rmp(1,k) = LP.stats{k,1}.qc.restVPre;
    rmp(2,k) = LP.stats{k,1}.qc.restVPost;
end

LP.rmp = rmp;

if params.plot_all == 1
    figure('Position',[50 50 300 250]); set(gcf,'color','w');
    plot(LP.rmp')
    xlabel('sweep #')
    ylabel('resting membrane potential (mV)')
    legend({'pre-stim','post-stim'})
    box off
    axis tight
    ylim([-80 -40])

    % save figure
    export_fig([folder(1:length(folder)-8),cellID,' rmp'],'-pdf','-r100');
    close
end