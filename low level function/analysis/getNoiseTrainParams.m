function NoiseSpPattrn = getNoiseTrainParams(CCSers , sp, PS, NoiseSpPattrn)

NoiseSpPattrn.spTrain.StimName1(PS.NoiseCount,1) = {CCSers.stimulus_description};
NoiseSpPattrn.spTrain.StimName2(PS.NoiseCount,1) = {CCSers.stimulus_description};
NoiseSpPattrn.spTrain.StimName3(PS.NoiseCount,1) = {CCSers.stimulus_description};
NoiseSpPattrn.spTrain.SwpNr1(PS.NoiseCount,1) = CCSers.sweep_number;
NoiseSpPattrn.spTrain.SwpNr2(PS.NoiseCount,1) = CCSers.sweep_number;
NoiseSpPattrn.spTrain.SwpNr3(PS.NoiseCount,1) = CCSers.sweep_number;

%% plotting all spikes for sanity check
figure('Visible','off'); t = tiledlayout(1,2);
nexttile; hold on
for s = 1:length(sp.thresholdTime)
plot(CCSers.data.load(sp.thresholdTime(s)-...
                        0.25/(1000/CCSers.starting_time_rate):...
                      sp.thresholdTime(s) + ...
                        2.75/(1000/CCSers.starting_time_rate)))
end
title("aligned by threshold")

nexttile; hold on
for s = 1:length(sp.peakTime)
plot(CCSers.data.load(sp.peakTime(s)-...
                        1/(1000/CCSers.starting_time_rate):...
                      sp.peakTime(s) + ...
                        2/(1000/CCSers.starting_time_rate)))
title("aligned by peak")
title(t,'AP Variability Sweep Nr', num2str(CCSers.sweep_number))
end
F=getframe(gcf);
      imwrite(F.cdata,fullfile(PS.outDest, 'Noise', ...
                                  [PS.cellID,' ',PS.SwDat.CurrentName,...
            ' AP_Variability.png']))
%% plotting sweep for sanity check
figure('Visible','off','Position',[7 458 1629 420]); hold on
tvec = sp.thresholdTime(1)-...
                        50/(1000/CCSers.starting_time_rate):...
                        sp.thresholdTime(end)+ ...
                        2/(1000/CCSers.starting_time_rate);

tvec = [1:length(tvec)].*(1000/CCSers.starting_time_rate);

plot(tvec, ...
    CCSers.data.load(sp.thresholdTime(1)-...
                        50/(1000/CCSers.starting_time_rate):...
                        sp.thresholdTime(end)+ ...
                        2/(1000/CCSers.starting_time_rate)))
scatter(tvec(sp.peakTime - sp.thresholdTime(1)+ ...
    50/(1000/CCSers.starting_time_rate) )...
    , ones(length(sp.peakTime),1)*min(CCSers.data.load))
F=getframe(gcf);
      imwrite(F.cdata,fullfile(PS.outDest, 'Noise', ...
                                  [PS.cellID,' ',PS.SwDat.CurrentName,...
            ' AP_Detection.png']))
%% ISI analysis

ISIs = diff(sp.peakTime)*(1000/CCSers.starting_time_rate);
StimGap = find(ISIs > 3000);
if length(StimGap)==1
  NoiseSpPattrn.spTrain.CV1(PS.NoiseCount,1) = NaN;
  NoiseSpPattrn.spTrain.FR1(PS.NoiseCount,1) = NaN;
  NoiseSpPattrn.spTrain.FR2(PS.NoiseCount,1) = (StimGap-1)/3;
  NoiseSpPattrn.spTrain.CV2(PS.NoiseCount,1) = ...
      mean(ISIs(1:StimGap-1))/std(ISIs(1:StimGap-1));
  NoiseSpPattrn.spTrain.CV3(PS.NoiseCount,1) = ...
      mean(ISIs(StimGap+1:end))/std(ISIs(StimGap+1:end));
  NoiseSpPattrn.spTrain.FR3(PS.NoiseCount,1) = (length(ISIs)-StimGap)/3;

elseif length(StimGap)==2
  NoiseSpPattrn.spTrain.CV1(PS.NoiseCount,1) = ...
      mean(ISIs(1:StimGap(1)-1))/std(ISIs(1:StimGap(1)-1));
  NoiseSpPattrn.spTrain.FR1(PS.NoiseCount,1) = (StimGap(1)-1)/3;
  NoiseSpPattrn.spTrain.CV2(PS.NoiseCount,1) = ...
                    mean(ISIs(StimGap(1)+1:StimGap(2)-1))/...
                     std(ISIs(StimGap(1)+1:StimGap(2)-1));
  NoiseSpPattrn.spTrain.FR2(PS.NoiseCount,1) = ...
      length(ISIs(StimGap(1)+1:StimGap(2)))/3;
  NoiseSpPattrn.spTrain.CV3(PS.NoiseCount,1) = ...
      mean(ISIs(StimGap(2)+1:end))/std(ISIs(StimGap(2)+1:end));
  NoiseSpPattrn.spTrain.FR3(PS.NoiseCount,1) = ...
      length(ISIs(StimGap(2)+1:end))/3;
else
  NoiseSpPattrn.spTrain.CV1(PS.NoiseCount,1) = NaN;
  NoiseSpPattrn.spTrain.FR1(PS.NoiseCount,1) = NaN;
  NoiseSpPattrn.spTrain.FR2(PS.NoiseCount,1) = NaN;
  NoiseSpPattrn.spTrain.CV2(PS.NoiseCount,1) = NaN;
  NoiseSpPattrn.spTrain.CV3(PS.NoiseCount,1) = mean(ISIs)/std(ISIs);
  NoiseSpPattrn.spTrain.FR3(PS.NoiseCount,1) = (length(ISIs)+1)/3;
end

ISIs(StimGap) = [];
NoiseSpPattrn.ISIs{1,PS.NoiseCount} = ISIs;
