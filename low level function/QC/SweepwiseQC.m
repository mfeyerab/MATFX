function [QC]  = SweepwiseQC(CCSers,PS,QC,SwpCt)

%{
SweepwiseQC
- takes two vectors, pre- and post-stimulus (400 ms each)
- takes two measures of noise, short (1.5 ms) and long (500 ms) term
- measures resting potential
- measures difference in resting potential at pre- and post-stimulus
%}


%% Getting test pulse onset and saving voltage data
if mean(mean(PS.SwDat.StimData(1:PS.SwDat.StimOn)))-mode(PS.SwDat.StimData) < 0                    % if test pulse is hyperpolarizing 
  [~, PS.SwDat.testOn] = ...
            findpeaks(-diff(PS.SwDat.StimData(1:PS.SwDat.StimOn)),'SortStr','descend','NPeaks',1);
  QC.testpulse(SwpCt) = {CCSers.data.load(PS.SwDat.testOn-...
                         (0.015*CCSers.starting_time_rate):...
                        PS.SwDat.testOn+(0.05*CCSers.starting_time_rate))};
elseif mean(mean(PS.SwDat.StimData(1:PS.SwDat.StimOn)))-mode(PS.SwDat.StimData) > 0                % if test pulse is hyperpolarizing 
   [~, PS.SwDat.testOn] = ...
            findpeaks(diff(PS.SwDat.StimData(1:PS.SwDat.StimOn)),'SortStr','descend','NPeaks',1);
  QC.testpulse(SwpCt) = {CCSers.data.load(PS.SwDat.testOn-...
                         (0.015*CCSers.starting_time_rate):...
                        PS.SwDat.testOn+(0.05*CCSers.starting_time_rate))};
else
    disp([PS.SwDat.CurrentName, ' has no detectable test pulse'])
end

%% selecting time windows and determining long-term noise/membrane voltage stability    
if checkVolts(CCSers.data_unit) && string(CCSers.description) ~= "PLACEHOLDER"

 vec_pre = CCSers.data.load(...
          PS.SwDat.StimOn-0.15*CCSers.starting_time_rate:PS.SwDat.StimOn-1).*1000;
 vec_post = CCSers.data.load((end-0.25*CCSers.starting_time_rate)+1:...
             length(CCSers.data.load)).*1000;
else   
  if PS.SwDat.StimOn < 0.15*CCSers.starting_time_rate
    disp(['Sweep Nr ', num2str(CCSers.sweep_number), ...
                         ' has peristimulus lengths shorter than desired'])
    vec_pre = CCSers.data.load(1:PS.SwDat.StimOn);
    vec_post = CCSers.data.load(PS.SwDat.StimOff:end);
  else 
    vec_pre = CCSers.data.load(...
      PS.SwDat.StimOn-0.15*CCSers.starting_time_rate:PS.SwDat.StimOn-1);
    vec_post = CCSers.data.load((end-0.25*CCSers.starting_time_rate)+1:...
    length(CCSers.data.load));
  end
end

restVPre = mean(vec_pre);
rmse_pre = sqrt(mean((vec_pre - restVPre).^2));
restVPost = mean(vec_post);
rmse_post = sqrt(mean((vec_post - restVPost).^2));
diffV_b_e = abs(restVPre-restVPost); % differnce between end and stim onset 
%% Determining short-term noise

stWin = round(1.5*(CCSers.starting_time_rate/1000));
winCount = 1;
for i = 1:round(stWin/2):length(vec_pre)-stWin
    yhat = mean(vec_pre(1,i:i+stWin));
    rmse_pre_st(winCount) = sqrt(mean((vec_pre(1,i:i+stWin) - yhat).^2));
end
rmse_pre_st = mean(rmse_pre_st);

winCount = 1;
 for i = 1:round(stWin/2):length(vec_post)-stWin
    yhat = mean(vec_post(1,i:i+stWin));
    rmse_post_st(winCount) = sqrt(mean((vec_post(1,i:i+stWin) - yhat).^2));
    winCount = winCount+1;  
 end   

rmse_post_st = mean(rmse_post_st);

%% saving parameters
    
if isempty(CCSers.bias_current)
 holdingI = 0;
elseif  isa(CCSers.bias_current,'types.untyped.DataStub')
 holdingI = CCSers.bias_current.load;
else
 holdingI = CCSers.bias_current;
end 

if isempty(CCSers.bridge_balance)
 bridgBal = 0;
elseif  isa(CCSers.bridge_balance,'types.untyped.DataStub')
 bridgBal = CCSers.bridge_balance.load;
else   
 bridgBal = CCSers.bridge_balance;
end

if isempty(CCSers.capacitance_compensation)
  CaComp = NaN;
elseif isa(CCSers.capacitance_compensation,'types.untyped.DataStub')
    CaComp = CCSers.capacitance_compensation.load;
else
    CaComp = CCSers.capacitance_compensation;
end

QC.params(SwpCt,3:end) = array2table([...
        rmse_pre_st, ...
        rmse_post_st, ...
        rmse_pre, ...
        rmse_post, ...
        diffV_b_e, ...
        restVPre, ...
        holdingI,...
        NaN,...
        bridgBal,...
        NaN,...
        NaN, ...
        CaComp]);

%% determine pass binaries

QC.pass.stRMSE_pre(SwpCt)  = QC.params.stRMSE_pre(SwpCt) < PS.RMSEst;
QC.pass.stRMSE_post(SwpCt) = QC.params.stRMSE_post(SwpCt) < PS.RMSEst;
QC.pass.ltRMSE_pre(SwpCt)  = QC.params.ltRMSE_pre(SwpCt) < PS.RMSElt;
QC.pass.ltRMSE_post(SwpCt) = QC.params.ltRMSE_post(SwpCt) < PS.RMSElt;
QC.pass.diffVrest(SwpCt)   = QC.params.diffVrest(SwpCt) < PS.maxDiffBwBeginEnd;
QC.pass.Vrest(SwpCt)       = QC.params.Vrest(SwpCt) < PS.maximumRestingPot;
QC.pass.holdingI(SwpCt)    = QC.params.holdingI(SwpCt) < PS.holdingI;
QC.pass.bridge_balance_abs(SwpCt) = ...
    QC.params.bridge_balance_abs(SwpCt) < PS.bridge_balance;

    %% Plotting visualizations (Optional)
    if PS.plot_all > 1
        figure('Position',[50 50 250 250],'visible','off'); set(gcf,'color','w');
        hold on
        plot(vec_pre)
        plot(vec_post)
        xlabel('time-steps')
        ylabel('voltage (mV)')
        axis tight
        ylim([-100 -30])
        legend({'pre-stim','post-stim'})
        export_fig(fullfile(params.outDest, 'peristim',[params.cellID,' ',int2str(SwpCt),...
            ' RMS noise vectors']),params.pltForm ,'-r100');
        close
    end
end