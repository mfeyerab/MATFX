function [icSum, PS] = LPsummary(nwb, icSum, ClNr, PS)

IcephysTab = nwb.general_intracellular_ephys_intracellular_recordings;     % Assign new variable for readability
SwpRespTbl = IcephysTab.responses.response.data.load.timeseries;           % Assign new variable for readability
SwpAmps = IcephysTab.stimuli.vectordata.values{1}.data;                    % Assign new variable for readability
qcParas = nwb.processing.map('QC parameter'...
                                     ).dynamictable.values{1}.vectordata;
qcPass = IcephysTab.dynamictable.map('quality_control_pass').vectordata;

LPIdx = contains(cellstr(IcephysTab.dynamictable.map('protocol_type'...
                     ).vectordata.values{1}.data.load),PS.LPtags);

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
  [icSum.RinHD(ClNr,1), icSum.RinOffset(ClNr,1)] = ...                     % Assign resistance and offset of cell in summary table
        inputResistance(SubThres,PS, IdPassSwps);                          % the function returns input resistance and offset calculated as slope of a linear fit and "membrane deflection" at 0 pA       
  icSum.RinSS(ClNr,1) = inputResisSS(SubThres, IdPassSwps, PS);            % same es previous lines but using steady state instead of highest deflection  
  icSum.rectI(ClNr,1) = rectification(SubThres,IdPassSwps);                % calculates the rectification index 
  %tau Vrest
  if ~isempty(qcParas.map('SweepID').data)                                 % if there are any QCed sweeps             
   qcTabIdx = find(ismember(regexp(cell2mat(qcParas.map('SweepID').data),...%Gets index of all passed LP sweeps  from cell  
                                             '\d*','Match'), IdPassSwpsC));  
   icSum.Vrest(ClNr,1) = round(nanmean(qcParas.map('Vrest').data(qcTabIdx)),2);  %calculates resting membrane potential as mean of prestim Vrest of all passed LP sweeps
  end
  %tau
  SubSwpIdx = find(endsWith(SubThres.keys, ['_',string(IdPassSwps)]));
  tauVec = nan(length(SubSwpIdx),1);
  for s = 1:length(SubSwpIdx)                                              % for each subthreshold sweep 
   if SubThres.values{SubSwpIdx(s)}.vectordata.map('GFtau').data > PS.GF 
     tauVec(s,1)=SubThres.values{SubSwpIdx(s)}.vectordata.map('tau').data;
   end         
  end    
  if length(tauVec) < 3 && ~isempty(tauVec)                                % if there are less than three values AND vector in not empty
   icSum.tau(ClNr,1) = round(nanmean(tauVec(length(tauVec))),2);           % cell wide tau is calculated by mean sweep taus
  elseif ~isempty(tauVec)                                                  % if there are 3 or more sweep taus 
   icSum.tau(ClNr,1) = round(mean(mink(tauVec,3)),2);                      % cell wide tau is calculated by mean of first three sweep taus
  end
  %% firing patterns
  spPatr = nwb.processing.map('AP Pattern').dynamictable;                  
  SpBinTab = nwb.processing.map('AP Pattern').dynamictable.values{2}.vectordata;                                    
  SpPatrTab = nwb.processing.map('AP Pattern').dynamictable.values{1}.vectordata;% assign variable for readability

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
   
   if PS.plot_all >= 1 && ~isempty(ISIs)
     figure('visible','off');         cdfplot(1000./ISIs);
     grid off; box off; xlim([0 200]);xlabel('instantenous frequency (Hz)'); 
     title('Dynamic frequency range');
     exportgraphics(gcf,fullfile(PS.outDest, 'firingPattern', [PS.cellID,' TP profile',PS.pltForm]))     
   end            
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
    if ~isempty(icSum.maxRt(ClNr,1)) && exist('Close2Rheo') && ~isempty(Close2Rheo)       
      MaxIdx = find(SpPatrTab.map('firRt').data==icSum.maxRt(ClNr,1));    
      StartSwpBinCount = table2array(getRow(spPatr.values{2},StartIdx));   % spike bin counts for start sweep 
      MaxSwpBinCount = table2array(getRow(spPatr.values{2},MaxIdx));       % spike bin counts for the sweep with maximum firing rate                        
      icSum.StimAdapB123(ClNr,1) = ...                                     % calculates an adaptiation ratio by
                     sum(StartSwpBinCount(1:3))/sum(MaxSwpBinCount(1:3));  % dividing spikes out of the first three bins from first by max sweeps  
      icSum.StimAdapB7_13(ClNr,1) = ...                                    % calculates an adaptiation ratio by
                     sum(StartSwpBinCount(7:13))/sum(MaxSwpBinCount(7:13));% dividing spikes from 7th to last bin from first by max sweeps 
    end              
    I = SwpAmps.load(find(ismember(SwpIDs,cellfun(@str2num,LPsupraIDs)))); % Get all stimulus amplitudes of suprathershold long pulse sweeps
    if length(I)>2
     P = robustfit(I, passRts);                                            % create a linear fit of I f curve                
     icSum.fIslope(ClNr,1) = round(P(1),3);                                % save slope as feature for cell

     if PS.plot_all >= 1
      figure('visible','off'); hold on
      scatter(I, passRts)
      yfit = P(2)*I+P(1);             plot(I,yfit,'r-.');
      xlabel('input current (pA)');   ylabel('firing frequency (Hz)')
      title('f/I curve');             box off; axis tight 
      exportgraphics(gcf, fullfile(PS.outDest, 'firingPattern', ...
                         [PS.cellID , ' fI_curve', PS.pltForm]));
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
    LPampsQC = round(SwpAmps.load(find(IdxPassSwps)));                     % assign current amplitudes  of sweeps that made the QC to variable
  end
  %% sag sweep                                                                                                                                                                             % the number of runs is lower than the number of sweep amplitudes +1    
  sagAmp = min(LPampsQC);                                                  % finds sag sweep amplitude 
  if (sagAmp < -70 && icSum.RinSS(ClNr,1) < 100) || ...
           (sagAmp <= -50 && icSum.RinSS(ClNr,1) > 100)
   tempIdx = find(all([round(SwpAmps.load(find(LPIdx)))==sagAmp; ...
                  qcPass.values{1}.data(LPIdx)],1));                 
   if length(tempIdx) >1
     for i=1:length(tempIdx)  
      temp = find(LPIdx,tempIdx(i), 'first');
      PS.sagSwpTabPos(i) = temp(end);
     end                                                                   % get sag sweep table position 
     sagSwpID = regexp([SwpRespTbl(PS.sagSwpTabPos).path],'\d*','Match');  % gets the sweep name from the last chunck                          
     StimOn = IcephysTab.responses.response.data.load.idx_start(PS.sagSwpTabPos);
     SagData = cell(sum(StimOn==mode(StimOn)),1);
     for s=1:length(sagSwpID)       
      if StimOn(s)==mode(StimOn)
         SagData{s,1}  = SubThres.values{endsWith(...
                              SubThres.keys,['_',sagSwpID{s}])}.vectordata;   
      end
     end
     SagIdx = StimOn==mode(StimOn);
     icSum.sagAmp(ClNr,1) = sagAmp;   
     icSum.sag(ClNr,1) = round(mean(cellfun(@(x) ...
                     x.map('sag').data,SagData(SagIdx))),2);               % save sag amplitude of sag sweep
     icSum.sagRat(ClNr,1) = round(mean(cellfun(@(x) ...
                        x.map('sagRat').data,SagData(SagIdx))),2);         % save ratio of sag sweep   
     icSum.sagVrest(ClNr,1) = round(mean(qcParas.map('Vrest').data(...
         PS.sagSwpTabPos(SagIdx))),2);                                     % save membrane potential of sag sweep from the QC parameters in sweep table because these are always in mV!                                                                  %            
     PS.sagSwpSers = nwb.resolve(SwpPaths(PS.sagSwpTabPos(SagIdx)));       % save CC series to plot it later in the cell profile          
   else
    temp = find(LPIdx,tempIdx, 'first');
    PS.sagSwpTabPos = temp(end);
    sagSwpID = regexp([SwpRespTbl(PS.sagSwpTabPos).path],'\d*','Match');  % gets the sweep name from the last chunck                          
    sagSwpDat = SubThres.values{endsWith(...
                        SubThres.keys,['_',sagSwpID{1}])}.vectordata;      % get sag sweep data
    if ~isempty(sagSwpDat)                                                 % if there is sag sweep data
     icSum.sagAmp(ClNr,1) = sagAmp;   
     icSum.sag(ClNr,1) = round(sagSwpDat.map('sag').data,2);               % save sag amplitude of sag sweep
     icSum.sagRat(ClNr,1) = round(sagSwpDat.map('sagRat').data,2);         % save ratio of sag sweep   
     icSum.sagVrest(ClNr,1) = round(qcParas.map('Vrest').data(...
                                                  PS.sagSwpTabPos(end)),2);% save membrane potential of sag sweep from the QC parameters in sweep table because these are always in mV!                                                                  %            
     PS.sagSwpSers = nwb.resolve(SwpPaths(PS.sagSwpTabPos(end)));          % save CC series to plot it later in the cell profile 
    end
   end
  end
  %% rheobase sweeps and parameters of first spike
  if iscell(LPsupraIDs) && ~isempty(passRts)
   [icSum.rheoRt(ClNr,1), rheoIdx] = ...
       min(SpPatrTab.map('firRt').data(passSuprIdx));
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
     icSum.Rheo(ClNr,1) = round(SwpAmps.load(PS.rheoSwpTabPos));           % get current stimulus from rheo sweep from sweep table 
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
     targets = [ target-10 target target+10 target+20 target+30 ];
    elseif icSum.Rheo(ClNr,1) < 180 
     target = icSum.Rheo(ClNr,1)+80;                                       % target current is Rheo + 70 pA
     targets = [target+10 target+20 target+30 target+40 target+50];
    else 
     target = icSum.Rheo(ClNr,1)+140;                                      % target current is Rheo + 70 pA
     targets = [target+10 target+20 target+30 target+40 target+50];
    end            
    PoHeroAmps = LPampsQC(ismember(LPampsQC,targets));
    if ~isempty(PoHeroAmps)
    PoHeroAmpsPos = find(abs(PoHeroAmps-target)==...
        min(abs(PoHeroAmps-target)),1,'last');
    [~, heroSwpPos] = min(abs(LPampsQC-PoHeroAmps(PoHeroAmpsPos)));        % get position of potential hero sweeps  
    PS.heroSwpTabPos = find(all([round(SwpAmps.load)==LPampsQC(heroSwpPos), ...
                                                                LPIdx],2));% get potential hero sweep table position
    heroID = str2double(regexp([SwpRespTbl(PS.heroSwpTabPos).path], '\d*','Match'));%   
    heroProModAPPos = endsWith(APwave.keys,['_',num2str(heroID(1))]);      % position of hero sweep in AP wave processing moduls
      if isempty(find(heroProModAPPos))
       heroID = [];
      else
       heroSwpAPDat = APwave.values{heroProModAPPos}.vectordata;              % 
      end    
    end
    if exist("heroID") && ~isempty(heroID)                                 % if there are potential hero sweep names
     PosSpTrain = find(str2double(LPsupraIDs)==heroID(1));                    % saves the position of the spPatr module that matches the first current potential hero sweep
     if ~isempty(PosSpTrain)
      PS.heroSwpAPPDat = getRow(spPatr.values{1}, PosSpTrain);   
     end
    end
    if ~isempty(PS.heroSwpAPPDat)                                          % if there is a hero sweep
     PS.heroSwpSers = nwb.resolve(SwpPaths(PS.heroSwpTabPos(end)));        % get CCSeries of hero sweep 
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
    end
   end
  end
 end
else  % required for runSummary because data format changes from double to DataStub
end