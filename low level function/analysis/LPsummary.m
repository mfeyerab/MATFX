function [icSum, PS] = LPsummary(nwb, icSum, ClNr, PS)

IcephysTab = nwb.general_intracellular_ephys_intracellular_recordings;     % Assign new variable for readability
SwpRespTbl = IcephysTab.responses.response.data.load.timeseries;           % Assign new variable for readability
SwpAmps = IcephysTab.stimuli.vectordata.values{1}.data;                    % Assign new variable for readability
qcParas = nwb.processing.map('QC parameter'...
                                     ).dynamictable.values{1}.vectordata;
qcPass = IcephysTab.dynamictable.map('quality_control_pass').vectordata;
Proto = strtrim(string(IcephysTab.dynamictable.map('protocol_type'...
                     ).vectordata.values{1}.data.load));
LPIdx = contains(cellstr(Proto),PS.LPtags);

if isa(qcPass.values{1}.data, 'double')                                    % Newly written entries into nwb object are doubles not DataStubs, hence there are two different forms of code needed to access them
  
  IdxPassSwps = all([qcPass.values{1}.data', LPIdx],2);                    % creates indices from passing QC (sweeps x 1)and LP type indices                              
  SwpPaths = {SwpRespTbl.path};                                            % Gets all sweep paths of sweep response table and assigns it to a new variable  
  SwpIDs = cellfun(@(a) str2double(a), cellfun(@(v)v(1),...                % Extract the numbers from the sweep names as doubles  
                                       regexp(SwpPaths,'\d*','Match')));   % inner cellfun necessary if sweep name contains mutliple numbers for example an extra AD01 
  IdPassSwps = SwpIDs(IdxPassSwps);                                        % Variable contains numbers of sweeps which passed QC  
  IdPassSwpsC = cellstr(string(IdPassSwps));
  
  if ~isempty(IdPassSwps)
  %% subthreshold parameters  
  SubThres = nwb.processing.map('subthreshold parameters').dynamictable;   % Creating variable with all subthreshold data for readability     
  [icSum.RinHD(ClNr,1), icSum.RinSS(ClNr,1), icSum.RinOffset(ClNr,1)] = ...% Assign resistance and offset of cell in summary table
        getRin(SubThres,PS, IdPassSwps);                                   % the function returns input resistance and offset calculated as slope of a linear fit and "membrane deflection" at 0 pA       

  %tau Vrest
  if ~isempty(qcParas.map('SweepID').data)                                 % if there are any QCed sweeps             
   qcTabIdx = find(ismember(regexp(cell2mat(qcParas.map('SweepID').data),...%Gets index of all passed LP sweeps  from cell  
                                             '\d*','Match'), IdPassSwpsC));  
   icSum.Vrest(ClNr,1) = round(nanmean(qcParas.map('Vrest').data(qcTabIdx)),2);  %calculates resting membrane potential as mean of prestim Vrest of all passed LP sweeps
  end
  %tau
  SubSwpIdx = find(endsWith(SubThres.keys, ['_',string(IdPassSwps)]));
  tauVec = deal(nan(length(SubThres.keys),1));
  minAmp = 200; minAmpSubSwpIdx = [];
  for s = 1:length(SubThres.keys)                                          % for each subthreshold sweep 
   if SubThres.values{s}.vectordata.map('GFtau').data > PS.GF &&...
        SubThres.values{s}.vectordata.map('maxSubDeflection').data > PS.maxDefl &&...
           abs(SubThres.values{s}.vectordata.map('SwpAmp').data) > 10 
    
     tauVec(s,1)=SubThres.values{s}.vectordata.map('tau').data;
   end
   if SubThres.values{s}.vectordata.map('GFtau').data > PS.GF && ...
           minAmp > abs(SubThres.values{s}.vectordata.map('SwpAmp').data)             
      minAmpSubSwpIdx = s;
      minAmp = abs(SubThres.values{s}.vectordata.map('SwpAmp').data); 
   end
  end    
  if ~isempty(tauVec) && any(~isnan(tauVec))                                                    
   icSum.tau(ClNr,1) = round(nanmean(tauVec),2);                          
  elseif ~isempty(tauVec) && ~isempty(minAmpSubSwpIdx)
   icSum.tau(ClNr,1) = SubThres.values{minAmpSubSwpIdx...
                                         }.vectordata.map('tau').data;                        
  end

  PS.tau = icSum.tau(ClNr,1); PS.Rin = icSum.RinHD(ClNr,1);
  
  %rectification 
  icSum = getRect(SubThres,IdPassSwps, PS, icSum, ClNr);                   % calculates the rectification index 

  %% firing patterns
  spPatr = nwb.processing.map('AP Pattern').dynamictable;                  
  SpBinTab = nwb.processing.map('AP Pattern').dynamictable.values{2}.vectordata;                                    
  SpPatrTab = nwb.processing.map('AP Pattern').dynamictable.values{1}.vectordata;% assign variable for readability
  SpiTiRagArr = spPatr.map('SpikeTimes').vectordata;
  SuprIDs = SpPatrTab.map('SwpID').data;                                   % Get names of suprathreshold sweeps as cell array  
  if iscell(SuprIDs)
  passSuprIdx = ismember(SuprIDs, IdPassSwpsC); 
  LPsupraIDs = SuprIDs(passSuprIdx);
  ISIs = spPatr.map('ISIs').vectordata.values{1}.data;  
  passRts = SpPatrTab.map('firRt').data(passSuprIdx);     
  
  if ~isempty(passRts)
  icSum.maxRt(ClNr,1) =  max(passRts);                                     % Maximum firing rate
  end
  icSum.lastQuisc(ClNr,1) = min(SpPatrTab.map('lastQuisc').data);          % non-persistance of firing quantified as minimum time span from last spike to stimulus end from all sweeps
  % dynamic frequency range
  if spPatr.isKey('ISIs') && ~isempty(ISIs)                                % if ISI module exists and is not empty
         
   ISIs = ISIs(~isnan(ISIs));ISIs(ISIs==0) = [];                           % get rid of 0 and nans                                                               
   icSum.medInstaRt(ClNr,1) = round(1000/nanmedian(ISIs),2);       
   icSum.DFR_P90(ClNr,1) = round(prctile(ISIs, 90),2);           
   icSum.DFR_P10(ClNr,1) = round(prctile(ISIs, 10),2); 
   icSum.DFR_IQR(ClNr,1) = round(prctile(ISIs, 75) - prctile(ISIs, 25),2);
            
   % adaptation   
   icSum.AdaptRatB1B2(ClNr,1) = ...                                        % divides the sum of all spikes in the second bin
        round(sum(SpBinTab.map('B2').data)/sum(SpBinTab.map('B1').data),2);% by the sum of all spikes in the first bin                    
   icSum.AdaptRatB1B13(ClNr,1) = ...                                       % divides the sum of all spikes in the last bin
       round(sum(SpBinTab.map('B13').data)/sum(SpBinTab.map('B1').data),2);% by the sum of all spikes in the first bin                         

   if ~isempty(SpBinTab.map('B1').data) && ~isempty(passRts)          
    if min(passRts) > 4
      StartIdx = find(SpPatrTab.map('firRt').data==min(passRts));
    else
      Close2Rheo = min(setdiff(passRts,min(passRts)));
      if ~isempty(Close2Rheo)          
       StartIdx = find(SpPatrTab.map('firRt').data==Close2Rheo);
      end
    end    
    if ~isempty(icSum.maxRt(ClNr,1)) && ...
            exist('Close2Rheo', 'var') && ~isempty(Close2Rheo)       
      MaxIdx = find(SpPatrTab.map('firRt').data==icSum.maxRt(ClNr,1));    
      StartSwpBinCount = table2array(getRow(spPatr.values{2},StartIdx));   % spike bin counts for start sweep 
      MaxSwpBinCount = table2array(getRow(spPatr.values{2},MaxIdx));       % spike bin counts for the sweep with maximum firing rate                        
      icSum.StimAdapB123(ClNr,1) = ...                                     % calculates an adaptiation ratio by
                     sum(StartSwpBinCount(1:3))/sum(MaxSwpBinCount(1:3));  % dividing spikes out of the first three bins from first by max sweeps  
      icSum.StimAdapB7_13(ClNr,1) = ...                                    % calculates an adaptiation ratio by
                     sum(StartSwpBinCount(7:13))/sum(MaxSwpBinCount(7:13));% dividing spikes from 7th to last bin from first by max sweeps 
    end              
    I = round(SwpAmps.load(find(...
                         ismember(SwpIDs,cellfun(@str2num,LPsupraIDs))))); % Get all stimulus amplitudes of suprathershold long pulse sweeps
    if length(I)>2
     P = robustfit(I, passRts);                                            % create a linear fit of I f curve                
     icSum.fIslope(ClNr,1) = round(P(1),3);                                % save slope as feature for cell

     if PS.plot_all >= 1
      figure('visible','off', 'Position', [128 320 1204 658]);
      %rasterplot
      SpiTi=cell(length(passSuprIdx),1);
      idx = SpiTiRagArr.map('time_index').data;
      for s=1:length(passSuprIdx)
          if s==1
            SpiTi{s,1} = SpiTiRagArr.map('time').data(1:idx(s));  
          else
            SpiTi{s,1} = SpiTiRagArr.map('time').data(idx(s-1)+1:idx(s));
          end
      end
      [~,order] = sort(cellfun(@length,SpiTi),'ascend');
      SpiTi = SpiTi(order);
      subplot(2,3,1);rasterplot(SpiTi)
      %I-f curve 
      subplot(2,3,2); hold on;
      scatter(I, passRts)
      yfit = P(2)*I+P(1);             plot(I,yfit,'r-.');
      xlabel('input current (pA)');   ylabel('firing frequency (Hz)')
      title('f/I curve');             box off; axis tight 
      subplot(2,3,3); hold on;
      %Adaptation over stimulus
      temp = spPatr.values{1}.vectordata.map('SwpID').data;
      [~,order] = sort(temp);
      SupIdx = ismember(spPatr.values{1}.vectordata.map(...
                                        'SwpID').data(order), IdPassSwpsC);
      scatter(I,getRow(spPatr.values{1},find(SupIdx)).adaptIdx)
      title('Adaptation Index 1 over stim'); 

      subplot(2,3,5);     
      scatter(I,getRow(spPatr.values{1},find(SupIdx)).burst)
      title('burst over stim'); 

      subplot(2,3,6);  
      scatter(I,getRow(spPatr.values{1},find(SupIdx)).cvISI)
      title('cvISI over stim'); 

      subplot(2,3,4); 
      if ~isempty(ISIs)
       cdfplot(1000./ISIs); grid off; box off;
      end
      xlim([0 200]);xlabel('instantenous frequency (Hz)'); 
      title('Dynamic frequency range');
      
      exportgraphics(gcf,fullfile(fullfile(PS.outDest, 'firingPattern', ...
                         [PS.cellID , '_firingPattern', PS.pltForm])));
     end
    end
   end
  end
  end
  %% finding certain sweeps
  APwave = nwb.processing.map('AP wave').dynamictable;                     % variable for better readability   
  if isa(SwpAmps, 'double')                                                % if current amplitude is double not a DataStub
    LPampsQC = round(SwpAmps(IdxPassSwps));                                % assign current amplitudes  of sweeps that made the QC to variable
  else  
    SwpAmps2 = round(SwpAmps.load);
    LPampsQC = round(SwpAmps2(find(IdxPassSwps)));                         % assign current amplitudes  of sweeps that made the QC to variable
  end
  %% sag sweep                                                                                                                                                                             % the number of runs is lower than the number of sweep amplitudes +1    
  PotSagAmps = sort(LPampsQC(LPampsQC<0), 'descend');                      % finds sag sweep amplitude 
  tmpSwtc = 0; currSagDefl = 0;
  for s=1:length(PotSagAmps)
   tempIdx = find(SwpAmps2==PotSagAmps(s),1,'last');                                % get sag sweep table position 
   sagSwpID = regexp(SwpPaths{tempIdx},'\d*','Match');                     % gets the sweep name from the last chunck    
   if any(endsWith(SubThres.keys,['_',char(sagSwpID)]))
          SagData = SubThres.values{...
       endsWith(SubThres.keys,['_',char(sagSwpID)])}.vectordata;
     if (tmpSwtc==0 && SagData.map('maxSubDeflection').data < (PS.maxDefl-2)) || (...
      abs(SagData.map('maxSubDeflection').data-(PS.maxDefl-2)) < currSagDefl && ...
       SagData.map('maxSubDeflection').data < (PS.maxDefl-2))
       
     currSagDefl = abs(SagData.map('maxSubDeflection').data-PS.maxDefl);
     tmpSwtc = 1;PS.sagSwpTabPos = tempIdx;
     icSum.sagAmp(ClNr,1) = PotSagAmps(s);   
     icSum.sag(ClNr,1) = round(SagData.map('sag').data,2);                 % save sag amplitude of sag sweep
     icSum.sagRat(ClNr,1) = round(SagData.map('sagRat').data,2);           % save ratio of sag sweep   
     icSum.sagVrest(ClNr,1) = round(SagData.map('baseVm').data,2);         % save membrane potential of sag sweep from the QC parameters in sweep table because these are always in mV!                                                                  %            
     PS.sagSwpSers = nwb.resolve(SwpPaths(tempIdx));                       % save CC series to plot it later in the cell profile  
     end
   end
  end
  if tmpSwtc==0 && ~isempty(PotSagAmps)
   icSum.sagAmp(ClNr,1) =  min(PotSagAmps);
   PS.sagSwpTabPos = find(SwpAmps2==icSum.sagAmp(ClNr,1) & ...
                                     IdxPassSwps,1,'last');                % get sag sweep table position  
   sagSwpID = regexp(SwpPaths{PS.sagSwpTabPos},'\d*','Match');             % gets the sweep name from the last chunck    
   if any(endsWith(SubThres.keys,['_',char(sagSwpID)])) 
     SagData = SubThres.values{...
       endsWith(SubThres.keys,['_',char(sagSwpID)])}.vectordata;
   end
   icSum.sag(ClNr,1) = round(SagData.map('sag').data,2);                   % save sag amplitude of sag sweep
   icSum.sagRat(ClNr,1) = round(SagData.map('sagRat').data,2);             % save ratio of sag sweep   
   icSum.sagVrest(ClNr,1) = round(SagData.map('baseVm').data,2);           % save membrane potential of sag sweep from the QC parameters in sweep table because these are always in mV!                                                                  %            
   PS.sagSwpSers = nwb.resolve(SwpPaths(PS.sagSwpTabPos));    
  end
  %% rheobase sweeps and parameters of first spike
  if exist('LPsupraIDs', 'var') && iscell(LPsupraIDs) && ~isempty(passRts)
   rheoIdx = find(passRts <= median(passRts) & I < median(I));
   if ~isempty(rheoIdx) && length(unique(passRts(rheoIdx)))>1
       [maxPotRheoRt, tempIdx] = max(passRts(rheoIdx));
       while maxPotRheoRt > 1 && ...
           any(I(passRts < maxPotRheoRt) < min(I(passRts == maxPotRheoRt)))
         rheoIdx(tempIdx) = [];
         [maxPotRheoRt, tempIdx] = max(passRts(rheoIdx));
       end
       if length(rheoIdx)>1
          rheoIdx = rheoIdx(1);
       end
   elseif length(passRts)==1
     rheoIdx=1;
   else
        [~,rheoIdx] = min(I);
   end
   icSum.rheoRt(ClNr,1) = passRts(rheoIdx);
   RheoSwpID = LPsupraIDs(rheoIdx);
   if length(RheoSwpID) > 1
    for r=1:length(RheoSwpID)
    PS.rheoSwpTabPos(r) = find(endsWith(SwpPaths,['_', RheoSwpID{r}]));    % save position of rheo sweep in sweep table   
    end
    StimOn = IcephysTab.responses.response.data.load.idx_start(PS.rheoSwpTabPos);
    RheoData = cell(sum(StimOn==mode(StimOn)),1);
    for s=1:length(RheoSwpID)       
     if StimOn(s)==mode(StimOn)
      RheoData{s,1} = ...
        APwave.values{endsWith(APwave.keys,['_',RheoSwpID{s}])}.vectordata;   
     end
    end
   else
    PS.rheoSwpTabPos = find(endsWith(SwpPaths,['_', RheoSwpID{1}]));    
    rheoProModPos = endsWith(APwave.keys,['_', RheoSwpID{1}]);             % save position of first rheo sweep in AP processing moduls
    PS.rheoSwpDat = APwave.values{find(rheoProModPos,1,'first')}.vectordata;
    if ~isempty(PS.rheoSwpDat)                                             % if there is a rheo sweep
     PS.rheoSwpSers = nwb.resolve(SwpRespTbl(PS.rheoSwpTabPos).path);      % get CCSeries from rheo sweep

     icSum.Rheo(ClNr,1) = round(min(I(passRts==passRts(rheoIdx))));        % get minimum current stimulus of all sweeps with the number of spikes of rheobase sweep  
 
     StimOnIdx = IcephysTab.responses.response.data.load.idx_start(...
                                                         PS.rheoSwpTabPos);
     StimOnTi = double(StimOnIdx)*1000/PS.rheoSwpSers.starting_time_rate;
     icSum.lat(ClNr,1) = PS.rheoSwpDat.map('thresTi').data(1)- StimOnTi;   % get AP latency as threshold time                                                                             % into time in milliseconds)                                                                                                
     icSum.widTP_LP(ClNr,1) = PS.rheoSwpDat.map('wiTP').data(1);           % get AP width from Rheo sweep
     icSum.peakLP(ClNr,1) = round(PS.rheoSwpDat.map('peak').data(1),2);    % get AP peak from Rheo sweep
     icSum.thresLP(ClNr,1) = round(PS.rheoSwpDat.map('thres').data(1),2);  % get AP threshold from Rheo sweep
     icSum.fTrghLP(ClNr,1) = round(PS.rheoSwpDat.map('fTrgh').data(1),2);  % get fast through from Rheo sweep
     icSum.sTrghLP(ClNr,1) = round(PS.rheoSwpDat.map('sTrgh').data(1),2);  % get slow through from Rheo sweep
     icSum.peakUpStrkLP(ClNr,1) = round(PS.rheoSwpDat.map(...
         'peakUpStrk').data(1),2);                                         % get peak up stroke from Rheo sweep
     icSum.peakDwStrkLP(ClNr,1) = round(PS.rheoSwpDat.map(...
         'peakDwStrk').data(1),2);                                         % get peak down stroke from Rheo sweep
     icSum.peakStrkRatLP(ClNr,1) = round(PS.rheoSwpDat.map(...
                                                 'peakStrkRat').data(1),2);% get peak stroke ratio from Rheo sweep  
     icSum.htTP_LP(ClNr,1) = round(PS.rheoSwpDat.map('htTP').data(1),2);   % get AP height from Rheo sweep
    end
   end
  %% Hero sweep selection         
   if ~isnan(icSum.Rheo(ClNr,1))                                           % if Rheo is not Nan i.e. there is a rheo base sweep
    if icSum.Rheo(ClNr,1) < 60                                             % if the Rheo is lower than 60 pA
     target = round(icSum.Rheo(ClNr,1),-1)+30;                             % target current is Rheo + 30 pA
     targets = [ target-10 target-5 target target+5 target+10 ...
              target+15 target+20 target+25 target+30];
    elseif icSum.Rheo(ClNr,1) < 180 
     target = round(icSum.Rheo(ClNr,1),-1)+80;                             % target current is Rheo + 80 pA
     targets = [target-20 target-10 target target+10 target+15 target+20 target+25 ...
               target+30 target+35 target+40 target+45 target+50];
    else 
     target = round(icSum.Rheo(ClNr,1),-1)+110;                            % target current is Rheo + 140 pA
     targets = [target-30 target-20 target-10 target target+10 target+20 ...
                        target+30 target+40 target+50];
    end 
    while ~any(passRts(ismember(I,targets))>1)  && max(targets) < 1200     % if any of the potential hero sweep has more than one spike
        target = unique(max(targets));                                     % get current steps that are both target for a herosweep and part of the LP protocols that passed QC      
        targets = [target+10 target+20 target+30 target+40 target+50];      
    end
    temp = I(ismember(I,targets));
    PoHeroAmps = LPampsQC(ismember(LPampsQC,...
                                 temp(passRts(ismember(I,targets))>1)));   
    if ~isempty(PoHeroAmps)
      PoHeroAmpsPos = find(abs(PoHeroAmps-target)==...
        min(abs(PoHeroAmps-target)),1,'last');                             % find position of the current step that is the closest to the target, take the last if there are multiple
      [~, heroSwpPos] = min(abs(LPampsQC-PoHeroAmps(PoHeroAmpsPos)));      % get position of potential hero sweeps 
      PS.heroSwpTabPos = find(all([round(SwpAmps.load)==LPampsQC(heroSwpPos), ...
                                                       LPIdx],2));         % get potential hero sweep table position
      heroID = str2double(regexp([SwpRespTbl(PS.heroSwpTabPos).path], '\d*','Match'));%   
      heroProModAPPos = endsWith(APwave.keys,['_',num2str(heroID(1))]);      % position of hero sweep in AP wave processing moduls
      if isempty(find(heroProModAPPos))
       heroID = [];
      else
       heroSwpAPDat = APwave.values{heroProModAPPos}.vectordata;              % 
      end    
    end
    if exist("heroID") && ~isempty(heroID)                                 % if there are potential hero sweep names
     PosSpTrain = find(ismember(spPatr.map('AP Pattern parameter'...
      ).vectordata.map('SwpID').data, num2str(heroID(1))));                % saves the position of the spPatr module that matches the first current potential hero sweep
     if ~isempty(PosSpTrain)
      PS.heroSwpAPPDat = getRow(spPatr.values{1}, PosSpTrain);   
     elseif length(heroID)>1
        PosSpTrain = find(str2double(LPsupraIDs)==heroID(end));  
        PS.heroSwpAPPDat = getRow(spPatr.values{1}, PosSpTrain);   
     end
    end
    if ~isempty(PS.heroSwpAPPDat)                                          % if there is a hero sweep
     PS.heroSwpSers = nwb.resolve(SwpPaths(PS.heroSwpTabPos(1)));          % get CCSeries of hero sweep 
     HeroStart = IcephysTab.responses.response.data.load(...
                                    PS.heroSwpTabPos(end)).idx_start;      % getting StimOnset for Hero sweep                                
     baseline = mean(PS.heroSwpSers.data.load(1:HeroStart));               % getting baseline Vm of herosweep for through ratio
     if checkVolts(PS.heroSwpSers.data_unit) && ...
             string(PS.heroSwpSers.description) ~= "PLACEHOLDER"
       baseline = baseline*1000;  
     end  
     if length(heroSwpAPDat.map('trgh').data)>1
       icSum.TrghRatio(ClNr,1) = round((heroSwpAPDat.map('trgh').data(1)...
         -baseline)/(heroSwpAPDat.map('trgh').data(end-1)-baseline),3);
       icSum.TrghDiff(ClNr,1) = heroSwpAPDat.map('trgh').data(1) -....
                                 heroSwpAPDat.map('trgh').data(end-1);
     end
     icSum.cvISI(ClNr,1) = round(PS.heroSwpAPPDat.cvISI,3);                % get cvISI
     icSum.HeroRt(ClNr,1) = PS.heroSwpAPPDat.firRt;                        % get firing rate of hero sweep  
     icSum.HeroAmp(ClNr,1) = LPampsQC(heroSwpPos(end));                    % get current amplitude of hero sweep
     icSum.heroLat(ClNr,1) = PS.heroSwpAPPDat.lat;                         % get latency of hero sweep
     icSum.peakAdapt(ClNr,1) = round(PS.heroSwpAPPDat.peakAdapt,3);              % get peak adaptation of hero sweep
     icSum.adaptIdx(ClNr,1) = round(PS.heroSwpAPPDat.adaptIdx2,3);         % get adaptation index of hero sweep 
     icSum.burst(ClNr,1) = round(PS.heroSwpAPPDat.burst,2);                % get bursting index of hero sweep 
     
   elseif length(PS.rheoSwpDat.map('htTP').data) > 3                       % if there is no hero sweep but rheobase has more than 3 spikes 
     PS.heroSwpSers = PS.rheoSwpSers; PS.heroSwpTabPos = PS.rheoSwpTabPos; % get rheo CCSeries as hero sweep  
     HeroStart = IcephysTab.responses.response.data.load(...
                                PS.heroSwpTabPos(end)).idx_start;          % getting StimOnset for Hero sweep                                
     baseline = mean(PS.heroSwpSers.data.load(1:HeroStart));               % getting baseline Vm of herosweep for through ratio
     if checkVolts(PS.heroSwpSers.data_unit) && ...
             string(PS.heroSwpSers.description) ~= "PLACEHOLDER"
       baseline = baseline*1000;  
     end
     heroSwpAPDat = APwave.values{rheoProModPos}.vectordata;                          
     icSum.TrghRatio(ClNr,1) = round((heroSwpAPDat.map('trgh').data(1)...
         -baseline)/(heroSwpAPDat.map('trgh').data(end-1)-baseline),3);
     icSum.TrghDiff(ClNr,1) = heroSwpAPDat.map('trgh').data(1) -....
                                 heroSwpAPDat.map('trgh').data(end-1);
     heroProModAPPPos = find(string(spPatr.values{1}.vectordata.map(...
         'SwpID').data)==string(RheoSwpID));                               % gets position of rheo sweep in AP Pattern dynamic table
     PS.heroSwpAPPDat = getRow(spPatr.values{1}, heroProModAPPPos);        % get Hero Sweep Data from spPatr module of rheo sweep
     icSum.cvISI(ClNr,1) = round(PS.heroSwpAPPDat.cvISI,3);                % get cvISI
     icSum.HeroRt(ClNr,1) = PS.heroSwpAPPDat.firRt;                        % get firing rate of hero sweep  
     icSum.HeroAmp(ClNr,1) =  icSum.Rheo(ClNr,1);                          % get current amplitude of hero sweep
     icSum.heroLat(ClNr,1) = PS.heroSwpAPPDat.lat;                         % get latency of hero sweep
     icSum.peakAdapt(ClNr,1) = round(PS.heroSwpAPPDat.peakAdapt,3);        % get peak adaptation of hero sweep
     icSum.adaptIdx(ClNr,1) = round(PS.heroSwpAPPDat.adaptIdx2,3);         % get adaptation index of hero sweep 
     icSum.burst(ClNr,1) = round(PS.heroSwpAPPDat.burst,2);                % get bursting index of hero sweep 
    else
        disp("No suitable hero sweep")
    end
   end
  end
 end
else  % required for runSummary because data format changes from double to DataStub
end