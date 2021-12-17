function [nwb, icSum, PltS] = LPsummary(nwb, icSum, ClNr, PS)

IcephysTab = nwb.general_intracellular_ephys_intracellular_recordings;     % Assign new variable for readability
SwpRespTbl = IcephysTab.responses.response.data.load.timeseries;           % Assign new variable for readability
SwpAmps = IcephysTab.stimuli.vectordata.values{1}.data;                    % Assign new variable for readability
qcParas = nwb.processing.map('QC parameter'...
                                     ).dynamictable.values{1}.vectordata;
qcPass = IcephysTab.dynamictable.map('quality_control_pass').vectordata;

if isa(qcPass.values{1}.data, 'double')                                    % Newly written entries into nwb object are doubles not DataStubs, hence there are two different forms of code needed to access them
  
  IdxPassSwps = all([qcPass.values{1}.data', contains(cellstr(...          % creates indices from a combined logical array                        
                          IcephysTab.dynamictable.map('protocol_type'...   % Gets logical array for passing QC (sweeps x 1) 
                           ).vectordata.values{1}.data.load),PS.LPtags)],2);    % Gets a logical array for sweeps being of the LP type                              
  SwpPaths = {SwpRespTbl.path};                               % Gets all sweep paths of sweep response table and assigns it to a new variable  
  SwpIDs = cellfun(@(a) str2double(a), cellfun(@(v)v(1),...            % Extract the numbers from the sweep names as doubles  
                                       regexp(SwpPaths,'\d*','Match'))); % inner cellfun necessary if sweep name contains mutliple numbers for example an extra AD01 
  IdPassSwps = SwpIDs(IdxPassSwps);                                    % Variable contains numbers of sweeps which passed QC  
  IdPassSwpsC = cellstr(string(IdPassSwps));
  %% subthreshold parameters  
  SubThres = nwb.processing.map('subthreshold parameters').dynamictable;   % Creating variable with all subthreshold data for readability     
  [icSum.RinHD(ClNr,1), icSum.RinOffset(ClNr,1)] = ...                    % Assign resistance and offset of cell in summary table
        inputResistance(SubThres,PS, IdPassSwps);                      % the function returns input resistance and offset calculated as slope of a linear fit and "membrane deflection" at 0 pA       
  icSum.RinSS(ClNr,1) = inputResisSS(SubThres, IdPassSwps, PS);       % same es previous lines but using steady state instead of highest deflection  
  icSum.rectI(ClNr,1) = rectification(SubThres,IdPassSwps);                % calculates the rectification index 
  %tau Vrest
  if ~isempty(qcParas.map('SweepID').data)                                 % if there are any QCed sweeps             
   qcTabIdx = find(ismember(regexp(cell2mat(qcParas.map('SweepID').data),...%Gets index of all passed LP sweeps  from cell  
                                             '\d*','Match'), IdPassSwpsC));  
   icSum.Vrest(ClNr,1) = round(nanmean(qcParas.map('Vrest').data(qcTabIdx)),2);  %calculates resting membrane potential as mean of prestim Vrest of all passed LP sweeps
  end
  %tau
  SubSwpIdx = find(endsWith(SubThres.keys, string(IdPassSwps)));
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
  passSuprIdx = ismember(SuprIDs, IdPassSwpsC); 
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
   
   if PS.plot_all == 1
     figure('visible','off');         cdfplot(1000./ISIs);
     grid off; box off; xlim([0 200]);xlabel('instantenous frequency (Hz)'); 
     title('Dynamic frequency range');
     export_fig(fullfile(PS.outDest, 'firingPattern', [PS.cellID , '_DFR']),...
                                                      PS.pltForm,'-r100');
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
      StartIdx = find(SpPatrTab.map('firRt').data==Close2Rheo);
    end
    
    if ~isempty(icSum.maxRt(ClNr,1))        
      MaxIdx = find(SpPatrTab.map('firRt').data==icSum.maxRt(ClNr,1));    
      StartSwpBinCount = table2array(getRow(spPatr.values{2},StartIdx));   % spike bin counts for start sweep 
      MaxSwpBinCount = table2array(getRow(spPatr.values{2},MaxIdx));       % spike bin counts for the sweep with maximum firing rate                        
      icSum.StimAdapB123(ClNr,1) = ...                                     % calculates an adaptiation ratio by
                     sum(StartSwpBinCount(1:3))/sum(MaxSwpBinCount(1:3));  % dividing spikes out of the first three bins from first by max sweeps  
      icSum.StimAdapB7_13(ClNr,1) = ...                                    % calculates an adaptiation ratio by
                     sum(StartSwpBinCount(7:13))/sum(MaxSwpBinCount(7:13));  % dividing spikes from 7th to last bin from first by max sweeps 
    end
    APPIdx = find(ismember(cellfun(@(v)v(1), regexp(SwpPaths,...           % Get index for location of suprathreshold sweeps 
                                       '\d*','Match')), cellstr(SuprIDs)));% in sweep response table                    
    I = SwpAmps.load(APPIdx);                                              % Get all stimulus amplitudes of suprathershold sweeps
    P = polyfit(I, SpPatrTab.map('firRt').data,1);                         % create a linear fit of I f curve                
    icSum.fIslope(ClNr,1) = round(P(1),3);                                % save slope as feature for cell

    if PS.plot_all == 1
     figure('visible','off'); hold on
     scatter(I, spPatr.values{1}.vectordata.map('firRt').data)
     yfit = P(1)*I+P(2);             plot(I,yfit,'r-.');
     xlabel('input current (pA)');   ylabel('firing frequency (Hz)')
     title('f/I curve');             box off; axis tight 
     export_fig(fullfile(PS.outDest, 'firingPattern', ...
                         [PS.cellID , ' fI_curve']),PS.pltForm,'-r100');
    end
   end
  end
  %% finding certain sweeps
  [sagSwpTabPos,rheoSwpTabPos, heroSwpTabPos] = deal([]);                  % initialize variabels to store sweep table position in plotting structure
  [sagSwpSers,rheoSwpSers, heroSwpSers] = deal(types.core.CurrentClampSeries);  % initialize variabels to store sweep series data in plotting structure                                          
  [rheoSwpDat, heroSwpDat] = deal([]);                                     % initialize variabels to store processed sweep data in plotting structure                       
     
  APwave = nwb.processing.map('AP wave').dynamictable;                     % variable for better readability
    
  if isa(SwpAmps, 'double')                                                % if current amplitude is double not a DataStub
    LPampsQC = SwpAmps(IdxPassSwps);                                       % assign current amplitudes  of sweeps that made the QC to variable
  else  
    LPampsQC = SwpAmps.load(find(IdxPassSwps));                            % assign current amplitudes  of sweeps that made the QC to variable
  end
  %% sag sweep                                                                                                                                                                             % the number of runs is lower than the number of sweep amplitudes +1    
  sagAmp = min(LPampsQC);                                                  % finds sag sweep amplitude 
  if (sagAmp < -70 && icSum.RinSS(ClNr,1) < 100) || ...
           (sagAmp <= -50 && icSum.RinSS(ClNr,1) > 100)
       
   sagSwpTabPos = any(SwpAmps.load==sagAmp,2);                             % get sag sweep table position  
   sagSwpID = regexp([SwpRespTbl(sagSwpTabPos).path],'\d*','Match');       % gets the sweep name from the last chunck                
   sagSwpDat = SubThres.values{contains(SubThres.keys, sagSwpID)}.vectordata;% get sag sweep data       
   if ~isempty(sagSwpDat)                                                  % if there is sag sweep data
    icSum.sagAmp(ClNr,1) = sagAmp;   
    icSum.sag(ClNr,1) = round(sagSwpDat.map('sag').data,2);                % save sag amplitude of sag sweep
    icSum.sagRat(ClNr,1) = round(sagSwpDat.map('sagRat').data,2);          % save ratio of sag sweep   
    icSum.sagVrest(ClNr,1) = round(qcParas.map('Vrest').data(sagSwpTabPos),2);% save membrane potential of sag sweep from the QC parameters in sweep table because these are always in mV!                                                                  %            
    sagSwpSers = nwb.resolve(SwpPaths(sagSwpTabPos));                      % save CC series to plot it later in the cell profile 
   end
  end
  %% rheobase sweeps and parameters of first spike
  if ~isempty(passRts)
   [icSum.rheoRt(ClNr,1), rheoIdx] = min(SpPatrTab.map('firRt').data(passSuprIdx));
   RheoSwpID = SuprIDs(rheoIdx);
   rheoProModPos = endsWith(APwave.keys,RheoSwpID);                         % save position of rheo sweep in sweep table
   rheoSwpDat = APwave.values{rheoProModPos}.vectordata;
   rheoSwpTabPos = find(endsWith(SwpPaths,RheoSwpID));                      % save position of rheo sweep in sweep table
   if ~isempty(rheoSwpDat)                                                  % if there is a rheo sweep
    rheoSwpSers = nwb.resolve(SwpRespTbl(rheoSwpTabPos).path);              % get CCSeries from rheo sweep                                                        
    icSum.Rheo(ClNr,1) = round(SwpAmps.load(rheoSwpTabPos));                % get current stimulus from rheo sweep from sweep table 
    StimOnIdx = IcephysTab.responses.response.data.load.idx_start(rheoSwpTabPos);
    StimOnTi = double(StimOnIdx)*1000/rheoSwpSers.starting_time_rate;
    icSum.lat(ClNr,1) = rheoSwpDat.map('thresTi').data(1)- StimOnTi;        % get AP latency as threshold time                                                                             % into time in milliseconds)                                                                                                
    icSum.widTP_LP(ClNr,1) = rheoSwpDat.map('wiTP').data(1);                % get AP width from Rheo sweep
    icSum.peakLP(ClNr,1) = round(rheoSwpDat.map('peak').data(1),2);         % get AP peak from Rheo sweep
    icSum.thresLP(ClNr,1) = round(rheoSwpDat.map('thres').data(1),2);       % get AP threshold from Rheo sweep
    icSum.fTrghLP(ClNr,1) = round(rheoSwpDat.map('fTrgh').data(1),2);       % get fast through from Rheo sweep
    icSum.sTrghLP(ClNr,1) = round(rheoSwpDat.map('sTrgh').data(1),2);       % get slow through from Rheo sweep
    icSum.peakUpStrkLP(ClNr,1) = round(rheoSwpDat.map('peakUpStrk').data(1),2);% get peak up stroke from Rheo sweep
    icSum.peakDwStrkLP(ClNr,1) = round(rheoSwpDat.map('peakDwStrk').data(1),2);% get peak down stroke from Rheo sweep
    icSum.peakStrkRatLP(ClNr,1) = round(rheoSwpDat.map('peakStrkRat').data(1),2);% get peak stroke ratio from Rheo sweep   
    icSum.htTP_LP(ClNr,1) = round(rheoSwpDat.map('htTP').data(1),2);        % get AP height from Rheo sweep
   end
  %% Hero sweep selection         
   if ~isnan(icSum.Rheo(ClNr,1))                                            % if Rheo is not Nan i.e. there is a rheo base sweep
    if icSum.Rheo(ClNr,1) < 60                                              % if the Rheo is lower than 60 pA
     target = round(icSum.Rheo(ClNr,1),-1)+30;                              % target current is Rheo + 30 pA
     targets = [ target-10 target target+10 ];
    else
     target = icSum.Rheo(ClNr,1)+70;                                        % target current is Rheo + 60 pA
     targets = [target-30 target-20 target-10 target target+10 target+20 target+30];
    end            
    PoHeroAmps = LPampsQC(ismember(LPampsQC,targets));
    [~, PoHeroAmpsPos] = min(abs(PoHeroAmps-target));
    [~, heroSwpPos] = min(abs(LPampsQC-PoHeroAmps(PoHeroAmpsPos)));         % get position of potential hero sweeps  
    heroSwpTabPos = find(any(SwpAmps.load==LPampsQC(heroSwpPos),2));        % get potential hero sweep table position
    heroID = str2double(regexp([SwpRespTbl(heroSwpTabPos).path], '\d*','Match'));%      
    if ~isempty(heroID)                                                     % if there are potential hero sweep names
    PosSpTrain = find(str2double(SuprIDs)==heroID(end));              % saves the position of the spPatr module that matches the last current potential hero sweep
     if ~isempty(PosSpTrain)
      heroSwpDat = getRow(spPatr.values{1}, PosSpTrain);   
     elseif length(heroID)>1
      PosSpTrain = find(str2double(SuprIDs)==heroID(1));              % saves the position of the spPatr module that matches 
      heroSwpDat = getRow(spPatr.values{1}, PosSpTrain);
     end
    end
    if ~isempty(heroSwpDat)                                                 % if there is a hero sweep
     heroSwpSers = nwb.resolve(SwpPaths(heroSwpTabPos(end)));              % get CCSeries of hero sweep 
     icSum.cvISI(ClNr,1) = round(heroSwpDat.cvISI,3);                      % get cvISI
     icSum.HeroRt(ClNr,1) = heroSwpDat.firRt;                            % get firing rate of hero sweep  
     icSum.HeroAmp(ClNr,1) = LPampsQC(heroSwpPos(end));                    % get current amplitude of hero sweep
     icSum.heroLat(ClNr,1) = heroSwpDat.lat;                           % get latency of hero sweep
     icSum.peakAdapt(ClNr,1) = round(heroSwpDat.peakAdapt,3);              % get peak adaptation of hero sweep
     icSum.adaptIdx(ClNr,1) = round(heroSwpDat.adaptIdx2,3);             % get adaptation index of hero sweep 
     icSum.burst(ClNr,1) = round(heroSwpDat.burst,2);                      % get bursting index of hero sweep 
    elseif length(rheoSwpDat.map('htTP').data) > 3                      % if there is no hero sweep but rheobase has more than 3 spikes 
     heroSwpSers = rheoSwpSers; heroSwpTabPos = rheoSwpTabPos;             % get rheo CCSeries as hero sweep            
     PosSpTrain = find(contains(SuprIDs, RheoSwpID));   
     heroSwpDat = getRow(spPatr.values{1}, PosSpTrain);                    % get Hero Sweep Data from spPatr module
     icSum.cvISI(ClNr,1) = round(heroSwpDat.cvISI,3);                      % get cvISI
     icSum.HeroRt(ClNr,1) = heroSwpDat.firRt;                            % get firing rate of hero sweep  
     icSum.HeroAmp(ClNr,1) =  icSum.Rheo(ClNr,1);                          % get current amplitude of hero sweep
     icSum.heroLat(ClNr,1) = heroSwpDat.lat;                           % get latency of hero sweep
     icSum.peakAdapt(ClNr,1) = round(heroSwpDat.peakAdapt,3);              % get peak adaptation of hero sweep
     icSum.adaptIdx(ClNr,1) = round(heroSwpDat.adaptIdx2,3);             % get adaptation index of hero sweep 
     icSum.burst(ClNr,1) = round(heroSwpDat.burst,2);                      % get bursting index of hero sweep 
    end
   end
  end
  %% Saving sweeps and data for plotting cell profile   
  PltS.heroSwpSers = heroSwpSers; PltS.heroSwpTabPos = heroSwpTabPos;      % save hero sweep CCseries and table position in structure for plotting later
  PltS.sagSwpTabPos = sagSwpTabPos; PltS.sagSwpSers = sagSwpSers;          % save sag sweep CCseries and position in sweep table
  PltS.rheoSwpTabPos = rheoSwpTabPos;                                      % save rheobase sweep table position in structure for plotting later
  PltS.rheoSwpSers = rheoSwpSers;  PltS.rheoSwpDat = rheoSwpDat;           % saves rheob data and CCSeries in plotting structure
else  % required for runSummary because data format changes from double to DataStub
  
end