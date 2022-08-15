<<<<<<< Updated upstream
function [QC_parameter, QC_pass]  = SweepwiseQC(CCSeries, SwData, SweepCount, QC_parameter, QC_pass, params)
=======
function [QC]  = SweepwiseQC(CCSers,PS,QC,SwpCt)
%SweepwiseQC
%- takes two vectors, pre- and post-stimulus (400 ms each)
%- takes two measures of noise, short (1.5 ms) and long (500 ms) term
%- measures resting potential
%- measures difference in resting potential at pre- and post-stimulus
%

%% Determining protocol type 
if contains(CCSers.stimulus_description, PS.LPtags) 
    Wind = PS.LPqc_samplWind;
    recvTi = PS.LPqc_recovTime;                         %   
elseif contains(CCSers.stimulus_description, PS.SPtags) 
    Wind = PS.SPqc_samplWind;
    recvTi = PS.SPqc_recovTime;  
else
    disp([PS.SwDat.CurrentName, ' has no identified protocol type', ...
       ' which is called ',CCSers.stimulus_description])
end

%% getting data and possible filter               
data = CCSers.data.load;                                                   % load the data into another variable; this is helpful in case it is compressed in a datapipe object
if PS.filterVectors
   data = lowpass(data,PS.filterFreq,CCSers.starting_time_rate); 
end

%% Getting test pulse onset and saving voltage data
if range(PS.SwDat.StimData)>2
 PS.SwDat.StimData = PS.SwDat.StimData/1000;
end
>>>>>>> Stashed changes

%{
SweepwiseQC
- takes two vectors, pre- and post-stimulus (400 ms each)
- takes two measures of noise, short (1.5 ms) and long (500 ms) term
- measures resting potential
- measures difference in resting potential at pre- and post-stimulus
%}

<<<<<<< Updated upstream
%% selecting time windows and determining long-term noise/membrane voltage stability    
if checkVolts(CCSeries.data_unit) && string(CCSeries.description) ~= "PLACEHOLDER"

    vec_pre = CCSeries.data.load(...
                 SwData.StimOn-0.15*CCSeries.starting_time_rate:SwData.StimOn-1).*1000;
    vec_post = CCSeries.data.load((end-0.25*CCSeries.starting_time_rate)+1:...
    length(CCSeries.data.load)).*1000;

else
    if SwData.StimOn < 0.15*CCSeries.starting_time_rate
        disp(['Sweep Nr ', num2str(CCSeries.sweep_number), ' has peristimulus lengths shorter than desired'])
        vec_pre = CCSeries.data.load(1:SwData.StimOn);
        vec_post = CCSeries.data.load(SwData.StimOff:end);
    else 
    vec_pre = CCSeries.data.load(...
              SwData.StimOn-0.15*CCSeries.starting_time_rate:SwData.StimOn-1) ;
    vec_post = CCSeries.data.load((end-0.25*CCSeries.starting_time_rate)+1:...
    length(CCSeries.data.load));
    end
=======
%% Getting voltage trace at stimulus onset

QC.VStimOn(SwpCt) = {data(PS.SwDat.StimOn-0.0003*CCSers.starting_time_rate:...
                      0.002*CCSers.starting_time_rate+PS.SwDat.StimOn)};

QC.VStimOff(SwpCt) = {data(PS.SwDat.StimOn-0.0003*CCSers.starting_time_rate:...
                       0.002*CCSers.starting_time_rate+PS.SwDat.StimOff)}; 

%% selecting time windows and determining long-term noise/membrane voltage stability    
if checkVolts(CCSers.data_unit) && string(CCSers.description) ~= "PLACEHOLDER"

 vec_pre = (data(PS.SwDat.StimOn-Wind*...
           CCSers.starting_time_rate:PS.SwDat.StimOn-1).*1000)';
      
 if PS.SwDat.StimOff+recvTi*CCSers.starting_time_rate+...
           Wind*CCSers.starting_time_rate > length(data)  
       
       error('Recovery period and/or integration window are too long. Please adjust in loadParams')
 else
     vec_post = (data(PS.SwDat.StimOff+recvTi*CCSers.starting_time_rate+1:...
                       PS.SwDat.StimOff+recvTi*CCSers.starting_time_rate+...
                           Wind*CCSers.starting_time_rate).*1000)';
 end
else   
  if PS.SwDat.StimOn < PS.LPqc_samplWind*CCSers.starting_time_rate
    disp(['Sweep Nr ', num2str(CCSers.sweep_number), ...
                         ' has peristimulus lengths shorter than desired'])
    vec_pre = data(1:PS.SwDat.StimOn)'; 
    vec_post = data(PS.SwDat.StimOff:end)';
    
  else
    vec_pre = data(PS.SwDat.StimOn-Wind*CCSers.starting_time_rate-1:...
                                    PS.SwDat.StimOn-1)';
    vec_post = data(PS.SwDat.StimOff+recvTi*CCSers.starting_time_rate+1:...
                    PS.SwDat.StimOff+recvTi*CCSers.starting_time_rate+...
                     Wind*CCSers.starting_time_rate)';
  end
>>>>>>> Stashed changes
end
%%
restVPre = mean(vec_pre);
rmse_pre = sqrt(mean((vec_pre - restVPre).^2));
restVPost = mean(vec_post);
rmse_post = sqrt(mean((vec_post - restVPost).^2));
diffV_b_e = abs(restVPre-restVPost); % differnce between end and stim onset 
%% Determining short-term noise

stWin = round(1.5*(CCSeries.starting_time_rate/1000));
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
    
if isempty(CCSeries.bias_current)
 holdingI = 0;
elseif  isa(CCSeries.bias_current,'types.untyped.DataStub')
 holdingI = CCSeries.bias_current.load;
else
 holdingI = CCSeries.bias_current*10^12;
end 

if isempty(CCSeries.bridge_balance)
 bridgBal = 0;
elseif  isa(CCSeries.bridge_balance,'types.untyped.DataStub')
 bridgBal = CCSeries.bridge_balance.load;
else   
 bridgBal = CCSeries.bridge_balance*10^-6;
end

if isempty(CCSeries.capacitance_compensation)
  CaComp = NaN;
elseif isa(CCSeries.capacitance_compensation,'types.untyped.DataStub')
    CaComp = CCSeries.capacitance_compensation.load;
else
    CaComp = CCSeries.capacitance_compensation;
end
    

    QC_parameter(SweepCount,3:end) = array2table([...
        rmse_pre_st, ...
        rmse_post_st, ...
        rmse_pre, ...
        rmse_post, ...
        diffV_b_e, ...
        restVPre, ...
        holdingI,...
        0,...
        bridgBal,...
        0,...
        0, ...
        CaComp]);

    %% determine pass binaries

    QC_pass.stRMSE_pre(SweepCount)  = ...
      QC_parameter.stRMSE_pre(SweepCount) < params.RMSEst;

    QC_pass.stRMSE_post(SweepCount) = ...
      QC_parameter.stRMSE_post(SweepCount) < params.RMSEst;

     QC_pass.ltRMSE_pre(SweepCount)  = ...
      QC_parameter.ltRMSE_pre(SweepCount) < params.RMSElt;

    QC_pass.ltRMSE_post(SweepCount) = ...
      QC_parameter.ltRMSE_post(SweepCount) < params.RMSElt;

    QC_pass.diffVrest(SweepCount) = ...
      QC_parameter.diffVrest(SweepCount) < params.maxDiffBwBeginEnd;

    QC_pass.Vrest(SweepCount) = ...
      QC_parameter.Vrest(SweepCount) < params.maximumRestingPot;

    QC_pass.holdingI(SweepCount) = ...
      QC_parameter.holdingI(SweepCount) < params.holdingI;

    QC_pass.bridge_balance_abs(SweepCount) = ...
      QC_parameter.bridge_balance_abs(SweepCount) < params.bridge_balance;

    %% Plotting visualizations (Optional)
    if params.plot_all == 1
        figure('Position',[50 50 250 250],'visible','off'); set(gcf,'color','w');
        hold on
        plot(vec_pre)
        plot(vec_post)
        xlabel('time-steps')
        ylabel('voltage (mV)')
        axis tight
        ylim([-100 -30])
        legend({'pre-stim','post-stim'})
        export_fig([params.outDest, '\peristim\',params.cellID,' ',int2str(SweepCount),...
            ' RMS noise vectors'],params.plot_format,'-r100');
        close
    end
end