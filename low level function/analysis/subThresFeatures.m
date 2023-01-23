function modSubStats = subThresFeatures(CCSers, modSubStats, PS,LPfilt)

data = CCSers.data.load();

if checkVolts(CCSers.data_unit) && string(CCSers.description) ~= "PLACEHOLDER"
 data= data*1000;
end

subStats.subSweepAmRin = PS.SwDat.swpAmp;
subStats.baselineVm = mean(data(1:PS.SwDat.StimOn));                       %does not take into account the testpulse
if PS.SwDat.swpAmp>0
[subStats.VmHD,subStats.VmHDt] = max(...
   data(PS.SwDat.StimOn:PS.SwDat.StimOn+PS.WinHD*CCSers.starting_time_rate));
else
[subStats.VmHD,subStats.VmHDt] = min(...
   data(PS.SwDat.StimOn:PS.SwDat.StimOn+PS.WinHD*CCSers.starting_time_rate));
end
%% estimate minimum voltage
subStats.maxSubDeflection = subStats.VmHD - subStats.baselineVm ;                             
subStats.VmHDt = subStats.VmHDt+PS.SwDat.StimOn;
%% time constant (rest to minimum V)
if PS.postFilt && length(PS.SwDat.StimOn:subStats.VmHDt)>153
   y = filtfilt(LPfilt.sos, LPfilt.ScaleValues, ...
                 data(PS.SwDat.StimOn:subStats.VmHDt));
else
   y =  data(PS.SwDat.StimOn:subStats.VmHDt);
end
x = linspace(1,subStats.VmHDt-PS.SwDat.StimOn,length(y))';
if length(y)>=4
    [f,gof] = fit(x,y,'exp2');
    temp = .63*(abs(f(1)-f(length(x))));
    vecin = find(f(1:length(x))<(f(1)-temp), 1, 'first');
    if ~isempty(vecin)
        subStats.tauMin = round(vecin(1)*1000/CCSers.starting_time_rate,3);
        if PS.plot_all >= 1
            figure('visible','off'); hold on
            IdxVec = PS.SwDat.StimOn-CCSers.starting_time_rate*0.10...
                           :subStats.VmHDt;
            plot(data(IdxVec))
            plot(x+CCSers.starting_time_rate*0.10,f(x),'r-.','LineWidth',2)
            title(['GOF=', num2str(gof.rsquare),...
                                        ' tau=', num2str(subStats.tauMin)])
            scatter(length(IdxVec),y(vecin(1)),'r','filled')
            plot([1,length(IdxVec)], ...
                ones(2)*subStats.baselineVm+PS.maxDefl,'k')
            F=getframe(gcf);
            imwrite(F.cdata,fullfile(PS.outDest, 'tauFit', ...
                [PS.cellID , '_',PS.SwDat.CurrentName '_tau_fit',PS.pltForm]))
        end
    else
        subStats.tauMin = NaN;
        subStats.tauMinGF = NaN;
    end
    subStats.tauMinGF = gof.rsquare ;
else
   subStats.tauMin = NaN;
   subStats.tauMinGF = NaN;
end
%% sag & sag ratio
sizeSlideWind = 0.075;
TotalSize = 0.5;
Increment = 0.025;

for w = 1:round(TotalSize/Increment)
    vec = ...
      data(PS.SwDat.StimOff-round((sizeSlideWind + Increment*w) ...
      *CCSers.starting_time_rate):PS.SwDat.StimOff-round(Increment*w*CCSers.starting_time_rate)-1);
    PoSS(w,1) = mean(vec);
    PoSSQ(w,1) = sqrt(mean((vec - PoSS(w,1)).^2));   
end

if all(PoSSQ) && min(PoSSQ) < 0.75*PS.RMSElt
    subStats.subSteadyState = PoSS(find(PoSSQ==min(PoSSQ)));
else
    subStats.subSteadyState = NaN;
end    

subStats.sag = abs(subStats.subSteadyState-subStats.VmHD);
subStats.sagRatio = (subStats.VmHD-subStats.baselineVm)/(subStats.subSteadyState-subStats.baselineVm);

%% rebound slope
[val,loc] = max(CCSers.data.load(PS.SwDat.StimOff:...
  PS.SwDat.StimOff+round(PS.reboundWindow*CCSers.starting_time_rate/1000)));
x = (loc:loc+round(PS.reboundWindow*CCSers.starting_time_rate/1000))-loc;
[f,~] = polyfit(x,data(PS.SwDat.StimOff+loc:...
	PS.SwDat.StimOff+loc+round(PS.reboundWindow*CCSers.starting_time_rate/1000))',1);
subStats.reboundSlope = f(1);
subStats.reboundDepolarization = abs(CCSers.data.load(PS.SwDat.StimOff+loc)-...
   CCSers.data.load(PS.SwDat.StimOff+loc+round(PS.reboundFitWindow/CCSers.starting_time_rate)));

%% save subthreshold parameters
subStats = structfun(@double, subStats, 'UniformOutput', false);

if sum(structfun(@numel,subStats)>1) > 0                                   % Filters for uneven structures caused by strange traces
 n=length(fieldnames(subStats));
 fldnames = fieldnames(subStats);
 for k=1:n
   subStats.(fldnames{k})=NaN;
 end
end

table = array2table(cell2mat(struct2cell(subStats))');
table.Properties.VariableNames = {'SwpAmp','baseVm','VmHD','VmHDTime',...
              'maxSubDeflection','tau', 'GFtau','SteadyState', 'sag',...
              'sagRat','reboundSlp','reboundDepolarization'};
table.SwpName = string(PS.SwDat.CurrentName);

if isempty(modSubStats.dynamictable.values)
    temp_table = util.table2nwb(table, 'subthreshold parameters');
    modSubStats.dynamictable.set('All Values',temp_table);
else
    addRow(modSubStats.dynamictable.values{1},...
    'SwpAmp',table.SwpAmp,'baseVm',table.baseVm,'VmHD',table.VmHD,...
    'VmHDTime',table.VmHDTime,'maxSubDeflection',table.maxSubDeflection,...
    'tau',table.tau, 'GFtau',table.GFtau,'SteadyState',table.SteadyState, ...
    'sag',table.sag,'sagRat',table.sagRat,'reboundSlp',table.reboundSlp,...
    'reboundDepolarization',table.reboundDepolarization, 'SwpName',  string(PS.SwDat.CurrentName))
end

