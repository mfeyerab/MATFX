function SubStats = subThresFeatures(CCSers, SubStats, PS,LPfilt)

data = CCSers.data.load();

if checkVolts(CCSers.data_unit) && string(CCSers.description) ~= "PLACEHOLDER"
 data= data*1000;
end

SubStats.SwpAmp(PS.subCount,1) = PS.SwDat.swpAmp;
SubStats.baseVm(PS.subCount,1) = mean(data(1:PS.SwDat.StimOn));                           %does not take into account the testpulse

if PS.SwDat.swpAmp>0
[SubStats.VmHD(PS.subCount,1),SubStats.VmHDTi(PS.subCount,1)] = ...
    max(data(PS.SwDat.StimOn:...
          PS.SwDat.StimOn+PS.WinHD*CCSers.starting_time_rate));
else
[SubStats.VmHD(PS.subCount,1),SubStats.VmHDTi(PS.subCount,1)]  = ...
    min(data(PS.SwDat.StimOn:...
          PS.SwDat.StimOn+PS.WinHD*CCSers.starting_time_rate));
end
%% estimate minimum voltage
SubStats.maxSubDeflection(PS.subCount,1) = ...
    SubStats.VmHD(PS.subCount,1) - SubStats.baseVm(PS.subCount,1);                             
SubStats.VmHDTi(PS.subCount,1) = ...
    SubStats.VmHDTi(PS.subCount,1) + PS.SwDat.StimOn;
%% time constant (rest to minimum V)
if PS.postFilt && length(PS.SwDat.StimOn:SubStats.VmHDTi(PS.subCount,1))>153
   y = filtfilt(LPfilt.sos, LPfilt.ScaleValues, ...
                 data(PS.SwDat.StimOn:SubStats.VmHDTi(PS.subCount,1)));
else
   y =  data(PS.SwDat.StimOn:SubStats.VmHDTi(PS.subCount,1));
end
x = linspace(1,SubStats.VmHDTi(PS.subCount,1)-PS.SwDat.StimOn,length(y))';
if length(y)>=4
     [f,gof] = fit(x,y,'exp1', 'TolFun', 10^(-1020));
    if gof.rsquare < PS.GF
     [f,gof] = fit(x,y,'exp2','Upper', [Inf 0 Inf 0],'TolFun', 10^(-1020));
    end
    temp = .63*(abs(f(1)-f(length(x))));
    vecin = find(f(1:length(x))<(f(1)-temp), 1, 'first');
    if ~isempty(vecin)
        SubStats.tau(PS.subCount,1) = ...
                 round(vecin(1)*1000/CCSers.starting_time_rate,3);
        if PS.plot_all >= 1
            figure('visible','off'); hold on
            IdxVec = PS.SwDat.StimOn-CCSers.starting_time_rate*0.10...
                           :SubStats.VmHDTi(PS.subCount,1);
            plot(data(IdxVec))
            plot(x+CCSers.starting_time_rate*0.10,f(x),'r-.','LineWidth',2)

            title(['GOF=', num2str(gof.rsquare),...
                  ' tau=', num2str(SubStats.tau(PS.subCount,1))])
            scatter(length(IdxVec),y(vecin(1)),'r','filled')
            plot([1,length(IdxVec)], ...
                ones(2)*SubStats.baseVm(PS.subCount,1)+PS.maxDefl,'k')
            F=getframe(gcf);
            imwrite(F.cdata,fullfile(PS.outDest, 'tauFit', ...
                [PS.cellID , '_',PS.SwDat.CurrentName '_tau_fit',PS.pltForm]))
        end
    else
        SubStats.tau(PS.subCount,1) = NaN;
        SubStats.GFtau(PS.subCount,1) = NaN;
    end
    SubStats.GFtau(PS.subCount,1) = gof.rsquare ;
else
   SubStats.tau(PS.subCount,1) = NaN;
   SubStats.GFtau(PS.subCount,1) = NaN;
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
    SubStats.SteadyState(PS.subCount,1) = ...
        PoSS(find(PoSSQ==min(PoSSQ),1,'last'));
else
    SubStats.SteadyState(PS.subCount,1) = NaN;
end    

SubStats.sag(PS.subCount,1) = abs(...
    SubStats.SteadyState(PS.subCount,1)-SubStats.VmHD(PS.subCount,1));
SubStats.sagRat(PS.subCount,1) = (SubStats.VmHD(PS.subCount,1)- ...
 SubStats.baseVm(PS.subCount,1))/ ...
(SubStats.SteadyState(PS.subCount,1)-SubStats.baseVm(PS.subCount,1));

%% rebound slope
[val,loc] = max(CCSers.data.load(PS.SwDat.StimOff:...
  PS.SwDat.StimOff+round(PS.reboundWindow*CCSers.starting_time_rate/1000)));
x = (loc:loc+round(PS.reboundWindow*CCSers.starting_time_rate/1000))-loc;
[f,~] = polyfit(x,data(PS.SwDat.StimOff+loc:...
	PS.SwDat.StimOff+loc+round(PS.reboundWindow*CCSers.starting_time_rate/1000))',1);
SubStats.reboundSlope(PS.subCount,1) = f(1);
SubStats.reboundDepolarization(PS.subCount,1) = abs(...
 CCSers.data.load(PS.SwDat.StimOff+loc)-CCSers.data.load(...
 PS.SwDat.StimOff+loc+round(PS.reboundFitWindow/CCSers.starting_time_rate)));

%% save subthreshold parameters
SubStats.SwpName(PS.subCount,1) = {PS.SwDat.CurrentName};
