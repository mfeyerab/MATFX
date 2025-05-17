function [icSum, PS] = LPsummary(nwb, icSum, ClNr, PS, QC, SubStats, SpPattrn, APTab)

IcephysTab = nwb.general_intracellular_ephys_intracellular_recordings;     % Assign new variable for readability
SwpRespTbl = IcephysTab.responses.response.data.load.timeseries;           % Assign new variable for readability
SwpAmps = IcephysTab.stimuli.vectordata.values{1}.data.load;               % Assign new variable for readability
Proto = strtrim(string(IcephysTab.vectordata.Map('protocol_type').data.load));
LPIdx = contains(cellstr(Proto),PS.LPtags);  
IdxPassSwps = QC.pass.QC_total_pass;                                       % creates indices from passing QC (sweeps x 1)and LP type indices                              
SwpPaths = {SwpRespTbl.path};                                              % Gets all sweep paths of sweep response table and assigns it to a new variable  
SwpIDs = cellfun(@(a) str2double(a), cellfun(@(v)v(1),...                  % Extract the numbers from the sweep names as doubles  
                                       regexp(SwpPaths,'\d*','Match')));   % inner cellfun necessary if sweep name contains mutliple numbers for example an extra AD01 
IdPassSwps = SwpIDs(IdxPassSwps);                                          % Variable contains numbers of sweeps which passed QC  
IdPassSwpsC = cellstr(string(IdPassSwps));
  
if ~isempty(IdPassSwps) & ~isempty(SubStats.SwpName)
  %% subthreshold parameters  
  [icSum.RinHD(ClNr), icSum.RinSS(ClNr)] = getRin(SubStats,PS, IdPassSwps);% Assign resistance of cell in summary table
  SubAmps = SubStats.SwpAmp;

  %Vrest
  icSum.Vrest(ClNr) = round(mean(...
                              QC.params.Vrest(IdxPassSwps),...
                                                   'all','omitmissing'),2);%calculates resting membrane potential as mean of prestim Vrest of all passed LP sweeps
  %tau
  Idx = SubStats.GFtau > PS.GF & SubAmps < 0 & ...
           SubStats.maxSubDeflection > PS.maxDefl & ...
            SubStats.maxSubDeflection <-2;
  if any(Idx)
   icSum.tau(ClNr) = round(mean(...
                         SubStats.tau(SubAmps==max(SubAmps(Idx)))...
                                                  ),2);                                                 
  end
  if PS.plot_all >= 2 && ~isempty(SubAmps(Idx))
   figure('Visible','off');
   scatter(SubAmps(Idx), SubStats.tau(Idx))
   xlim([min(SubAmps(Idx))-10 0])
   F=getframe(gcf);
   imwrite(F.cdata,fullfile(PS.outDest, 'tauFit', ...
                                   [PS.cellID,'_all_tau',PS.pltForm]))
  end                                                   
  %rectification 
  PS.RinHD = icSum.RinHD(ClNr); PS.RinSS = icSum.RinSS(ClNr);
  icSum = getRect(SubStats,IdPassSwps, PS, icSum, ClNr);                   % calculates the rectification index 

  %% firing patterns
  if iscell(SpPattrn.spTrainIDs) && ~isempty(SpPattrn.spTrainIDs)
   SuprIDs = cellfun(@(a) str2double(a), cellfun(@(v)v(1),...               % Extract the numbers from the sweep names as doubles  
                 regexp(SpPattrn.spTrainIDs,'\d*','Match')));
   passSuprIdx = ismember(IdPassSwps, SuprIDs); 
   StartLP = mode(...
       IcephysTab.responses.response.data.load.idx_start(LPIdx));
   SamR_LP = mode(...
       IcephysTab.responses.response.data.load.count(LPIdx));
   LPsupraIDs = IdPassSwps(passSuprIdx);
   [AllI, Ipass] = deal(round(SwpAmps(ismember(SwpIDs,LPsupraIDs))));              % Get all stimulus amplitudes of suprathershold long pulse sweeps
   [Iorder, Isorted] = sort(Ipass);
   ISIs = SpPattrn.ISIs;  
   passRts = SpPattrn.Tab.firingRate(ismember(SuprIDs,IdPassSwps));  
   passRtIDs = SpPattrn.spTrainIDs(ismember(SuprIDs,IdPassSwps));
   MaxIdxPass =[];
   if ~isempty(passRts)
    icSum.maxRt(ClNr) =  max(passRts);                                     % Maximum firing rate
    MaxIdxPass = find(max(passRts)==passRts,1,'last');
    [~,maxIdxAll] =max(passRts);
   end
   icSum.lastQuisc(ClNr) = min(SpPattrn.Tab.LastQuiesence);                % non-persistance of firing quantified as minimum time span from last spike to stimulus end from all sweeps
  % dynamic frequency range
  if  ~isempty(ISIs) && exist('maxIdxAll', 'var')                          %if ISI module exists and is not empty
   ISIexport = table();
   ISIexport.SweepID = SpPattrn.spTrainIDs;
   for r=1:length(ISIs)
      ISIexport.ISIs(r) =  ISIs(r);
   end
   writetable(ISIexport, fullfile(PS.outDest, 'firingPattern', ...
                                  [PS.cellID,'_ISIs.csv']));
   ISImat = horzcat(ISIs{:}); ISImat(isnan(ISImat))=[];

   if length(ISImat) > 7 && 1000./median(ISImat) > 2
     [data, edges] = histcounts(...
              1000./ISImat,65,'Normalization','cdf','BinLimits', [0 375]);

    icSum.medInstaRt(ClNr) = round(1000/median(ISImat),2);       
    icSum.DFR_P90(ClNr) = round(prctile(1000./ISImat, 90),2);           
    icSum.DFR_P10(ClNr) = round(prctile(1000./ISImat, 10),2); 
    icSum.DFR_IQR(ClNr) = round(prctile(1000./ISImat, 75) - ...
       prctile(1000./ISImat, 25),2);
    icSum.DFR_P90(ClNr) = round(prctile(1000./ISImat, 90),2);           

   end

   % adaptation   
   icSum.AdaRatB1B2(ClNr) = ...                                            % divides the sum of all spikes in the second bin
        round(sum(SpPattrn.BinTbl(1:MaxIdxPass,2))/...
              sum(SpPattrn.BinTbl(1:MaxIdxPass,1)),2);                     % by the sum of all spikes in the first bin                    
   SumLastBin = 0; Bcount=13;
   while SumLastBin == 0
    SumLastBin = sum(SpPattrn.BinTbl(1:MaxIdxPass,Bcount));
    Bcount = Bcount -1;
   end
   icSum.AdaRatB1BLast(ClNr) = ...                                         % divides the sum of all spikes in the last bin
       round(SumLastBin/sum(SpPattrn.BinTbl(1:MaxIdxPass,1)),2);           % by the sum of all spikes in the first bin                         
    RtsSort = passRts(Isorted);
    MaxIdxPass = find(max(passRts)==RtsSort,1,'first');
    if length(1:MaxIdxPass)>2
     P = robustfit(Iorder(1:MaxIdxPass),  RtsSort(1:MaxIdxPass));                  % create a linear fit of I f curve                
     icSum.fIslope(ClNr) = round(P(2),3);                                  % save slope as feature for cell

     if PS.plot_all >= 1
      figure('visible','off', 'Position', [128 320 1204 658]);
      %rasterplot
      subplot(2,3,1);rasterplot(SpPattrn.SpTimes')
      xlim([StartLP-10 StartLP+SamR_LP+10])
      set(gca, 'visible', 'off')
      %I-f curve 
      subplot(2,3,2); hold on;
      scatter(Ipass, passRts)
      yfit = P(2)*Ipass+P(1);             plot(Ipass,yfit,'r-.');
      xlabel('input current (pA)');   ylabel('firing frequency (Hz)')
      title('f/I curve');             box off; axis tight 
      subplot(2,3,3); hold on;
      %Adaptation over stimulus
      scatter(Ipass,SpPattrn.Tab.adaptIndex(ismember(SuprIDs,IdPassSwps)))
      title('Adaptation Index 1 over stim'); 

      subplot(2,3,5);     
      scatter(Ipass,SpPattrn.Tab.burst(ismember(SuprIDs,IdPassSwps)))
      title('burst over stim'); 

      subplot(2,3,6);  
      scatter(Ipass,SpPattrn.Tab.cvISI(ismember(SuprIDs,IdPassSwps)))
      title('cvISI over stim'); 

      subplot(2,3,4); 
      if ~isempty(ISImat) 
       cdfplot(1000./ISImat); grid off; box off;hold on;
      end

      if prctile(1000./ISImat,99) < 200
        xlim([0 200]);
      else
        xlim([0 350]);
      end
      xlabel('instantenous frequency (Hz)'); 
      title('Dynamic frequency range');
      F=getframe(gcf);
      imwrite(F.cdata,fullfile(PS.outDest, 'firingPattern', ...
                                  [PS.cellID,'_firingPattern',PS.pltForm]))
     end
    end
   end
   end
  else
    return
  end
  %% finding certain sweeps
  LPampsQC = round(SwpAmps(IdxPassSwps & LPIdx));                                  % assign current amplitudes  of sweeps that made the QC to variable

  %% sag sweep                                                                                                                                                                             % the number of runs is lower than the number of sweep amplitudes +1    
  PotSagAmps = sort(LPampsQC(LPampsQC<0), 'descend');                      % finds sag sweep amplitude 
  SubIDs =  regexp([SubStats.SwpName{:}],'\d*','Match');

  PotSagIdx = ismember(round(SubStats.SwpAmp),PotSagAmps) & ...
              SubStats.maxSubDeflection < PS.maxDefl &...
              ismember(SubIDs', IdPassSwpsC);
  if length(SubStats.SwpAmp(PotSagIdx)) > 1
   [~, temp] = max(SubStats.SwpAmp(PotSagIdx));  
   PotSagIdx = find(PotSagIdx);
   PotSagIdx = PotSagIdx(temp);
  else
      [~,PotSagIdx] = min(round(SubStats.SwpAmp) & ...
                           ismember(SubIDs', IdPassSwpsC));
      if SubStats.SwpAmp(PotSagIdx) >0 
          PotSagIdx = 0;
      end
  end
  if any(PotSagIdx)
    icSum.sagAmp(ClNr) = round(SubStats.SwpAmp(PotSagIdx));  
    icSum.sag(ClNr) = round(SubStats.sag(PotSagIdx),2);                    % save sag amplitude of sag sweep
    icSum.sagRat(ClNr) = round(SubStats.sagRat(PotSagIdx),2);              % save ratio of sag sweep   
    icSum.sagVrest(ClNr) = round(SubStats.baseVm(PotSagIdx),2);            % save membrane potential of sag sweep from the QC parameters in sweep table because these are always in mV!                                                                  %            
    PS.sagSwpTabPos = find(ismember(SwpIDs,...
                                  str2num(SubIDs{PotSagIdx})));
    PS.sagSwpSers = nwb.resolve(['/acquisition/', ...
                             char(SubStats.SwpName(PotSagIdx))]);          % save CC series to plot it later in the cell profile  
  else
    disp('No appropiate sag sweep')
  end
  %% rheobase sweeps and parameters of first spike
  if exist('LPsupraIDs', 'var') && ~isempty(passRts)
   rheoIdx = find(passRts <= median(passRts) & Ipass <= max(Ipass)/2);
   if ~isempty(rheoIdx) && length(unique(passRts(rheoIdx)))>1
       [maxPotRheoRt, tempIdx] = max(passRts(rheoIdx));
       while maxPotRheoRt > 1 && ...
           any(Ipass(passRts < maxPotRheoRt) < min(Ipass(passRts == maxPotRheoRt)))
         rheoIdx(tempIdx) = [];
         [maxPotRheoRt, tempIdx] = max(passRts(rheoIdx));
       end
       if length(rheoIdx)>1
          rheoIdx = rheoIdx(1);
       end
   elseif length(passRts)==1
     rheoIdx=1;
   elseif ~isempty(rheoIdx)
        [~,temp] = min(Ipass(rheoIdx));
        rheoIdx = rheoIdx(temp);
   else
     [~, rheoIdx]= min(Ipass);
   end
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
    PS.rheoSwpTabPos = find(endsWith(SwpPaths,...
                                           ['_', num2str(RheoSwpID(1))]));  
    APTabPos= find(endsWith(APTab.SweepID,['_', num2str(RheoSwpID(1))]));  
    if ~isempty(PS.rheoSwpTabPos)                                          % if there is a rheo sweep
     PS.rheoSwpSers = nwb.resolve(SwpRespTbl(PS.rheoSwpTabPos).path);      % get CCSeries from rheo sweep
     RheoStart = single(IcephysTab.responses.response.data.load.idx_start(...
                                                         PS.rheoSwpTabPos));
     icSum.Rheo(ClNr) = round(min(Ipass(passRts==passRts(rheoIdx))));        % get minimum current stimulus of all sweeps with the number of spikes of rheobase sweep  
     icSum.rheoRt(ClNr) = passRts(rheoIdx);

     Temp = APTab.thresTi{APTabPos} - RheoStart;
     icSum.lat(ClNr) = round(Temp(1)*1000/PS.SwDat.sampleRT,2);                  % get AP latency as threshold time                                                                             % into time in milliseconds)                                                                                                
     Temp = APTab.wiTP{APTabPos}; icSum.widTP_LP(ClNr) = round(Temp(1),2); % get AP width from Rheo sweep
     Temp = APTab.thres{APTabPos}; icSum.thresLP(ClNr) = round(Temp(1),2);
     Temp = APTab.peak{APTabPos}; icSum.peakLP(ClNr) = round(Temp(1),2);
     Temp = APTab.fTrgh{APTabPos}; icSum.fTrghLP(ClNr) = round(Temp(1),2);
     Temp = APTab.sTrgh{APTabPos}; icSum.sTrghLP(ClNr) = round(Temp(1),2);
     Temp = APTab.peakUpStrk{APTabPos};
     icSum.peakUpStrkLP(ClNr) = round(Temp(1),2);
     Temp = APTab.peakDwStrk{APTabPos};
     icSum.peakDwStrkLP(ClNr) = round(Temp(1),2);  
     Temp = APTab.peakStrkRat{APTabPos};
     icSum.peakStrkRatLP(ClNr) = round(Temp(1),2); 
     Temp = APTab.htTP{APTabPos}; icSum.htTP_LP(ClNr) = round(Temp(1),2);
     PS.RheoStart = RheoStart;
    end
   end
  end
  %% Hero sweep selection   
   if ~isnan(icSum.Rheo(ClNr))                                             % if Rheo is not Nan i.e. there is a rheo base sweep 
    if length(passRts)>3 && any(passRts>1) && max(passRts)>2
      [~,max_po] = max(passRts);

      if icSum.rheoRt(ClNr) < 10
       tempRts = passRts(1:max_po)-min(passRts(1:max_po));
       [~, pos] = min(abs(tempRts-0.5*max(tempRts)));
      else
        [~, pos] = min(abs(passRts(1:max_po)-0.65*range(passRts(1:max_po))));
      end    
    elseif max(passRts)==2
       pos = find(passRts==2,1,'first');
    else
      [~, pos] = min(abs(Ipass-(min(Ipass)+0.6*range(Ipass))));      
    end
    heroID = passRtIDs(pos);   
    if isempty(heroID)   
        dips('Make rheo to hero')
    end
    if ~isempty(heroID)       
     PS.heroSwpTabPos = find(endsWith(...
                          {SwpRespTbl.path}, [char(heroID)]));             % get potential hero sweep table position
     PosSpTrain = find(ismember(SpPattrn.spTrainIDs, heroID{1}));          % saves the position of the spPatr module that matches the first current potential hero sweep
     PS.heroSwpSers = nwb.resolve(SwpPaths(PS.heroSwpTabPos(1)));          % get CCSeries of hero sweep 
     HeroStart = IcephysTab.responses.response.data.load.idx_start(...
                                    PS.heroSwpTabPos(end));                % getting StimOnset for Hero sweep                                
     icSum.cvISI(ClNr) = round(SpPattrn.Tab.cvISI(PosSpTrain),3);          % get cvISI
     icSum.HeroRt(ClNr) = SpPattrn.Tab.firingRate(PosSpTrain);             % get firing rate of hero sweep  
     icSum.HeroAmp(ClNr) = Ipass(pos);                                     % get current amplitude of hero sweep
     icSum.heroLat(ClNr) = round(SpPattrn.Tab.latency(PosSpTrain),2);      % get latency of hero sweep
     icSum.peakAda(ClNr) = SpPattrn.Tab.peakAdapt(PosSpTrain);             % get peak adaptation of hero sweep
     icSum.AdaIdx(ClNr) = SpPattrn.Tab.adaptIndex(PosSpTrain);             % get adaptation index of hero sweep   
     icSum.burst(ClNr) = round(SpPattrn.Tab.burst(PosSpTrain),3);          % get bursting index of hero sweep     
     if length(APTab.trgh{PosSpTrain})>1
        icSum.TrghDiff(ClNr)= APTab.trgh{PosSpTrain}(1)-...
         APTab.trgh{PosSpTrain}(end);
        HeroVrest = QC.params.Vrest(string(QC.params.SweepID)== ...
                              string(APTab.SweepID{PosSpTrain}));
        icSum.TrghRatio(ClNr)= (APTab.trgh{PosSpTrain}(1)-HeroVrest)/...
         (APTab.trgh{PosSpTrain}(end)-HeroVrest);
     end

    else
        disp("No suitable hero sweep")
    end
  end
  end