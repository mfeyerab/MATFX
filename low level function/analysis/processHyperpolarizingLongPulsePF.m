function subStats = processHyperpolarizingLongPulsePF(protocol,params,qc,k, ...
    cellID,folder,sweepIDcount)

%{
processHyperpolarizingLongPulse
- analysis of subthreshold sweeps
- QC parameters set in processICsweepsParFor
- parameters computed:
    minimum V
    current input
    maximum deflection
    time constant (two different ways)
        - expon fit from rest to minimum
        - expon fit from minimum to steady state
    steady state
    sag
    sag ratio
- finally analysis of rebound spikes
%}

if params.plot_all == 1
    figure('Position',[50 50 1100 250]); set(gcf,'color','w');
    hold on

    plot(protocol.V{1,k},'k')
    xlabel('time-steps')
    ylabel('voltage (mV)')
    axis tight
    box off
end

subStats.subSweepID = k;
subStats.subSweepAmps = protocol.sweepAmps(k,1);

% estimate minimum voltage
[subStats.minV,subStats.minVt] = ...
    min(protocol.V{1,k}(1,protocol.stimOn(1,k):protocol.stimOff(1,k)));
subStats.maxSubDeflection = subStats.minV-qc.restVPre;
subStats.minVt = subStats.minVt+protocol.stimOn(1,k);

% time constant (rest to minimum V)
y = double(protocol.V{1,k}(protocol.stimOn(1,k):subStats.minVt)');
x = double(linspace(1,subStats.minVt-protocol.stimOn(1,k),length(y))');
if length(y)>=4
    [f,gof] = fit(x,y,'exp2');
    if gof.rsquare > 0.75          % Label NaN if rsquared < 0
        if params.plot_all == 1
            plot(x+protocol.stimOn(1,k),f(x),'r-.','LineWidth',2)
        end
        temp = .63*(abs(f(1)-f(length(x))));
        vecin = find(f(1:length(x))<(f(1)-temp), 1, 'first');
        if ~isempty(vecin)
            if params.plot_all == 1
                scatter(vecin(1)+1+protocol.stimOn(1,k),protocol.V{1,k}(protocol.stimOn(1,k))-temp,'r','filled')
            end
            subStats.tauMin = vecin(1)*protocol.acquireRes(1,k);
            subStats.tauMinamp = protocol.sweepAmps(k,1);
            subStats.tauMinGF = 1;
        else
            subStats.tauMinGF = 0;
        end
    else
        subStats.tauMinGF = 0;
    end
end

% sag & sag ratio
subStats.subSteadyState = mean(protocol.V{1,k}(protocol.stimOff(1,k)-round(50/protocol.acquireRes(1,k)):protocol.stimOff(1,k)-1));
subStats.sag = abs(subStats.subSteadyState-subStats.minV);
subStats.sagRatio = subStats.minV/subStats.subSteadyState;

% time constant based on fit between minimum and steady state
y = double(protocol.V{1,k}(subStats.minVt:protocol.stimOff(1,k)-1)');
x = double(linspace(1,protocol.stimOff(1,k)-subStats.minVt,length(y))');
if length(y)>=4
    [f,gof] = fit(x,y,'exp2');
    if gof.rsquare > 0.75          % Label NaN if rsquared < 0
        if params.plot_all == 1
            plot(x+subStats.minVt,f(x),'b-.','LineWidth',2)
        end
        temp = .63*(abs(f(1)-f(length(x))));
        vecin = find(f(1:length(x))>(f(1)+temp), 1, 'first');
        if ~isempty(vecin)
            if params.plot_all == 1
                scatter(vecin(1)+1+subStats.minVt,protocol.V{1,k}(subStats.minVt)+temp,'b','filled')
            end
            subStats.tauSS = vecin(1)*protocol.acquireRes(1,k);
            subStats.tauSSamp = protocol.sweepAmps(k,1);
            subStats.tauSSGF = 1;
        else
            subStats.tauSSGF = 0;
        end
    else
        subStats.tauSSGF = 0;
    end
end

if params.plot_all == 1
    plot((protocol.stimOff(1,k)-round(50/protocol.acquireRes):protocol.stimOff(1,k)-1),...
        protocol.V{1,k}(protocol.stimOff(1,k)-round(50/protocol.acquireRes(1,k)):protocol.stimOff(1,k)-1),'g-.','LineWidth',2)
end

% rebound slope
[val,loc] = max(protocol.V{1,k}(protocol.stimOff(1,k):...
  protocol.stimOff(1,k)+round(params.reboundWindow/protocol.acquireRes(1,k))));
x = (loc:loc+round(params.reboundFitWindow/protocol.acquireRes(1,k)))-loc;
[f,~] = polyfit(x,protocol.V{1,k}(protocol.stimOff(1,k)+loc:...
	protocol.stimOff(1,k)+loc+round(params.reboundFitWindow/protocol.acquireRes(1,k)))',1);
subStats.reboundSlope = f(1);
subStats.reboundDepolarization = abs(protocol.V{1,k}(protocol.stimOff(1,k)+loc)-...
    protocol.V{1,k}(protocol.stimOff(1,k)+loc+round(params.reboundFitWindow/protocol.acquireRes(1,k))));
if params.plot_all == 1
    plot(x+loc+protocol.stimOff(1,k),(f(1)*x+f(2))','c-.','LineWidth',2)
    scatter(loc+protocol.stimOff(1,k),val,'g','filled')
    scatter(round(params.reboundFitWindow/protocol.acquireRes(1,k))+loc+protocol.stimOff(1,k),mean(protocol.V{1,k}(end-(3/protocol.acquireRes(1,k)):end)),'g','filled')

    % save figure
    export_fig([folder(1:length(folder)-8),cellID,' ',int2str(sweepIDcount),' hyperpolarizing parameters'],params.plot_format,'-r100');
    close
end

% rebound spikes
reboundAPTimes = find(protocol.V{1,k}(protocol.stimOff(1,k):...
    protocol.stimOff(1,k)+(params.reboundSpWindow/protocol.acquireRes(1,k)))>=params.thresholdV); 
if ~isempty(reboundAPTimes)                 % if no spikes
    diffPutAPTime = diff(reboundAPTimes);
    rebound2APTimes = [];
    tag = 1;
    dCount = 1;
    for i = 1:length(reboundAPTimes)-1
        if diffPutAPTime(i) ~= 1
            int4Peak{dCount} = reboundAPTimes(tag):reboundAPTimes(i);
            rebound2APTimes(dCount) = reboundAPTimes(tag);
            tag = i+1;
            dCount = dCount + 1;
        end
    end
    int4Peak{dCount} = reboundAPTimes(tag):reboundAPTimes(end);
    rebound2APTimes(dCount) = reboundAPTimes(tag);
    subStats.reboundAPs = rebound2APTimes;
else
    subStats.reboundAPs = NaN;
end
