function NoiseSpPattrn = getNoiseTrainParams(StimSers, CCSers , PS, NoiseSpPattrn)

data = CCSers.data.load(find(StimSers.data.load~=0));
Stimdata = StimSers.data.load(find(StimSers.data.load~=0));

if checkVolts(CCSers.data_unit) && string(CCSers.description) ~= "PLACEHOLDER"
 supraEvents = find(data>=PS.thresholdV/1000);
else 
 supraEvents = find(data>=PS.thresholdV);
end

if ~isempty(supraEvents)
    [int4Peak,startPotSp] = int4APs(supraEvents, PS);
    sp = estimatePeak(startPotSp,int4Peak,data);
    if ~isempty(sp)
             sp = getSpikeParameter(data, sp, PS);
    end
end

%%
figure('Visible','on'); hold on
NrSp = length(sp.threshold);
PreSp = 0.2*CCSers.starting_time_rate;
STAmat = nan(PreSp,NrSp);
for s = 1:NrSp
STAmat(:,s) = Stimdata(sp.thresholdTime(s)-PreSp:sp.thresholdTime(s)-1);
end
title('STA 200 ms before threshold')
plot(STAmat,'k')
plot(mean(STAmat'),'LineWidth',3)

F=getframe(gcf);
      imwrite(F.cdata,fullfile(PS.outDest, 'Noise', ...
                                  [PS.cellID,' ',PS.SwDat.CurrentName,...
            ' STA.png']))

%% plotting all spikes for sanity check
figure('Visible','on'); t = tiledlayout(1,2);
nexttile; hold on
SpTi = sp.thresholdTime;

for s = 1:length(SpTi)
plot(data(SpTi(s)- (0.00025*CCSers.starting_time_rate):...
                      SpTi(s) + (0.00275*CCSers.starting_time_rate)))
end
title("aligned by threshold")

PeakTi = sp.peakTime;
nexttile; hold on
for s = 1:length(PeakTi)
plot(data(PeakTi(s)-(0.001*CCSers.starting_time_rate):...
                      PeakTi(s) + 0.002*CCSers.starting_time_rate))
title("aligned by peak")
title(t,'AP Variability Sweep Nr', num2str(CCSers.sweep_number))
end
F=getframe(gcf);
      imwrite(F.cdata,fullfile(PS.outDest, 'Noise', ...
                                  [PS.cellID,' ',PS.SwDat.CurrentName,...
            ' AP_Variability.png']))
%% plotting sweep for sanity check
figure('Visible','on','Position',[7 458 1629 420]); hold on
tvec = SpTi(1)-50/(1000/CCSers.starting_time_rate):...
       SpTi(end)+ 2/(1000/CCSers.starting_time_rate);

tvec = [1:length(tvec)].*(1000/CCSers.starting_time_rate);

plot(tvec, ...
    data(SpTi(1)-50/(1000/CCSers.starting_time_rate):...
                     SpTi(end)+ 2/(1000/CCSers.starting_time_rate)))
scatter(tvec(PeakTi - SpTi(1)+ 50/(1000/CCSers.starting_time_rate) )...
    , ones(length(PeakTi),1)*min(CCSers.data.load))
F=getframe(gcf);
      imwrite(F.cdata,fullfile(PS.outDest, 'Noise', ...
                                  [PS.cellID,' ',PS.SwDat.CurrentName,...
            ' AP_Detection.png']))
%% ISI analysis

ISIs = diff(PeakTi)*(1000/CCSers.starting_time_rate);
NoiseSpPattrn.ISIs{1,PS.NoiseCount} = ISIs;
