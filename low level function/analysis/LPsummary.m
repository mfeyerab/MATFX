function [icSum, PS] = LPsummary(nwb, icSum, ClNr, PS)

IcephysTab = nwb.general_intracellular_ephys_intracellular_recordings;     % Assign new variable for readability
SwpRespTbl = IcephysTab.responses.response.data.load.timeseries;           % Assign new variable for readability
SwpAmps = IcephysTab.stimuli.vectordata.values{1}.data.load;               % Assign new variable for readability
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
  SubThres = nwb.processing.map(...
                      'subthreshold parameters').dynamictable.values{1};   % Creating variable with all subthreshold data for readability     
  SubStats.baseVm = SubThres.vectordata.map('baseVm').data';
  SubStats.SwpAmp = SubThres.vectordata.map('SwpAmp').data';
  SubStats.maxSubDeflection = ...
      SubThres.vectordata.map('maxSubDeflection').data';
  SubStats.sag = SubThres.vectordata.map('sag').data';
  SubStats.SwpName = SubThres.vectordata.map('SwpName').data';
  [icSum.RinHD(ClNr), icSum.RinSS(ClNr)] = getRin(SubStats,PS, IdPassSwps);% Assign resistance of cell in summary table
  SubAmps = SubStats.SwpAmp';

  %Vrest
  if ~isempty(qcParas.map('SweepID').data)                                 % if there are any QCed sweeps             
   qcTabIdx = find(ismember(regexp(cell2mat(qcParas.map('SweepID').data),...%Gets index of all passed LP sweeps  from cell  
                                             '\d*','Match'), IdPassSwpsC));  
   icSum.Vrest(ClNr) = round(nanmean(qcParas.map('Vrest').data(qcTabIdx)),2);  %calculates resting membrane potential as mean of prestim Vrest of all passed LP sweeps
  end
  %tau
  Idx = SubThres.vectordata.map('GFtau').data> PS.GF & SubAmps < 0 & ...
            SubThres.vectordata.map('maxSubDeflection').data> PS.maxDefl & ...
            SubThres.vectordata.map('maxSubDeflection').data <-2;
  if any(Idx)
   icSum.tau(ClNr) = round(mean(SubThres.vectordata.map('tau').data(...
                            SubAmps==max(SubAmps(Idx)))),2);                                                 
  end
  if PS.plot_all >= 2 && ~isempty(SubAmps(Idx))
   figure('Visible','off');
   scatter(SubAmps(Idx), SubThres.vectordata.map('tau').data(Idx))
   xlim([min(SubAmps(Idx))-10 0])
   F=getframe(gcf);
   imwrite(F.cdata,fullfile(PS.outDest, 'tauFit', ...
                                   [PS.cellID,'_all_tau',PS.pltForm]))
  end                                                   
  %rectification 
  PS.RinHD = icSum.RinHD(ClNr); PS.RinSS = icSum.RinSS(ClNr);
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
   AllI = round(SwpAmps(ismember(SwpIDs,cellfun(@str2num,SuprIDs))));      % Get all stimulus amplitudes of suprathershold long pulse sweeps
   Ipass = round(SwpAmps(ismember(SwpIDs,cellfun(@str2num,LPsupraIDs))));      % Get all stimulus amplitudes of suprathershold long pulse sweeps
   [Iorder, Isorted] = sort(Ipass);
   ISIs = spPatr.map('ISIs').vectordata.values{1}.data;  
   passRts = SpPatrTab.map('firRt').data(passSuprIdx);     
   passRtIDs = SpPatrTab.map('SwpID').data(passSuprIdx);     
   MaxIdxPass =[];
   if ~isempty(passRts)
    icSum.maxRt(ClNr) =  max(passRts);                                     % Maximum firing rate
    MaxIdxPass = find(max(passRts)==passRts,1,'last');
    [~,maxIdxAll] =max(SpPatrTab.map('firRt').data);
   end
   icSum.lastQuisc(ClNr) = min(SpPatrTab.map('lastQuisc').data);            % non-persistance of firing quantified as minimum time span from last spike to stimulus end from all sweeps
  % dynamic frequency range
  if spPatr.isKey('ISIs') && ~isempty(ISIs) && exist('maxIdxAll', 'var') && ...
                                            ~isempty(maxIdxAll)            %if ISI module exists and is not empty
   ISIIdx = spPatr.map('ISIs').vectordata.values{2}.data;   
   ISIexport = table();
   if length(unique(AllI(1:maxIdxAll)))~=length(AllI(1:maxIdxAll))
     disp('improve analysis here')
     [~,ia] =unique(AllI(1:maxIdxAll),'first');
     testIdx = find(SpPatrTab.map('firRt').data(ia)-1);
      for s=1:length(testIdx)
        ISIexport.SweepID(s) = SuprIDs(ia(testIdx(s)));
        ISIexport.SweepAmp(s) = AllI(ia(s));
        if ia(testIdx(s))==1
          ISIexport.ISIs(s) = {ISIs(1:ISIIdx(ia(testIdx(s))))};
        else
          ISIexport.ISIs(s) = {ISIs(...
            ISIIdx(ia(testIdx(s))-1)+1:...
            ISIIdx(ia(testIdx(s))))};
        end
      end
      ISIs = vertcat(ISIexport.ISIs{:});
   else
    ISIMaxIdx = ISIIdx(maxIdxAll);    
    testIdx = find(SpPatrTab.map('firRt').data(1:maxIdxAll)-1);
    for s=1:length(testIdx)
        ISIexport.SweepID(s) = SuprIDs(testIdx(s));
        ISIexport.SweepAmp(s) = AllI(testIdx(s));
        if testIdx(s)==1
          ISIexport.ISIs(s) = {ISIs(1:ISIIdx(testIdx(s)))};
        else
          ISIexport.ISIs(s) = {ISIs(...
            ISIIdx(testIdx(s)-1)+1:...
            ISIIdx(testIdx(s)))};
        end
    end
    if length(ISIs)~=ISIMaxIdx
      ISIs = ISIs(1:ISIMaxIdx);
    end
   end
   writetable(ISIexport, fullfile(PS.outDest, 'firingPattern', ...
                                  [PS.cellID,'_ISIs.csv']));
   ISIs = ISIs(~isnan(ISIs));ISIs(ISIs==0) = [];  % get rid of 0 and nans  

   if length(ISIs) > 7 && 1000./median(ISIs) > 2
     [data, edges] = histcounts(...
              1000./ISIs,65,'Normalization','cdf','BinLimits', [0 375]);

     SatP = find(data>0.99999,1,'first');
     if ~isempty(SatP) && SatP < length(data)
      NewData = interp1([data(1:SatP+1)],[1:0.5:SatP+1],'makima');
      NewEdges = interp1([edges(2:SatP+1)],[1:0.5:SatP+1],'linear');
      SatP = find(NewData>0.99999,1,'first');
     else
      NewData = interp1(data,[1:0.5:length(data)],'makima');
      NewEdges = interp1([edges(2:end)],[1:0.5:length(data)],'linear');
      SatP = find(NewData>0.99999,1,'first');  
     end
     if ~isempty(SatP)
      SloData = gradient(smooth(NewData(1:SatP),5));
     else
       SloData = gradient(smooth(NewData,5));  
     end
     [MaxConVal, MaxConP] = min(gradient(SloData(...
                                find(NewData>0.5,1,'first')-1:end)));
    icSum.SpanMaxCon2P99(ClNr) = ((abs(MaxConVal))*range(1000./ISIs))/...
             NewData(find(NewData>0.5,1,'first')-1+MaxConP);
    figure; plot(edges,[0, data]); hold on; plot(NewEdges, NewData);
     plot(NewEdges, smooth(NewData,5));  plot((NewEdges(...
       find(NewData>0.5,1,'first')+MaxConP) + ...
                   (NewEdges(2)-NewEdges(1))/2)*ones(2,1),[0 1])

      F=getframe(gcf);
      imwrite(F.cdata,fullfile(PS.outDest, 'firingPattern', ...
                                  [PS.cellID,'_firingPatternTest',PS.pltForm]))

      figure;plot(gradient(SloData))
      F=getframe(gcf);
      imwrite(F.cdata,fullfile(PS.outDest, 'firingPattern', ...
                                  [PS.cellID,'_firingPatternTest2',PS.pltForm]))


    icSum.medInstaRt(ClNr) = round(1000/median(ISIs),2);       
    icSum.DFR_P90(ClNr) = round(prctile(1000./ISIs, 90),2);           
    icSum.DFR_P10(ClNr) = round(prctile(1000./ISIs, 10),2); 
    icSum.DFR_IQR(ClNr) = round(prctile(1000./ISIs, 75) - ...
       prctile(1000./ISIs, 25),2);
    icSum.DFR_P90(ClNr) = round(prctile(1000./ISIs, 90),2);           
   disp(num2str(icSum.SpanMaxCon2P99(ClNr)))

   end

   % adaptation   
   icSum.AdaRatB1B2(ClNr) = ...                                            % divides the sum of all spikes in the second bin
        round(sum(SpBinTab.map('B2').data(1:MaxIdxPass))/...
        sum(SpBinTab.map('B1').data(1:MaxIdxPass)),2);                     % by the sum of all spikes in the first bin                    
   SumLastBin = 0; Bcount=13;
   while SumLastBin == 0
    SumLastBin = sum(SpBinTab.map(['B',num2str(Bcount)]).data(1:MaxIdxPass));
    Bcount = Bcount -1;
   end
   icSum.AdaRatB1BLast(ClNr) = ...                                         % divides the sum of all spikes in the last bin
       round(SumLastBin/sum(SpBinTab.map('B1').data(1:MaxIdxPass)),2);         % by the sum of all spikes in the first bin                         

   if ~isempty(SpBinTab.map('B1').data) && ~isempty(passRts)          
    if min(passRts) > 4
      StartIdx = find(SpPatrTab.map('firRt').data==min(passRts));
    else
      Close2Rheo = min(setdiff(passRts,min(passRts)));
      if ~isempty(Close2Rheo)          
       StartIdx = find(SpPatrTab.map('firRt').data==Close2Rheo);
      end
    end    
    if ~isempty(icSum.maxRt(ClNr)) && ...
            exist('Close2Rheo', 'var') && ~isempty(Close2Rheo)       
      MaxISIIdx = find(SpPatrTab.map('firRt').data==icSum.maxRt(ClNr));    
      StartSwpBinCount = table2array(getRow(spPatr.values{2},StartIdx));   % spike bin counts for start sweep 
      MaxSwpBinCount = table2array(getRow(spPatr.values{2},MaxISIIdx)); % spike bin counts for the sweep with maximum firing rate                        
      icSum.StimAdaB123(ClNr) = ...                                        % calculates an adaptiation ratio by
                     sum(StartSwpBinCount(1:3))/sum(MaxSwpBinCount(1:3));  % dividing spikes out of the first three bins from first by max sweeps  
      icSum.StimAdaB7_13(ClNr) = ...                                       % calculates an adaptiation ratio by
                     sum(StartSwpBinCount(7:13))/sum(MaxSwpBinCount(7:13));% dividing spikes from 7th to last bin from first by max sweeps 
    end
    RtsSort = passRts(Isorted);
    MaxIdxPass = find(max(passRts)==RtsSort,1,'first');
    if length(1:MaxIdxPass)>2
     P = robustfit(Iorder(1:MaxIdxPass),  RtsSort(1:MaxIdxPass));                  % create a linear fit of I f curve                
     icSum.fIslope(ClNr) = round(P(2),3);                                  % save slope as feature for cell

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
      xlim([0 1010])
      %I-f curve 
      subplot(2,3,2); hold on;
      scatter(Ipass, passRts)
      yfit = P(2)*Ipass+P(1);             plot(Ipass,yfit,'r-.');
      xlabel('input current (pA)');   ylabel('firing frequency (Hz)')
      title('f/I curve');             box off; axis tight 
      subplot(2,3,3); hold on;
      %Adaptation over stimulus
      temp = spPatr.values{1}.vectordata.map('SwpID').data;
      [~,order] = sort(temp);
      SupIdx = ismember(spPatr.values{1}.vectordata.map(...
                                        'SwpID').data(order), IdPassSwpsC);
      scatter(Ipass,getRow(spPatr.values{1},find(SupIdx)).adaptIdx)
      title('Adaptation Index 1 over stim'); 

      subplot(2,3,5);     
      scatter(Ipass,getRow(spPatr.values{1},find(SupIdx)).burst)
      title('burst over stim'); 

      subplot(2,3,6);  
      scatter(Ipass,getRow(spPatr.values{1},find(SupIdx)).cvISI)
      title('cvISI over stim'); 

      subplot(2,3,4); 
      if ~isempty(ISIs) 
       cdfplot(1000./ISIs); grid off; box off;hold on;
       if length(ISIs) > 7 && 1000./median(ISIs) > 2
              plot((NewEdges(...
                  find(NewData>0.5,1,'first')+MaxConP) + ...
                   (NewEdges(2)-NewEdges(1))/2)*ones(2,1),[0 1])
       end
      end

      if prctile(1000./ISIs,99) < 200
        xlim([0 200]);
      else
        xlim([0 350]);
      end
      xlabel('instantenous frequency (Hz)'); 
      title('Dynamic frequency range');
      if length(ISIs) > 7 && 1000./median(ISIs) > 2
        subtitle(['DwnConc: ',num2str(abs(round(...
                             MaxConVal*range(1000./ISIs),2)))])
      end
      
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
  APwave = nwb.processing.map('AP wave').dynamictable;                     % variable for better readability   
  LPampsQC = round(SwpAmps(IdxPassSwps));                                  % assign current amplitudes  of sweeps that made the QC to variable
%   SwpAmps2 = round(SwpAmps);

  %% sag sweep                                                                                                                                                                             % the number of runs is lower than the number of sweep amplitudes +1    
  PotSagAmps = sort(LPampsQC(LPampsQC<0), 'descend');                      % finds sag sweep amplitude 
  Data = SubThres.getRow(find(ismember(round(SubAmps),PotSagAmps)));
  SagData = Data(Data.maxSubDeflection < PS.maxDefl-2 &...
                   endsWith(Data.SwpName, string(IdPassSwps)),:);
  if isempty(SagData)
   SagData = Data(Data.maxSubDeflection == min(Data.maxSubDeflection) &...
                   endsWith(Data.SwpName, string(IdPassSwps)),:);
  end 
  if height(SagData)>1
      [~,SwpIdx] = max(SagData.SwpAmp);
      SagData = SagData(SwpIdx,:);
  end
  if ~isempty(SagData)
    icSum.sagAmp(ClNr) = round(SagData.SwpAmp);  
    icSum.sag(ClNr) = round(SagData.sag,2);                                  % save sag amplitude of sag sweep
    icSum.sagRat(ClNr) = round(SagData.sagRat,2);                            % save ratio of sag sweep   
    icSum.sagVrest(ClNr) = round(SagData.baseVm,2);                          % save membrane potential of sag sweep from the QC parameters in sweep table because these are always in mV!                                                                  %            
    PS.sagSwpTabPos = find(endsWith({SwpRespTbl.path},SagData.SwpName));
    PS.sagSwpSers = nwb.resolve(['/acquisition/', char(SagData.SwpName)]);   % save CC series to plot it later in the cell profile  
  else
    disp('No appropiate sag sweep')
  end
  %% rheobase sweeps and parameters of first spike
  if exist('LPsupraIDs', 'var') && iscell(LPsupraIDs) && ~isempty(passRts)
   rheoIdx = find(passRts' <= median(passRts) & Ipass < median(Ipass));
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
   else
        [~,rheoIdx] = min(Ipass);
   end
   icSum.rheoRt(ClNr) = passRts(rheoIdx);
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

     icSum.Rheo(ClNr) = round(min(Ipass(passRts==passRts(rheoIdx))));        % get minimum current stimulus of all sweeps with the number of spikes of rheobase sweep  
 
     StimOnIdx = IcephysTab.responses.response.data.load.idx_start(...
                                                         PS.rheoSwpTabPos);
     StimOnTi = double(StimOnIdx)*1000/PS.rheoSwpSers.starting_time_rate;
     icSum.lat(ClNr) = PS.rheoSwpDat.map('thresTi').data(1)- StimOnTi;   % get AP latency as threshold time                                                                             % into time in milliseconds)                                                                                                
     icSum.widTP_LP(ClNr) = PS.rheoSwpDat.map('wiTP').data(1);           % get AP width from Rheo sweep
     icSum.peakLP(ClNr) = round(PS.rheoSwpDat.map('peak').data(1),2);    % get AP peak from Rheo sweep
     icSum.thresLP(ClNr) = round(PS.rheoSwpDat.map('thres').data(1),2);  % get AP threshold from Rheo sweep
     icSum.fTrghLP(ClNr) = round(PS.rheoSwpDat.map('fTrgh').data(1),2);  % get fast through from Rheo sweep
     icSum.sTrghLP(ClNr) = round(PS.rheoSwpDat.map('sTrgh').data(1),2);  % get slow through from Rheo sweep
     icSum.peakUpStrkLP(ClNr) = round(PS.rheoSwpDat.map(...
         'peakUpStrk').data(1),2);                                         % get peak up stroke from Rheo sweep
     icSum.peakDwStrkLP(ClNr) = round(PS.rheoSwpDat.map(...
         'peakDwStrk').data(1),2);                                         % get peak down stroke from Rheo sweep
     icSum.peakStrkRatLP(ClNr) = round(PS.rheoSwpDat.map(...
                                                 'peakStrkRat').data(1),2);% get peak stroke ratio from Rheo sweep  
     icSum.htTP_LP(ClNr) = round(PS.rheoSwpDat.map('htTP').data(1),2);   % get AP height from Rheo sweep
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
      heroID = passRtIDs(pos);
    elseif max(passRts)==2
       pos = find(passRts==2,1,'first');
       heroID = passRtIDs(pos);   
    else
      [~, pos] = min(abs(Ipass-(min(Ipass)+0.6*range(Ipass))));
      heroID = passRtIDs(pos);   
    end
    if ~isempty(heroID)       
      PS.heroSwpTabPos = find(endsWith(...
                          {SwpRespTbl.path}, ['_',char(heroID)]));        % get potential hero sweep table position
      heroProModAPPos = endsWith(APwave.keys,['_',heroID{1}]);            % position of hero sweep in AP wave processing moduls
      if isempty(find(heroProModAPPos))
       heroID = [];
      else
       heroSwpAPDat = APwave.values{heroProModAPPos}.vectordata;              % 
      end    
    end
    if exist('heroID','var') && ~isempty(heroID)
        PosSpTrain = find(ismember(spPatr.map('AP Pattern parameter'...
          ).vectordata.map('SwpID').data, heroID{1}));                % saves the position of the spPatr module that matches the first current potential hero sweep
        if ~isempty(PosSpTrain)
          PS.heroSwpAPPDat = getRow(spPatr.values{1}, PosSpTrain);   
        elseif length(heroID)>1
            PosSpTrain = find(str2double(LPsupraIDs)==heroID{end});  
            PS.heroSwpAPPDat = getRow(spPatr.values{1}, PosSpTrain);   
        end
    end
    if ~isempty(PS.heroSwpAPPDat)                                           % if there is a hero sweep
     PS.heroSwpSers = nwb.resolve(SwpPaths(PS.heroSwpTabPos(1)));          % get CCSeries of hero sweep 
     HeroStart = IcephysTab.responses.response.data.load.idx_start(...
                                    PS.heroSwpTabPos(end));                % getting StimOnset for Hero sweep                                
     baseline = mean(PS.heroSwpSers.data.load(1:HeroStart));               % getting baseline Vm of herosweep for through ratio
     if checkVolts(PS.heroSwpSers.data_unit) && ...
             string(PS.heroSwpSers.description) ~= "PLACEHOLDER"
       baseline = baseline*1000;  
     end  
     if length(heroSwpAPDat.map('trgh').data)>1
       icSum.TrghRatio(ClNr) = round((heroSwpAPDat.map('trgh').data(1)...
         -baseline)/(heroSwpAPDat.map('trgh').data(end-1)-baseline),3);
       icSum.TrghDiff(ClNr) = heroSwpAPDat.map('trgh').data(1) -....
                                 heroSwpAPDat.map('trgh').data(end-1);
     end
     icSum.cvISI(ClNr) = round(PS.heroSwpAPPDat.cvISI,3);                  % get cvISI
     icSum.HeroRt(ClNr) = PS.heroSwpAPPDat.firRt;                          % get firing rate of hero sweep  
     icSum.HeroAmp(ClNr) = Ipass(pos);                                     % get current amplitude of hero sweep
     icSum.heroLat(ClNr) = PS.heroSwpAPPDat.lat;                           % get latency of hero sweep
     icSum.peakAda(ClNr) = round(PS.heroSwpAPPDat.peakAdapt,3);            % get peak adaptation of hero sweep
     icSum.AdaIdx(ClNr) = round(PS.heroSwpAPPDat.adaptIdx,4);              % get adaptation index of hero sweep 
     icSum.AdaIdx2(ClNr) = round(PS.heroSwpAPPDat.adaptIdx2,4);              % get adaptation index of hero sweep 
     icSum.burst(ClNr) = round(PS.heroSwpAPPDat.burst,3);                  % get bursting index of hero sweep 
     
   elseif length(PS.rheoSwpDat.map('htTP').data) > 3                       % if there is no hero sweep but rheobase has more than 3 spikes 
     PS.heroSwpSers = PS.rheoSwpSers; PS.heroSwpTabPos = PS.rheoSwpTabPos; % get rheo CCSeries as hero sweep  
     HeroStart = IcephysTab.responses.response.data.load.idx_start(...
                                PS.heroSwpTabPos(end));                    % getting StimOnset for Hero sweep                                
     baseline = mean(PS.heroSwpSers.data.load(1:HeroStart));               % getting baseline Vm of herosweep for through ratio
     if checkVolts(PS.heroSwpSers.data_unit) && ...
             string(PS.heroSwpSers.description) ~= "PLACEHOLDER"
       baseline = baseline*1000;  
     end
     heroSwpAPDat = APwave.values{rheoProModPos}.vectordata;                          
     icSum.TrghRatio(ClNr) = round((heroSwpAPDat.map('trgh').data(1)...
         -baseline)/(heroSwpAPDat.map('trgh').data(end-1)-baseline),3);
     icSum.TrghDiff(ClNr) = heroSwpAPDat.map('trgh').data(1) -....
                                 heroSwpAPDat.map('trgh').data(end-1);
     heroProModAPPPos = find(string(spPatr.values{1}.vectordata.map(...
         'SwpID').data)==string(RheoSwpID));                               % gets position of rheo sweep in AP Pattern dynamic table
     PS.heroSwpAPPDat = getRow(spPatr.values{1}, heroProModAPPPos);        % get Hero Sweep Data from spPatr module of rheo sweep
     icSum.cvISI(ClNr) = round(PS.heroSwpAPPDat.cvISI,3);                % get cvISI
     icSum.HeroRt(ClNr) = PS.heroSwpAPPDat.firRt;                        % get firing rate of hero sweep  
     icSum.HeroAmp(ClNr) =  icSum.Rheo(ClNr);                          % get current amplitude of hero sweep
     icSum.heroLat(ClNr) = PS.heroSwpAPPDat.lat;                         % get latency of hero sweep
     icSum.peakAda(ClNr) = round(PS.heroSwpAPPDat.peakAdapt,4);        % get peak adaptation of hero sweep
     icSum.AdaIdx(ClNr) = round(PS.heroSwpAPPDat.adaptIdx2,4);         % get adaptation index of hero sweep 
     icSum.burst(ClNr) = round(PS.heroSwpAPPDat.burst,3);                % get bursting index of hero sweep 
    else
        disp("No suitable hero sweep")
    end
  end
 end
% else  % required for runSummary because data format changes from double to DataStub
end