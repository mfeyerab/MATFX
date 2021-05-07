function [qc] = SweepwiseQC(protocols,k,params,cellID,folder,Metadata, sweepIDcount)

%{
SweepwiseQC
- takes two vectors, pre- and post-stimulus (400 ms each)
- takes two measures of noise, short (1.5 ms) and long (500 ms) term
- measures resting potential
- measures difference in resting potential at pre- and post-stimulus
%}

if string(protocols.name) == "long pulse" 
vec_pre = double(protocols.V{1,k}(protocols.stimOn(1,k)-(params.LPqc_samplWind/protocols.acquireRes(1,k))-1:protocols.stimOn(1,k)-1));
vec_post = double(protocols.V{1,k}((protocols.stimOff(1,k)+(params.LPqc_recovTime/protocols.acquireRes(1,k))-1):...
    protocols.stimOff(1,k)+(params.LPqc_recovTime/protocols.acquireRes(1,k))-1+(params.LPqc_samplWind/protocols.acquireRes(1,k))));
elseif string(protocols.name) == "short pulse"
vec_pre = double(protocols.V{1,k}(protocols.stimOn(1,k)-(params.SPqc_samplWind/protocols.acquireRes(1,k))-1:protocols.stimOn(1,k)-1));
vec_post = double(protocols.V{1,k}((protocols.stimOff(1,k)+(params.SPqc_recovTime/protocols.acquireRes(1,k))-1):...
    protocols.stimOff(1,k)+(params.SPqc_recovTime/protocols.acquireRes(1,k))-1+(params.SPqc_samplWind/protocols.acquireRes(1,k))));
elseif string(protocols.name) == "NONAIBS" && any(protocols.V{1,k}) && protocols.stimOn(1,k) > 0
vec_pre = double(protocols.V{1,k}(protocols.stimOn(1,k)-(params.preAIBS_samplWind/protocols.acquireRes):protocols.stimOn(1,k)));
vec_post = nan;
else 
vec_pre = nan;
vec_post = nan;
rmse_pre_st = nan;
end

%% long-term noise
qc.restVPre = mean(vec_pre);
qc.rmse_pre = sqrt(mean((vec_pre - qc.restVPre).^2));
qc.restVPost = mean(vec_post);
qc.rmse_post = sqrt(mean((vec_post - qc.restVPost).^2));

%% short-term noise
stWin = round(1.5/protocols.acquireRes(1,1));
winCount = 1;
for i = 1:round(stWin/2):length(vec_pre)-stWin
    yhat = mean(vec_pre(1,i:i+stWin));
    rmse_pre_st(winCount) = sqrt(mean((vec_pre(1,i:i+stWin) - yhat).^2));
end

qc.rmse_pre_st = mean(rmse_pre_st);
%%
if ~isnan(vec_post) 
 winCount = 1;
 for i = 1:round(stWin/2):length(vec_pre)-stWin
    yhat = mean(vec_post(1,i:i+stWin));
    rmse_post_st(winCount) = sqrt(mean((vec_post(1,i:i+stWin) - yhat).^2));
    winCount = winCount+1;  
 end   
qc.rmse_post_st = mean(rmse_post_st);
qc.diffV_b_e = abs(qc.restVPre-qc.restVPost); % differnce between end and stim onset
else
qc.rmse_post_st = NaN;   
qc.diffV_b_e = NaN;
end

%% Creating the logic vector

if ~isfield(Metadata,'membrane_resistance')
   membrane_resistance = nan;
end

qc.logicVec = [qc.rmse_pre_st > params.RMSEst, ...
    qc.rmse_post_st > params.RMSEst, ...
    qc.rmse_pre > params.RMSElt, ...
    qc.rmse_post > params.RMSElt, ...
    qc.diffV_b_e > params.maxDiffBwBeginEnd, ...
    qc.restVPre > params.maximumRestingPot, ...
    abs(protocols.holding_current(k)) >  params.holdingI, ...
    protocols.bridge_balance(k) >  params.bridge_balance, ...
    protocols.bridge_balance(k)> ...
    params.factorRelaRa*membrane_resistance];
    
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
