function [protocol] = betweenSweepVmQC(protocol,cellID,folder,params)
%{
betweenSweepVmQC
%}
for k = 1:length(protocol.V)                                                    % for each sweep
    rmp(1,k) = protocol.stats{k,1}.qc.restVPre;
    rmp(2,k) = protocol.stats{k,1}.qc.restVPost;
end

protocol.rmp = rmp;

if params.plot_all == 1
    figure('Position',[50 50 300 250]); set(gcf,'color','w');
    plot(protocol.rmp')
    xlabel('sweep #')
    ylabel('resting membrane potential (mV)')
    legend({'pre-stim','post-stim'})
    box off
    axis tight
    ylim([-80 -40])

    % save figure
    export_fig([folder(1:length(folder)-8),cellID,' rmp ', protocol.name],'-pdf','-r100');
    close
end