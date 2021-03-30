function plotQCfailed(protocol,k,cellID,qc,folder,params)
if params.plot_all == 1
    figure('Position',[50 50 600 250]); set(gcf,'color','w');
    hold on
    plot(protocol.V{k,1},'k','LineWidth',0.25)
    xlabel('time-steps')
    ylabel('voltage (mV)')
    title(num2str(qc.logicVec))
    axis tight
    export_fig([folder(1:length(folder)-8),cellID,' ',int2str(k),' qc fail ', protocol.name,' ',num2str(qc.logicVec)],'-pdf','-r100');
    close
end