function wf = singleWaveform(protocol,sp,params,k,pTime)

%{
resample each waveform to 50 kHz
%}

x = protocol.V{1,k}(sp.peakTime(pTime)-params.windowBeg:...
    sp.peakTime(pTime)+params.windowEnd);
if round(double(protocol.acquireRes),2) ~= params.sampleRTdt
    x = double(x);                                                          % double precision
    prePad = x(1)+zeros(1,100); postPad = x(end)+zeros(1,100);              % generate pads
    x = [prePad,x,postPad];                                                 % pad vector
    x = resample(x,params.sampleRT,round(double(1000/protocol.acquireRes(1,k))));      % resample
    if round(double(1000/protocol.acquireRes(1,k))) == 10000                           % remove pad 10kHz
        x = x(501:end-500); % length==315
    elseif round(double(1000/protocol.acquireRes(1,k))) == 20000                       % remove pad 20 kHz
        x = x(251:end-250); % length==313
    elseif round(double(1000/protocol.acquireRes(1,k))) == 200000                      % remove pad 200 kHz
        x = x(25:end-25); % length==312
    end
    x = single(x);
end
[val,pt] = max(x(1:180));
figure('Position',[50 50 250 200]); set(gcf,'color','w');
hold on
plot(x)
scatter(pt,val)
close
wf = x(pt-params.windowBegS:pt+params.windowEndS);

%{
notes re: padding waveforms
10 kHz
    63 -> 315
    63 -> 1315 = 501:end-500 
20 kHz
    125 -> 313
    125 -> 813
200 kHz
    1241 -> 311
    1241 -> 361
%}