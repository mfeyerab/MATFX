% parametersNWB_SP

%% Getting sampling rate
if sum(h5readatt(fileName,[level.Resp,'/starting_time'],'unit') ...
        == 'seconds')==7 || ...
        sum(h5readatt(fileName,[level.Resp,'/starting_time'],'unit') ...
        == 'Seconds')==7                                                   % checks if the unit is as expected
    SP.acquireRes(1,SPcount) = 1000/h5readatt(...
        fileName,[level.Resp,'/starting_time'],'rate');                    % gets the sampling intervall
end
%% Extracting different epochs/'stimulus episodes'
temp = h5read(fileName,[level.Resp,'/data'])';   
if H5L.exists(H5G.open(H5F.open(fileName), ...
        '/specifications/'),'ndx-mies','H5P_DEFAULT') 
  stimFun = h5read(fileName,[level.Stim,'/data']);
  tempStimOn = find(stimFun(...
      preSP/SP.acquireRes(1,SPcount):end,1)~=0,1,'first')...
      +preSP/SP.acquireRes(1,SPcount)-1;                                       % offset by 10,000 timepoints to avoid test pulses
  testpulseOnset = find(stimFun(1:200/SP.acquireRes(1,SPcount)...
      )~=0,1,'first')-1;                                              % finds the onset of the testpulse
  SP.testpulse{1,SPcount} = temp(testpulseOnset+1-...
      5/SP.acquireRes(1,SPcount):testpulseOnset+100/SP.acquireRes(1,SPcount));         % saves voltage data of test pulse epoche
  SP.stimOff(1,SPcount) = find(stimFun~=0,1,'last')+1;
  stimDur = (SP.stimOff(1,SPcount)-tempStimOn)*SP.acquireRes(1,SPcount);
elseif  H5L.exists(H5G.open(H5F.open(fileName), ...
        '/stimulus/presentation/'),level.Stim(24:end),'H5P_DEFAULT')       % checks if there is a link with similarly labeled stimulus
stimFun = h5read(fileName,[level.Stim,'/data']);
tempStimOn = find(stimFun( ...
    100/SP.acquireRes(1,SPcount):end,1)~=0,1,'first')+200/SP.acquireRes(1,SPcount)-1;              % offset by 10,000 timepoints to avoid test pulses
testpulseOnset = find(stimFun(1:100/SP.acquireRes(1,SPcount))~=0,1,'first')-1;                    % finds the onset of the testpulse
SP.testpulse{1,SPcount} = temp(testpulseOnset-10/SP.acquireRes(1,SPcount):...         % saves voltage data of test pulse epoche
    testpulseOnset+100/SP.acquireRes(1,SPcount));
    if any(stimFun~=0)
    SP.stimOff(1,SPcount) = find(stimFun~=0,1,'last')+1;
    stimDur = (SP.stimOff(1,SPcount)-tempStimOn)*SP.acquireRes(1,SPcount);
    else
    stimFun = [];   
    SP.stimOff(1,SPcount) = NaN;
    tempStimOn = [];
    end
else
stimFun = [];   
SP.stimOff(1,SPcount) = NaN;
tempStimOn = [];
end    

%% Metadata on sweep/protocol level
if  H5L.exists(H5G.open(H5F.open(fileName), ...
        [level.Resp '/']),'bridge_balance','H5P_DEFAULT')
    if max(abs(stimFun))<1                                                     % checking for Stimulussignal in nA
      SP.sweepAmps(SPcount,1) = ...
      round(mean(stimFun(tempStimOn:SP.stimOff(1,SPcount))*1000));
    else
      SP.sweepAmps(SPcount,1) = ...
      round(mean(stimFun(tempStimOn:SP.stimOff(1,SPcount))));
    end
  SP.holding_current(SPcount,1) = ...
    h5read(fileName,[level.Resp,'/bias_current'])*1e12;                    % gets the holding current, factor converts into pA
  SP.bridge_balance(SPcount,1) = ...
    h5read(fileName,[level.Resp,'/bridge_balance'])/1e6;                   % gets the bridge balance, factor converts into MOhm
elseif ~H5L.exists(H5G.open(H5F.open(fileName), ...
                [level.Resp,'/']),'capacitance_fast','H5P_DEFAULT')
            if H5L.exists(H5G.open(H5F.open(fileName), ...
                [level.Resp,'/']),'bias_current','H5P_DEFAULT') 
                  SP.holding_current(SPcount,1) = ...
                h5read(fileName,[level.Resp,'/bias_current']);
            else 
                SP.holding_current(SPcount,1) = nan;
            end   
            if H5L.exists(H5G.open(H5F.open(fileName), ...
                [level.Resp,'/']),'bridge_balance','H5P_DEFAULT') 
                  SP.bridge_balance(SPcount,1) = ...
                h5read(fileName,[level.Resp,'/bridge_balance']);
            else 
                SP.bridge_balance(SPcount,1) = nan;
            end    
            SP.sweepAmps(SPcount,1) = ...
            round(mean(stimFun(tempStimOn:SP.stimOff(1,SPcount))));
else
    isVC = true;
end
%% Extracting the data
SP.sweep_label(SPcount,1) = string(info.Groups(1).Groups(s).Name);
if isempty(tempStimOn)                                                 
SP.stimOn(1,SPcount)  = NaN;
SP.stimOff(1,SPcount) = NaN;
tempStimOn = SP.stimOn(1,SPcount)+10000-1;  
else
 SP.stimOn(1,SPcount) = tempStimOn-(tempStimOn-preSP/SP.acquireRes(1,SPcount));
 SP.stimOff(1,SPcount) = SP.stimOff(1,SPcount)-...
     (tempStimOn-preSP/SP.acquireRes(1,SPcount)); 
end                                                                    
SP.V{1,SPcount} = temp(tempStimOn...
    -(preSP/SP.acquireRes(1,SPcount)):SP.stimOff(1,SPcount)+...
           (tempStimOn-preSP/SP.acquireRes(1,SPcount))+ ...
           (postSP/SP.acquireRes(1,SPcount)));                    

SPcount = SPcount + 1;

 
