function module_subStats = subThresFeatures(CCSeries,StimOn, StimOff, ...
                                     sweepAmp, CurrentName, module_subStats, params, QC_parameter)

subStats.subSweepAmps = sweepAmp;

[subStats.minV,subStats.minVt] = min(...
   CCSeries.data.load(StimOn:StimOff));

%% estimate minimum voltage

subStats.maxSubDeflection = subStats.minV -...
                                 mean(CCSeries.data.load(1:StimOn)) ;
subStats.minVt = subStats.minVt+StimOn;

%% time constant (rest to minimum V)
y = double(CCSeries.data.load(StimOn:subStats.minVt)');
x = double(linspace(1,subStats.minVt-StimOn,length(y))');
if length(y)>=4
    [f,gof] = fit(x,y,'exp2');
    if gof.rsquare > 0.75          % Label NaN if rsquared < 0
        if params.plot_all == 1
            plot(x+StimOn*1000/CCSeries.starting_time_rate,f(x),'r-.','LineWidth',2)
            hold on
        end
        temp = .63*(abs(f(1)-f(length(x))));
        vecin = find(f(1:length(x))<(f(1)-temp), 1, 'first');
        if ~isempty(vecin)
            if params.plot_all == 1
                scatter(vecin(1)+1+StimOn,CCSeries.data.load(StimOn)-temp,'r','filled')
            end
            subStats.tauMin = round(vecin(1)*1000/CCSeries.starting_time_rate,3);
            subStats.tauMinGF = 1;
        else
            subStats.tauMinGF = 0;
            subStats.tauMin = NaN;
        end
    else
        subStats.tauMinGF = 0;
        subStats.tauMin = NaN;
    end
else
        subStats.tauMinGF = 0;
        subStats.tauMin = NaN;
end
%% sag & sag ratio
sizeSlideWind = 0.075;
TotalSize = 0.5;
Increment = 0.025;

for w = 1:round(TotalSize/Increment)
    vec = ...
      CCSeries.data.load(StimOff-round((sizeSlideWind + Increment*w) ...
      *CCSeries.starting_time_rate):StimOff-round(Increment*w*CCSeries.starting_time_rate)-1);
    PoSS(w,1) = mean(vec);
    PoSSQ(w,1) = sqrt(mean((vec - PoSS(w,1)).^2));   
end

if min(PoSSQ) < 0.75*params.RMSElt
    subStats.subSteadyState = PoSS(find(PoSSQ==min(PoSSQ)));
else
    subStats.subSteadyState = NaN;
end    
subStats.sag = abs(subStats.subSteadyState-subStats.minV);
subStats.sagRatio = subStats.minV/subStats.subSteadyState;

%% rebound slope
[val,loc] = max(CCSeries.data.load(StimOff:...
  StimOff+round(params.reboundWindow*CCSeries.starting_time_rate/1000)));
x = (loc:loc+round(params.reboundWindow*CCSeries.starting_time_rate/1000))-loc;
[f,~] = polyfit(x,CCSeries.data.load(StimOff+loc:...
	StimOff+loc+round(params.reboundWindow*CCSeries.starting_time_rate/1000))',1);
subStats.reboundSlope = f(1);
subStats.reboundDepolarization = abs(CCSeries.data.load(StimOff+loc)-...
   CCSeries.data.load(StimOff+loc+round(params.reboundFitWindow/CCSeries.starting_time_rate)));
%%

if checkVolts(CCSeries.data_unit)
    
    subStats.minV  = subStats.minV*1000;  
    subStats.sag = subStats.sag*1000;
    subStats.maxSubDeflection = subStats.maxSubDeflection*1000;
end

%% save subthreshold parameters
subStats = structfun(@double, subStats, 'UniformOutput', false);
table =  array2table(cell2mat(struct2cell(subStats))');
table.Properties.VariableNames = {'SweepAmp','minV','minVTime',...
              'maxSubDeflection','tauMin', 'tauMinGF','SteadyState',...
             'sag','sagRatio','reboundSlope','reboundDepolarization'};

table = table2nwb(table, 'subthreshold parameters');

module_subStats.dynamictable.set(CurrentName, table);

%%

if params.plot_all == 1
    plot(x+loc+StimOff,(f(1)*x+f(2))','c-.','LineWidth',2)
    scatter(loc+StimOff,val,'g','filled')
    scatter(round(params.reboundFitWindow/CCSeries.starting_time_rate)+loc+StimOff,mean(CCSeries.data.load(end-(3/CCSeries.starting_time_rate):end)),'g','filled')

%     % save figure
%     export_fig([folder(1:length(folder)-8),cellID,' ',int2str(sweepIDcount),' hyperpolarizing parameters'],params.plot_format,'-r100');
    close
end