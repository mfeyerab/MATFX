function [qc] = estimateRMSnoisePFfunction(protocol,k,params,cellID,folder)

%{
estimateRMSnoisePFfunction
- takes two vectors, pre- and post-stimulus (500 ms each)
- takes two measures of noise, short (1.5 ms) and long (500 ms) term
- measures resting potential
- measures difference in resting potential at pre- and post-stimulus
%}

% vectors to estimate noise
if string(protocol.name) == "long pulse" 
vec_pre = double(protocol.V{k,1}(protocol.stimOn(1,k)-(500/protocol.acquireRes)-1:protocol.stimOn(1,k)-1));
vec_post = double(protocol.V{k,1}(protocol.stimOff(1,k)+(1500/protocol.acquireRes):protocol.stimOff(1,k)+(2000/protocol.acquireRes)-1));
elseif  string(protocol.name) == "short pulse"
vec_pre = double(protocol.V{k,1}(protocol.stimOn(1,1)-(20/protocol.acquireRes)+1:protocol.stimOn(1,1)-1));
vec_post = double(protocol.V{k,1}(end-(20/protocol.acquireRes):end));    
elseif string(protocol.name) == "noise"
vec_pre = double(protocol.V{k,1}(protocol.stimOn(1,1)-(500/protocol.acquireRes)-1:protocol.stimOn(1,1)-1));
vec_post = double(protocol.V{k,1}(protocol.stimOff(1,1)+(500/protocol.acquireRes):protocol.stimOff(1,1)+(1000/protocol.acquireRes)-1)); 
elseif string(protocol.name) == "ramp"    
vec_pre = double(protocol.V{k,1}(1:protocol.stimOn(1,k)-1));
vec_post = double(protocol.V{k,1}(protocol.stimOff(1,k)+(150/protocol.acquireRes):protocol.stimOff(1,k)+(350/protocol.acquireRes))); 
elseif string(protocol.name) == "ultrashort pulse"   
vec_pre = double(protocol.V{k,1}(1:protocol.stimOn(1,k)-1));
vec_post = double(protocol.V{k,1}(end-(100/protocol.acquireRes):end));
elseif string(protocol.name) == "nanoamp pulse"  
vec_pre = double(protocol.V{k,1}(protocol.stimOn(1,1)-(500/protocol.acquireRes)-1:protocol.stimOn(1,1)-1));
vec_post = double(protocol.V{k,1}(end-(500/protocol.acquireRes):end));
end


% long-term noise
qc.restVPre = mean(vec_pre);
qc.rmse_pre = sqrt(mean((vec_pre - qc.restVPre).^2));
qc.restVPost = mean(vec_post);
qc.rmse_post = sqrt(mean((vec_post - qc.restVPost).^2));

% short-term noise
% stWin = round(1.5/protocol.acquireRes);
% winCount = 1;
% for i = 1:round(stWin/2):length(vec_post)-stWin
%     yhat = mean(vec_pre(1,i:i+stWin));
%     rmse_pre_st(winCount) = sqrt(mean((vec_pre(1,i:i+stWin) - yhat).^2));
%     yhat = mean(vec_post(1,i:i+stWin));
%     rmse_post_st(winCount) = sqrt(mean((vec_post(1,i:i+stWin) - yhat).^2));
%     winCount = winCount+1;
% end

% qc.rmse_pre_st = mean(rmse_pre_st);
% qc.rmse_post_st = mean(rmse_post_st);

 qc.rmse_pre_st = 0;
 qc.rmse_post_st = 0;

qc.diffV_b_e = abs(qc.restVPre-qc.restVPost); % differnce between end and stim onset

qc.logicVec = [qc.rmse_pre_st > params.RMSEst, ...
    qc.rmse_post_st > params.RMSEst, ...
    qc.rmse_pre > params.RMSElt, ...
    qc.rmse_post > params.RMSElt, ...
    qc.diffV_b_e > params.maxDiffBwBeginEnd, ...
    qc.restVPre > params.minimumRestingPot];

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
    export_fig([folder(1:length(folder)-8),cellID,' ',int2str(k),' RMS noise vectors ', protocol.name],'-pdf','-r100');
    close
end
