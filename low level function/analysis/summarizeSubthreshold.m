function b = summarizeSubthreshold(LP,cellID,folder,params)
if params.plot_all == 1
    figure('Position',[50 50 900 250]); set(gcf,'color','w');
end
if isfield(LP,'stats')
    ind = find(LP.sweepAmps < 0);

    % resistance
    count = 1;
    for i = 1:length(ind)
        num = ind(i);
        if LP.sweepAmps(num,1)>-100 && length(LP.stats)>num && isfield(LP.stats{num,1},'tauMinGF') && LP.stats{num,1}.tauMinGF == 1
            x(count) = LP.stats{num,1}.subSweepAmps;
            y(count) = LP.stats{num,1}.minV;
            count = count + 1;
        end
    end
    if exist('y','var') && length(y)>1
        f = polyfit(x,y,1);
        resistance = f(1) * (10^3);
        if params.plot_all == 1
            subplot(1,3,1)
            hold on
            plot(x,(f(1)*x+f(2))','k','LineWidth',1)
            scatter(x,y,'r')
            legend('off')
            xlabel('input current (pA)')
            ylabel('membrane potential (mV)')
            title('V/I curve')
            box off
            axis tight
        end
    else
        resistance = NaN;
    end
    clear x y f


    % time constant (rest -> min)
    count = 1;
    for i = 1:length(ind)
        num = ind(i);
        if LP.sweepAmps(num,1)>-100 && length(LP.stats)>num && ~isempty(LP.stats{num,1}) && isfield(LP.stats{num,1},'tauMin')
            y(count) = LP.stats{num,1}.tauMin;
            x(count) = LP.sweepAmps(num,1);
            count = count + 1;
        end
    end
    if exist('y','var') && length(y)>1
        f = polyfit(x,y,1);
        tauMin = mean(y);
        if params.plot_all == 1
            subplot(1,3,2)
            hold on
            plot(x,(f(1)*x+f(2))','k','LineWidth',1)
            scatter(x,y,'r')
            legend('off')
            xlabel('input current (pA)')
            ylabel('membrane potential (mV)')
            title('tau (rest-to-min)')
            box off
            axis tight
            ylim([0 100])
        end
    else
        tauMin = NaN;
    end
    clear x y f


    % time constant (min -> ss)
    count = 1;
    for i = 1:length(ind)
        num = ind(i);
        if LP.sweepAmps(num,1)>-100 && length(LP.stats)>num && ~isempty(LP.stats{num,1}) && isfield(LP.stats{num,1},'tauSS')
            y(count) = LP.stats{num,1}.tauSS;
            x(count) = LP.sweepAmps(num,1);
            count = count + 1;
        end
    end
    if exist('y','var') && length(y)>1
        tauSS = mean(y);
        f = polyfit(x,y,1);
        if params.plot_all == 1
            subplot(1,3,3)
            hold on
            plot(x,(f(1)*x+f(2))','k','LineWidth',1)
            scatter(x,y,'r')
            legend('off')
            xlabel('input current (pA)')
            ylabel('membrane potential (mV)')
            title('tau (min-to-steady)')
            box off
            axis tight
        %     ylim([0 100])
        end
    else
        tauSS = NaN;
    end

    b.resistance = resistance;
    b.tauMin = tauMin;
    b.tauSS = tauSS;
else
    b.resistance = NaN;
    b.tauMin = NaN;
    b.tauSS = NaN;
end
if params.plot_all == 1
    export_fig([folder(1:length(folder)-8),cellID,' subthreshold summary'],params.plot_format,'-r100');
    close
end