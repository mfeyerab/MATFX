function protocol = getSPdVdt(protocol,k,thresholdDVDT,cellID,folder,params)

%{
getSPdVdt
%}

% upsample V to 50 kHz
x = double(protocol.V{k,1});                                                  % double precision
prePad = x(1)+zeros(1,100); postPad = x(end)+zeros(1,100);              % generate pads
x = [prePad,x,postPad];                                                 % pad vector
x = resample(x,5e4,round(double(1000/protocol.acquireRes)));      % resample
if round(double(1000/protocol.acquireRes)) == 1e4                           % remove pad 10kHz
    x = x(501:end-500); % length==315
elseif round(double(1000/protocol.acquireRes)) == 2e4                       % remove pad 20 kHz
    x = x(251:end-250); % length==313
elseif round(double(1000/protocol.acquireRes)) == 2e5                      % remove pad 200 kHz
    x = x(25:end-25); % length==312
end
x = single(x);


% smooth w filter?
% output = smoothdata(dVdt,'gaussian',15,'SamplePoints',1:length(dVdt));

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
    ylim([0 30])
    box off
    export_fig([folder(1:length(folder)-8),cellID,' ',int2str(k),' no spikes ', protocol.name],'-pdf','-r100');
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