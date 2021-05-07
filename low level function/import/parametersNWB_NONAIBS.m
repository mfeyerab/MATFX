% parametersNWB_NONAIBS

%% Getting sampling rate
if sum(h5readatt(fileName,[level.Resp,'/starting_time'],'unit') ...
        == 'seconds')==7 || ... 
        sum(h5readatt(fileName,[level.Resp,'/starting_time'],'unit') ...
        == 'Seconds')==7                                                         % checks if the unit is as expected
    NONAIBS.acquireRes = 1000/h5readatt(...
        fileName,[level.Resp,'/starting_time'],'rate');                    % gets the sampling intervall
end
%% Extracting different epochs/'stimulus episodes'
temp = h5read(fileName,[level.Resp,'/data'])';                             
if H5L.exists(H5G.open(H5F.open(fileName), ...
        '/stimulus/presentation/'),level.Stim(24:end),'H5P_DEFAULT')    % checks if there is a link with similarly labeled stimulus
stimFun = h5read(fileName,[level.Stim,'/data']);
   if any(stimFun)
    tempStimOn = find(stimFun(...
        200/NONAIBS.acquireRes:end,1)~=0,1,'first')+200/NONAIBS.acquireRes-1;              % offset by 10,000 timepoints to avoid test pulses
    testpulseOnset = find(stimFun(1:200/NONAIBS.acquireRes)~=0,1,'first')-1;                    % finds the onset of the testpulse
    NONAIBS.testpulse{1,NONAIBScount} = temp(testpulseOnset+1-5/NONAIBS.acquireRes:...         % saves voltage data of test pulse epoche
        testpulseOnset+100/NONAIBS.acquireRes);
    NONAIBS.stimOff(1,NONAIBScount) = find(stimFun~=0,1,'last')+1;
    stimDur = (NONAIBS.stimOff(1,NONAIBScount)-tempStimOn)*NONAIBS.acquireRes;

    tempStimOn = find(stimFun(10000:end,1)~=0,1,'first')+10000-1;              % offset by 10,000 timepoints to avoid test pulses
    NONAIBS.stimOff(1,NONAIBScount) = find(stimFun~=0,1,'last')+1;  
    stimDur = (NONAIBS.stimOff(1,NONAIBScount)-tempStimOn)*NONAIBS.acquireRes;
    NONAIBS.V{1,NONAIBScount} = temp(tempStimOn-(preNONAIBS/NONAIBS.acquireRes):end);    
   else
   NONAIBS.testpulse{1,NONAIBScount} = nan;    
   NONAIBS.sweepAmps(NONAIBScount,1)= nan;
   NONAIBS.stimOn(1,NONAIBScount) = 500/NONAIBS.acquireRes;
   NONAIBS.stimOff(NONAIBScount)= nan;
   NONAIBScount = NONAIBScount + 1;
   NONAIBS.V{1,NONAIBScount} = temp;   
   end
else   
NONAIBS.testpulse{1,NONAIBScount} = nan;        
NONAIBS.sweepAmps(NONAIBScount)= nan;
NONAIBS.stimOn(1,NONAIBScount) = 500/NONAIBS.acquireRes;
NONAIBS.stimOff(NONAIBScount)= nan;
NONAIBScount = NONAIBScount + 1;
NONAIBS.V{1,NONAIBScount} = temp;    
end    
%% Metadata
if ~H5L.exists(H5G.open(H5F.open(fileName), ...
        '/specifications/'),'ndx-mies','H5P_DEFAULT') 
    if max(abs(stimFun))<1                                                     % checking for Stimulussignal in nA
      NONAIBS.sweepAmps(NONAIBScount,1) = ...
      round(mean(stimFun(tempStimOn:NONAIBS.stimOff(1,NONAIBScount))*1000));
    else
      NONAIBS.sweepAmps(NONAIBScount,1) = ...
      round(mean(stimFun(tempStimOn:NONAIBS.stimOff(1,NONAIBScount))));
    end
  NONAIBS.holding_current(NONAIBScount,1) = ...
    h5read(fileName,[level.Resp,'/bias_current'])*1e12;                    % gets the holding current, factor converts into pA
  NONAIBS.bridge_balance(NONAIBScount,1) = ...
    h5read(fileName,[level.Resp,'/bridge_balance'])/1e6;                   % gets the bridge balance, factor converts into MOhm
elseif ~H5L.exists(H5G.open(H5F.open(fileName), ...
                [level.Resp,'/']),'capacitance_fast','H5P_DEFAULT')
            if H5L.exists(H5G.open(H5F.open(fileName), ...
                [level.Resp,'/']),'bias_current','H5P_DEFAULT') 
                  NONAIBS.holding_current(NONAIBScount,1) = ...
                h5read(fileName,[level.Resp,'/bias_current']);
            else 
                NONAIBS.holding_current(NONAIBScount,1) = nan;
            end    
            NONAIBS.bridge_balance(NONAIBScount,1) = ...
            h5read(fileName,[level.Resp,'/bridge_balance']);
            NONAIBS.sweepAmps(NONAIBScount,1) = ...
            round(mean(stimFun(tempStimOn:NONAIBS.stimOff(1,NONAIBScount))));
else
    isVC = true;
    NONAIBS.V{1,NONAIBScount} = {};
end
%%
NONAIBScount = NONAIBScount + 1;