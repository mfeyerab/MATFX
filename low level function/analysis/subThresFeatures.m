function module_subStats = subThresFeatures(CCSeries, SwData, module_subStats, PS)

subStats.subSweepAmRin = SwData.sweepAmp;

subStats.baselineVm = mean(CCSeries.data.load(1:SwData.StimOn)); 

[subStats.minV,subStats.minVt] = min(...
   CCSeries.data.load(SwData.StimOn:SwData.StimOff));

%% estimate minimum voltage

subStats.maxSubDeflection = subStats.minV - subStats.baselineVm ;                             
subStats.minVt = subStats.minVt+SwData.StimOn;

%% time constant (rest to minimum V)
y = CCSeries.data.load(SwData.StimOn:subStats.minVt)';
x = linspace(1,subStats.minVt-SwData.StimOn,length(y))';
if length(y)>=4
    [f,gof] = fit(x,y,'exp2');
    temp = .63*(abs(f(1)-f(length(x))));
    vecin = find(f(1:length(x))<(f(1)-temp), 1, 'first');
    if ~isempty(vecin)
        if PS.plot_all == 1
            figure('visible','off'); hold on
            plot(CCSeries.data.load(SwData.StimOn-CCSeries.starting_time_rate*0.10:subStats.minVt))
            plot(x+CCSeries.starting_time_rate*0.10,f(x),'r-.','LineWidth',2)
            title(['GOF=', num2str(gof.rsquare)])
            scatter(20000,y(vecin(1)),'r','filled')
            export_fig(fullfile(PS.outDest, 'tauFit',...
                [PS.cellID , '_',SwData.CurrentName '_tau_fit']),PS.pltForm ,'-r100');
        end
        subStats.tauMin = round(vecin(1)*1000/CCSeries.starting_time_rate,3);
    else
        subStats.tauMin = NaN;
    end
else
   subStats.tauMin = NaN;
end
subStats.tauMinGF = gof.rsquare ;
%% sag & sag ratio
sizeSlideWind = 0.075;
TotalSize = 0.5;
Increment = 0.025;

for w = 1:round(TotalSize/Increment)
    vec = ...
      CCSeries.data.load(SwData.StimOff-round((sizeSlideWind + Increment*w) ...
      *CCSeries.starting_time_rate):SwData.StimOff-round(Increment*w*CCSeries.starting_time_rate)-1);
    PoSS(w,1) = mean(vec);
    PoSSQ(w,1) = sqrt(mean((vec - PoSS(w,1)).^2));   
end

if all(PoSSQ) && min(PoSSQ) < 0.75*PS.RMSElt
    subStats.subSteadyState = PoSS(find(PoSSQ==min(PoSSQ)));
else
    subStats.subSteadyState = NaN;
end    

subStats.sag = abs(subStats.subSteadyState-subStats.minV);

subStats.sagRatio = (subStats.minV-subStats.baselineVm)/(subStats.subSteadyState-subStats.baselineVm);

%% rebound slope
[val,loc] = max(CCSeries.data.load(SwData.StimOff:...
  SwData.StimOff+round(PS.reboundWindow*CCSeries.starting_time_rate/1000)));
x = (loc:loc+round(PS.reboundWindow*CCSeries.starting_time_rate/1000))-loc;
[f,~] = polyfit(x,CCSeries.data.load(SwData.StimOff+loc:...
	SwData.StimOff+loc+round(PS.reboundWindow*CCSeries.starting_time_rate/1000))',1);
subStats.reboundSlope = f(1);
subStats.reboundDepolarization = abs(CCSeries.data.load(SwData.StimOff+loc)-...
   CCSeries.data.load(SwData.StimOff+loc+round(PS.reboundFitWindow/CCSeries.starting_time_rate)));
% if PS.plot_all == 1
%     figure; hold on
%     plot(x+loc+SwData.StimOff,(f(1)*x+f(2))','c-.','LineWidth',2)
%     scatter(loc+SwData.StimOff,val,'g','filled')
%     scatter(round(PS.reboundFitWindow/CCSeries.starting_time_rate)...
%         +loc+SwData.StimOff,mean(CCSeries.data.load(end-(3/CCSeries.starting_time_rate):end)),'g','filled')
%   export_fig(fullfile(PS.outDest,[PS.cellID,'_',SwData.CurrentName,...
%       '_rebound']),PS.pltForm ,'-r100');
%     close
% end
%%
if checkVolts(CCSeries.data_unit) && string(CCSeries.description) ~= "PLACEHOLDER"
    subStats.minV  = subStats.minV*1000;  
    subStats.sag = subStats.sag*1000;
    subStats.maxSubDeflection = subStats.maxSubDeflection*1000;
end
%% save subthreshold parameters
subStats = structfun(@double, subStats, 'UniformOutput', false);

if sum(structfun(@numel,subStats)>1) > 0                                   % Filters for uneven structures caused by strange traces
 n=length(fieldnames(subStats));
 fldnames = fieldnames(subStats);
 for k=1:n
   subStats.(fldnames{k})=NaN;
 end
end

table =  array2table(cell2mat(struct2cell(subStats))');
table.Properties.VariableNames = {'SwpAmp','baseVm','minV','minVTime',...
              'maxSubDeflection','tau', 'GFtau','SteadyState',...
             'sag','sagRat','reboundSlp','reboundDepolarization'};

temp_table = util.table2nwb(table, 'subthreshold parameters');
module_subStats.dynamictable.set(SwData.CurrentName, temp_table);

%%

