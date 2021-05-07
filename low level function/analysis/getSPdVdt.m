function protocol = getSPdVdt(protocol,k,thresholdDVDT,cellID,folder,params,sweepIDcount)

%{
getSPdVdt
%}

% upsample V to 50 kHz
x = double(protocol.V{1,k});                                                  % double precision
dVdt = diff(x)/(1000/5e4);              % dV/dt at 50 kHz

if params.plot_all == 1
    figure('Position',[50 50 600 400]); set(gcf,'color','w');
    subplot(2,1,1)
    plot(x,'k')
    xlabel('time')
    ylabel('voltage (mV)')
    axis tight
    box off
    subplot(2,1,2)
    hold on
    plot([1 length(dVdt)],[thresholdDVDT,thresholdDVDT],'r')
    plot(dVdt,'k')
    xlabel('time')
    ylabel('dV/dt (mV/ms)')
    axis tight
    ylim([0 300])
    box off
    export_fig([folder(1:length(folder)-8),cellID,' ',int2str(sweepIDcount),' no spikes'],params.plot_format,'-r100');
    close
end

% tempSP = find(dVdt > (20/protocol.acquireRes));
% c = 1;
% for j = 1:length(tempSP)-1
%     if sum(dVdt(1,tempSP(j):putSP.dVdttempSP(j+1)) < 0) > 0
%         putSP.dVdt(c) = putSP.dVdt(j);
%         c = c + 1;
%     end
% end
% clear c j
% >20mV/ms and returns below 0mV/ms between events