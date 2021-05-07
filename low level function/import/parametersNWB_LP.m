% parametersNWB_LP

%% Getting sampling rate
if sum(h5readatt(fileName,[level.Resp,'/starting_time'],'unit') ...
        == 'seconds')==7 || ...
        sum(h5readatt(fileName,[level.Resp,'/starting_time'],'unit') ...
        == 'Seconds')==7                                                   % checks if the unit is as expected
    LP.acquireRes(1,LPcount) = 1000/h5readatt(...
        fileName,[level.Resp,'/starting_time'],'rate');                    % gets the sampling intervall
end
%% Extracting different epochs/'stimulus episodes'
temp = h5read(fileName,[level.Resp,'/data'])';   
if H5L.exists(H5G.open(H5F.open(fileName), ...
        '/specifications/'),'ndx-mies','H5P_DEFAULT') 
  stimFun = h5read(fileName,[level.Stim,'/data']);
  tempStimOn = find(stimFun(...
      200/LP.acquireRes(1,LPcount):end,1)~=0,1,'first')...
      +200/LP.acquireRes(1,LPcount)-1;                                       % offset by 10,000 timepoints to avoid test pulses
  testpulseOnset = find(stimFun(1:200/LP.acquireRes(1,LPcount)...
      )~=0,1,'first')-1;                                              % finds the onset of the testpulse
  LP.testpulse{1,LPcount} = temp(testpulseOnset+1-...
      5/LP.acquireRes(1,LPcount):testpulseOnset+100/LP.acquireRes(1,LPcount));         % saves voltage data of test pulse epoche
  LP.stimOff(1,LPcount) = find(stimFun~=0,1,'last')+1;
  stimDur = (LP.stimOff(1,LPcount)-tempStimOn)*LP.acquireRes(1,LPcount);
elseif  H5L.exists(H5G.open(H5F.open(fileName), ...
        '/stimulus/presentation/'),level.Stim(24:end),'H5P_DEFAULT')       % checks if there is a link with similarly labeled stimulus
stimFun = h5read(fileName,[level.Stim,'/data']);
tempStimOn = find(stimFun( ...
    200/LP.acquireRes(1,LPcount):end,1)~=0,1,'first')+200/LP.acquireRes(1,LPcount)-1;              % offset by 10,000 timepoints to avoid test pulses
testpulseOnset = find(stimFun(1:200/LP.acquireRes(1,LPcount))~=0,1,'first')-1;                    % finds the onset of the testpulse
LP.testpulse{1,LPcount} = temp(testpulseOnset-10/LP.acquireRes(1,LPcount):...         % saves voltage data of test pulse epoche
    testpulseOnset+100/LP.acquireRes(1,LPcount));
LP.stimOff(1,LPcount) = find(stimFun~=0,1,'last')+1;
stimDur = (LP.stimOff(1,LPcount)-tempStimOn)*LP.acquireRes(1,LPcount);
else
stimFun = [];   
LP.stimOff(1,LPcount) = NaN;
tempStimOn = [];
end    

%% Metadata on sweep/protocol level
if ~H5L.exists(H5G.open(H5F.open(fileName), ...
        '/specifications/'),'ndx-mies','H5P_DEFAULT') 
    if max(abs(stimFun))<1                                                     % checking for Stimulussignal in nA
      LP.sweepAmps(LPcount,1) = ...
      round(mean(stimFun(tempStimOn:LP.stimOff(1,LPcount))*1000));
    else
      LP.sweepAmps(LPcount,1) = ...
      round(mean(stimFun(tempStimOn:LP.stimOff(1,LPcount))));
    end
  LP.holding_current(LPcount,1) = ...
    h5read(fileName,[level.Resp,'/bias_current'])*1e12;                    % gets the holding current, factor converts into pA
  LP.bridge_balance(LPcount,1) = ...
    h5read(fileName,[level.Resp,'/bridge_balance'])/1e6;                   % gets the bridge balance, factor converts into MOhm
elseif ~H5L.exists(H5G.open(H5F.open(fileName), ...
                [level.Resp,'/']),'capacitance_fast','H5P_DEFAULT')
            if H5L.exists(H5G.open(H5F.open(fileName), ...
                [level.Resp,'/']),'bias_current','H5P_DEFAULT') 
                  LP.holding_current(LPcount,1) = ...
                h5read(fileName,[level.Resp,'/bias_current']);
            else 
                LP.holding_current(LPcount,1) = nan;
            end   
            if H5L.exists(H5G.open(H5F.open(fileName), ...
                [level.Resp,'/']),'bridge_balance','H5P_DEFAULT') 
                  LP.bridge_balance(LPcount,1) = ...
                h5read(fileName,[level.Resp,'/bridge_balance']);
            else 
                LP.bridge_balance(LPcount,1) = nan;
            end    
            LP.sweepAmps(LPcount,1) = ...
            round(mean(stimFun(tempStimOn:LP.stimOff(1,LPcount))));
else
    isVC = true;
end
%% Extracting the data
LP.sweep_label(LPcount,1) = string(info.Groups(1).Groups(s).Name);

if length(temp)>(LP.stimOff(1,LPcount)+(postLP/LP.acquireRes(1,LPcount))) && ...
    ~isempty(findpeaks(temp)) && ~isVC
    if isempty(tempStimOn)                                                 % in case there is no LP stimulation (happens in some Rheo reps)   
    LP.stimOn(1,LPcount)  = LP.stimOn(1,LPcount-1);
    LP.stimOff(1,LPcount) = LP.stimOff(1,LPcount-1);
    tempStimOn = LP.stimOn(1,LPcount)+10000-1;  
    else
     LP.stimOn(1,LPcount) = tempStimOn-(tempStimOn-preLP/LP.acquireRes(1,LPcount));
     LP.stimOff(1,LPcount) = LP.stimOff(1,LPcount)-...
         (tempStimOn-preLP/LP.acquireRes(1,LPcount)); 
    end                                                                    
    LP.V{1,LPcount} = temp(tempStimOn...
        -(preLP/LP.acquireRes(1,LPcount)):LP.stimOff(1,LPcount)+...
               (tempStimOn-preLP/LP.acquireRes(1,LPcount))+ ...
               (postLP/LP.acquireRes(1,LPcount)));                    

    LPcount = LPcount + 1;

elseif isfield(LP, 'sweepAmps')
    LP.sweepAmps(LPcount)= nan;
    LP.stimOff(LPcount)= nan;
end
 
