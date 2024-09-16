function [QC]  = SweepwiseQC(CCSers,PS,QC,SwpCt,LPfilt)
%SweepwiseQC
%- takes two vectors, pre- and post-stimulus (400 ms each)
%- takes two measures of noise, short (1.5 ms) and long (500 ms) term
%- measures resting potential
%- measures difference in resting potential at pre- and post-stimulus
%

data = CCSers.data.load;
SR = CCSers.starting_time_rate;

%% Determining protocol type 
if contains(CCSers.stimulus_description, PS.LPtags) 
    Wind = PS.LPqc_samplWind;
    recvTi = PS.LPqc_recovTime;                         %   
elseif contains(CCSers.stimulus_description, PS.SPtags) 
    Wind = PS.SPqc_samplWind;
    recvTi = PS.SPqc_recovTime;
elseif contains(CCSers.stimulus_description, PS.Noisetags) 
    Wind = PS.Noiseqc_samplWind;
    recvTi = PS.Noiseqc_recovTime;  
else
    disp([PS.SwDat.CurrentName, ' has no identified protocol type', ...
       ' which is called ',CCSers.stimulus_description])
end

%% Getting test pulse onset and saving voltage data
if range(PS.SwDat.StimData)>2
 PS.SwDat.StimData = PS.SwDat.StimData/1000;
end

[PS.SwDat.testOn, QC.testpulse{SwpCt}, QC.params.TP(SwpCt)] = ...
    getTestPulse(PS, CCSers, PS.SwDat.StimData(1:PS.SwDat.StimOn-10));

%% Getting voltage trace at stimulus onset
QC.VStimOn(SwpCt) = {data(PS.SwDat.StimOn-0.0003*SR:...
                         0.002*SR+PS.SwDat.StimOn)};

QC.VStimOff(SwpCt) = {data(PS.SwDat.StimOn-0.0003*SR:...
                       0.002*SR+PS.SwDat.StimOff)};

%% selecting time windows and determining long-term noise/membrane voltage stability    
if checkVolts(CCSers.data_unit) && string(CCSers.description) ~= "PLACEHOLDER"

 vec_pre = data(PS.SwDat.StimOn-Wind*...
           SR:PS.SwDat.StimOn-1).*1000;
      
 if PS.SwDat.StimOff+recvTi*SR+...
           Wind*SR > CCSers.data.dims 
       
       error('Recovery period and/or integration window are too long. Please adjust in loadParams')
 else
     vec_post = data(PS.SwDat.StimOff+recvTi*...
           SR+1:...
           PS.SwDat.StimOff+recvTi*SR+...
           Wind*SR).*1000;
 end
else   
  if PS.SwDat.StimOn < PS.([PS.SwDat.Tag,'qc_samplWind'])*SR
      
    disp(['Sweep Nr ', num2str(CCSers.sweep_number), ...
                         ' has prestimulus length shorter than desired'])
    vec_pre = data(1:PS.SwDat.StimOn);
    
  else
    vec_pre = data(PS.SwDat.StimOn-...
        Wind*SR-1:PS.SwDat.StimOn-1);
  end
  if length(PS.SwDat.StimData)  < PS.SwDat.StimOn + ...
                               PS.([PS.SwDat.Tag,'qc_samplWind'])*SR + ...
                               PS.([PS.SwDat.Tag,'qc_recovTime'])*SR
      
    disp(['Sweep Nr ', num2str(CCSers.sweep_number), ...
                         ' has poststimulus length shorter than desired'])
    vec_post = data(PS.SwDat.StimOff+...
                PS.([PS.SwDat.Tag,'qc_recovTime'])*SR:end);
  else
    vec_post = data(PS.SwDat.StimOff+recvTi*SR+ 1:...
                    PS.SwDat.StimOff+recvTi*SR+ Wind*SR);
  end

end

restVPre = mean(vec_pre);
restVPost = mean(vec_post);
if PS.postFilt && length(vec_post)>153
    temp = filtfilt(LPfilt.sos, LPfilt.ScaleValues, vec_post);
    rmse_post = sqrt(mean((temp - restVPost).^2));
else
    rmse_post = sqrt(mean((vec_post - restVPost).^2));
end
if PS.postFilt && length(vec_pre)>153
  temp = filtfilt(LPfilt.sos, LPfilt.ScaleValues, vec_pre);
  rmse_pre = sqrt(mean((temp - restVPre).^2));
else
   rmse_pre = sqrt(mean((vec_pre - restVPre).^2));
end
diffV_b_e = abs(restVPre-restVPost); % differnce between end and stim onset 
%% Determining short-term noise

stWin = round(1.5*(SR/1000));
winCount = 1;
for i = 1:round(stWin/2):length(vec_pre)-stWin
    yhat = mean(vec_pre(i:i+stWin));
    rmse_pre_st(winCount) = sqrt(mean((vec_pre(i:i+stWin) - yhat).^2));
end
rmse_pre_st = mean(rmse_pre_st);

winCount = 1;
 for i = 1:round(stWin/2):length(vec_post)-stWin
    yhat = mean(vec_post(i:i+stWin));
    rmse_post_st(winCount) = sqrt(mean((vec_post(i:i+stWin) - yhat).^2));
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
  if CCSers.bridge_balance.load >500  
      bridgBal = CCSers.bridge_balance.load/1e6;
  else
      bridgBal = CCSers.bridge_balance.load;
  end
else  
  if CCSers.bridge_balance >500  
      bridgBal = CCSers.bridge_balance/1e6;
  else
      bridgBal = CCSers.bridge_balance;
  end
end

if isempty(CCSers.capacitance_compensation)
  CaComp = NaN;
elseif isa(CCSers.capacitance_compensation,'types.untyped.DataStub')
    
    if CCSers.capacitance_compensation.load <1
      CaComp = CCSers.capacitance_compensation.load*1e12;   
    else
      CaComp = CCSers.capacitance_compensation.load; 
    end
else
    if CCSers.capacitance_compensation <1
      CaComp = CCSers.capacitance_compensation*1e12;
    else 
      CaComp = CCSers.capacitance_compensation;
    end
end

QC.params(SwpCt,3:end-1) = array2table([...
        rmse_pre_st, ...
        rmse_post_st, ...
        rmse_pre, ...
        rmse_post, ...
        diffV_b_e, ...
        restVPre, ...
        holdingI,...
        NaN,...
        bridgBal,...
        CaComp]);

%% determine pass binaries

QC.pass.stRMSE_pre(SwpCt)  = QC.params.stRMSE_pre(SwpCt) < PS.RMSEst;
QC.pass.stRMSE_post(SwpCt) = QC.params.stRMSE_post(SwpCt) < PS.RMSEst;
QC.pass.ltRMSE_pre(SwpCt)  = QC.params.ltRMSE_pre(SwpCt) < PS.RMSElt;
QC.pass.ltRMSE_post(SwpCt) = QC.params.ltRMSE_post(SwpCt) < PS.RMSElt;
QC.pass.diffVrest(SwpCt)   = QC.params.diffVrest(SwpCt) < PS.maxDiffBwBeginEnd;
QC.pass.Vrest(SwpCt)       = QC.params.Vrest(SwpCt) < PS.maxSwpBasLinPot;
QC.pass.holdingI(SwpCt)    = abs(QC.params.holdingI(SwpCt)) < PS.holdingI;

%% Plotting visualizations (Optional)
 if PS.plot_all > 1
  figure('Position',[50 50 250 250],'visible','off'); set(gcf,'color','w');
  hold on
  plot(vec_pre-mean(vec_pre))
  plot(vec_post-mean(vec_pre))
  xlabel('samples')
  ylabel('voltage (mV)')
  axis tight
  ylim([-8 8])
  legend({['pre-stim: RMSE ', num2str(round(rmse_pre,3))], ...
                       ['post-stim: RMSE ', num2str(round(rmse_post,3))]});
  F=getframe(gcf);
  imwrite(F.cdata,fullfile(PS.outDest, 'peristim',[PS.cellID,' ',int2str(SwpCt),...
            ' RMS noise vectors.png']))
 end
end