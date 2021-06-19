function [QC_parameter, QC_pass]  = SweepwiseQC(CCSeries, StimOn, SweepCount, QC_parameter, QC_pass, params)

%{
SweepwiseQC
- takes two vectors, pre- and post-stimulus (400 ms each)
- takes two measures of noise, short (1.5 ms) and long (500 ms) term
- measures resting potential
- measures difference in resting potential at pre- and post-stimulus
%}

%% selecting time windows and determining long-term noise/membrane voltage stability    
    if checkVolts(CCSeries.data_unit)
        
            vec_pre = CCSeries.data.load(...
                     StimOn-0.15*CCSeries.starting_time_rate:StimOn-1).*1000;
        vec_post = CCSeries.data.load((end-0.25*CCSeries.starting_time_rate)+1:...
        length(CCSeries.data.load)).*1000;

    else
        vec_pre = CCSeries.data.load(...
                     StimOn-0.15*CCSeries.starting_time_rate:StimOn-1) ;
        vec_post = CCSeries.data.load((end-0.25*CCSeries.starting_time_rate)+1:...
        length(CCSeries.data.load));
    end

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

    if ~isempty(CCSeries.bias_current)
     holdingI = CCSeries.bias_current*10^12;
     bridgBal = CCSeries.bridge_balance*10^-6;
    else
     holdingI = 0;
     bridgBal = 0;
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
        0]);

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
        figure('Position',[50 50 250 250]); set(gcf,'color','w');
        hold on
        plot(vec_pre)
        plot(vec_post)
        xlabel('time-steps')
        ylabel('voltage (mV)')
        axis tight
        ylim([-100 -30])
        legend({'pre-stim','post-stim'})
        %export_fig([folder(1:length(folder)-8),cellID,' ',int2str(sweepIDcount),' RMS noise vectors'],params.plot_format,'-r100');
        close
    end
end