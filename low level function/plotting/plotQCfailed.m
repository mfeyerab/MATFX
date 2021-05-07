function plotQCfailed(LP,k,cellID,qc,folder,params,sweepIDcount)
if params.plot_all == 1
    figure('Position',[50 50 600 250]); set(gcf,'color','w');
    hold on
    plot(LP.V{1,k},'k','LineWidth',0.25)
    xlabel('time-steps')
    ylabel('voltage (mV)')
    title(num2str(qc.logicVec))
    axis tight
    export_fig([folder(1:length(folder)-8),cellID,' ',int2str(sweepIDcount),' qc fail ',num2str(qc.logicVec)],params.plot_format,'-r100');
    close
end