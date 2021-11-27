function plotQCdDepolarizing(protocol,sp,k,cellID,folder,params,sweepIDcount)

%{
plotSuprathreshold
%}

if params.plot_all == 1
    figure('Position',[50 50 1500 250]); set(gcf,'color','w');
    subplot(1,4,1:3)
    hold on
    plot(protocol.V{1,k},'k','LineWidth',0.25)
    plot(sp.peakTime,protocol.V{1,k}(sp.peakTime),'.r','markersize',16)
    plot(sp.maxdVdtTime,protocol.V{1,k}(sp.maxdVdtTime),'.c','markersize',16)                     % plot max dV/dt
    plot(sp.thresholdTime,protocol.V{1,k}(sp.thresholdTime),'.g','markersize',16)                % threshold
    plot(sp.thresholdRefTime,protocol.V{1,k}(sp.thresholdRefTime),'.g','markersize',10)          % refined threshold
    plot(sp.troughTime,protocol.V{1,k}(sp.troughTime),'.b','markersize',16)                         % trough
    plot(sp.halfHeightTimeUpPT,protocol.V{1,k}(sp.halfHeightTimeUpPT),'.k','markersize',16)      % half height time up
    plot(sp.halfHeightTimeDownPT,protocol.V{1,k}(sp.halfHeightTimeDownPT),'.k','markersize',16)  % half height time down
    plot(sp.halfHeightTimeUpTP,protocol.V{1,k}(sp.halfHeightTimeUpTP),'.y','markersize',16)      % half height time up
    plot(sp.halfHeightTimeDownTP,protocol.V{1,k}(sp.halfHeightTimeDownTP),'.y','markersize',16)  % half height time down
    xlabel('time-steps')
    ylabel('voltage (mV)')
    axis tight

    subplot(1,4,4)
    hold on
    plot(protocol.V{1,k},'k','LineWidth',0.25)
    plot(sp.peakTime,protocol.V{1,k}(sp.peakTime),'.r','markersize',16)
    plot(sp.maxdVdtTime,protocol.V{1,k}(sp.maxdVdtTime),'.c','markersize',16)                       % plot max dV/dt
    plot(sp.thresholdTime,protocol.V{1,k}(sp.thresholdTime),'.g','markersize',16)                   % threshold
    plot(sp.thresholdRefTime,protocol.V{1,k}(sp.thresholdRefTime),'.g','markersize',10)             % refined threshold
    plot(sp.troughTime,protocol.V{1,k}(sp.troughTime),'.b','markersize',16)                         % trough
    plot(sp.halfHeightTimeUpPT,protocol.V{1,k}(sp.halfHeightTimeUpPT),'.k','markersize',16)         % half height time up
    plot(sp.halfHeightTimeDownPT,protocol.V{1,k}(sp.halfHeightTimeDownPT),'.k','markersize',16)     % half height time down
    plot(sp.halfHeightTimeUpTP,protocol.V{1,k}(sp.halfHeightTimeUpTP),'.y','markersize',16)         % half height time up
    plot(sp.halfHeightTimeDownTP,protocol.V{1,k}(sp.halfHeightTimeDownTP),'.y','markersize',16)     % half height time down
    xlabel('time-steps')
    ylabel('voltage (mV)')
    axis tight
    xlim([sp.peakTime(1)-(2/protocol.acquireRes) sp.troughTime(1)+(2/protocol.acquireRes)])

    % save figure
    export_fig(fullfile(folder(1:length(folder)-8),[cellID,' ',int2str(sweepIDcount),' spiking parameters']),params.plot_format,'-r100');
    close
end