function [ltRMSE, VPs, stRMSE, SweepQC] = SweepwiseQC(CCSeries, CCStimSeries, SweepQC, sweepNr, params)

%{
SweepwiseQC
- takes two vectors, pre- and post-stimulus (400 ms each)
- takes two measures of noise, short (1.5 ms) and long (500 ms) term
- measures resting potential
- measures difference in resting potential at pre- and post-stimulus
%}

StimOn = find(CCStimSeries.data.load~=0,1,'first');
StimOff = find(CCStimSeries.data.load~=0,1,'last')+1;
vec_pre = CCSeries.data.load(1:StimOn);
vec_post = CCSeries.data.load((end-0.1*CCSeries.starting_time_rate)+1:...
    length(CCSeries.data.load));


%% long-term noise
restVPre = mean(vec_pre);
rmse_pre = sqrt(mean((vec_pre - restVPre).^2));
restVPost = mean(vec_post);
rmse_post = sqrt(mean((vec_post - restVPost).^2));


ltRMSE = types.core.FeatureExtraction(...
    'description', 'long-term RMSE pre and post',...
'electrodes',  types.hdmf_common.DynamicTableRegion(...
 'table',[], 'description', 'electrode', 'data', []), ...
'features', [rmse_pre, rmse_post], ...
'times', [StimOn/CCSeries.starting_time_rate, (length(CCSeries.data.load)/CCSeries.starting_time_rate)-0.5]);

%%

diffV_b_e = abs(restVPre-restVPost); % differnce between end and stim onset

VPs = types.core.FeatureExtraction(...
    'description', 'Membrane Potential Pre, Post and Delta',...
'electrodes', types.hdmf_common.DynamicTableRegion(...
 'table',[], 'description', 'electrode', 'data', []), ...
'features', [restVPre, restVPost, diffV_b_e], ...
'times', [StimOn/CCSeries.starting_time_rate, (length(CCSeries.data.load)/CCSeries.starting_time_rate)-0.5, ...
          (length(CCSeries.data.load)/CCSeries.starting_time_rate)-0.5 - StimOn/CCSeries.starting_time_rate
                     ]);

%% short-term noise
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

stRMSE = types.core.FeatureExtraction(...
    'description', 'short-term RMSE pre and post',...
'electrodes',  types.hdmf_common.DynamicTableRegion(...
 'table',[], 'description', 'electrode', 'data', []), ...
'features', [rmse_pre_st, rmse_post_st], ...
'times', [StimOn/CCSeries.starting_time_rate, (length(CCSeries.data.load)/CCSeries.starting_time_rate)-0.5]);


%% Creating the logic vector

logicVec = [rmse_pre_st > params.RMSEst, ...
    rmse_post_st > params.RMSEst, ...
    rmse_pre > params.RMSElt, ...
    rmse_post > params.RMSElt, ...
    diffV_b_e > params.maxDiffBwBeginEnd, ...
    restVPre > params.maximumRestingPot 
    ];
    

if sum(logicVec) > 0
SweepQC.features(sweepNr, 1) = 0;
b=num2str(find(logicVec));
idx=strfind(b,' ');
b(idx)=[];
SweepQC.features(sweepNr, 1) = str2double(b);
end

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
    export_fig([folder(1:length(folder)-8),cellID,' ',int2str(sweepIDcount),' RMS noise vectors'],params.plot_format,'-r100');
    close
end
