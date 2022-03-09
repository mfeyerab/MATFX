function [icSum, PS] = SPsummary(nwb, icSum, cellNr, PS)

IcephysTab = nwb.general_intracellular_ephys_intracellular_recordings;     % Assign new variable for readability
SwpRespTbl = IcephysTab.responses.response.data.load.timeseries;           % Assign new variable for readability
SwpAmps = IcephysTab.stimuli.vectordata.values{1}.data;                    % Assign new variable for readability
qcPass = IcephysTab.dynamictable.map('quality_control_pass').vectordata;

SPIdx = contains(cellstr(IcephysTab.dynamictable.map('protocol_type'...
                     ).vectordata.values{1}.data.load),PS.SPtags);
if isa(qcPass.values{1}.data, 'double')                                    % Newly written entries into nwb object are doubles not DataStubs, hence there are two different forms of code needed to access them
  
  IdxPassSwps = all([qcPass.values{1}.data', SPIdx],2);                    % creates indices from passing QC (sweeps x 1)and LP type indices                              
  SwpPaths = {SwpRespTbl.path};                                            % Gets all sweep paths of sweep response table and assigns it to a new variable  
  SwpIDs = cellfun(@(a) str2double(a), cellfun(@(v)v(1),...                % Extract the numbers from the sweep names as doubles  
                                       regexp(SwpPaths,'\d*','Match')));   % inner cellfun necessary if sweep name contains mutliple numbers for example an extra AD01 
  IdPassSwps = SwpIDs(IdxPassSwps);                                        % Variable contains numbers of sweeps which passed QC  
  IdPassSwpsC = cellstr(string(IdPassSwps));
  
 if ~isempty(IdPassSwps)
      
%% find SP "rheobase" sweeps and parameters of first spike
  APwave = nwb.processing.map('AP wave').dynamictable;                     % variable for better readability     
  if isa(SwpAmps, 'double')                                                % if current amplitude is double not a DataStub
    SPampsQC = SwpAmps(IdxPassSwps);                                       % assign current amplitudes  of sweeps that made the QC to variable
  else  
    SPampsQC = SwpAmps.load(find(IdxPassSwps));                            % assign current amplitudes  of sweeps that made the QC to variable
  end  
  tempSPstep = min(SPampsQC(ismember(IdPassSwpsC,...
                            regexp(cell2mat(APwave.keys),'\d*','Match'))));

  if ~isempty(tempSPstep)
    
    tempSPstepLoc = find(contains(APwave.keys,IdPassSwpsC(...
                                        SPampsQC==tempSPstep)),1,'first');
    PS.SPSwpTbPos = find(endsWith(SwpPaths,nwb.processing.map('AP wave'...
                                      ).dynamictable.keys{tempSPstepLoc}));
    PS.SPSwpDat = APwave.values{tempSPstepLoc}.vectordata;
    
    if ~isempty(PS.SPSwpDat.values{1}.data)
      icSum.latencySP(cellNr,1) = PS.SPSwpDat.map('thresTi').data - ...
            (IcephysTab.responses.response.data.load(PS.SPSwpTbPos).idx_start*...
            1000/nwb.resolve(SwpRespTbl(PS.SPSwpTbPos).path).starting_time_rate);        

      icSum.CurrentStepSP(cellNr,1) = tempSPstep;
      icSum.widthTP_SP(cellNr,1) = PS.SPSwpDat.map('wiTP').data;
      icSum.peakSP(cellNr,1) = PS.SPSwpDat.map('peak').data;    
      icSum.thresholdSP(cellNr,1) = PS.SPSwpDat.map('thres').data;
      icSum.fastTroughSP(cellNr,1) = PS.SPSwpDat.map('fTrgh').data;
      icSum.slowTroughSP(cellNr,1) = PS.SPSwpDat.map('sTrgh').data;
      icSum.peakUpStrokeSP(cellNr,1) = PS.SPSwpDat.map('peakUpStrk').data; 
      icSum.peakDownStrokeSP(cellNr,1) = PS.SPSwpDat.map('peakDwStrk').data;
      icSum.peakStrokeRatioSP(cellNr,1) = PS.SPSwpDat.map('peakStrkRat').data;   
      icSum.heightTP_SP(cellNr,1) = PS.SPSwpDat.map('htTP').data;     
      PS.SPSwpSers =  nwb.resolve(SwpPaths(PS.SPSwpTbPos(contains(...
                                    SwpPaths(PS.SPSwpTbPos),'acquisition'))));
    end
  end
end
else  % required for runSummary because data format changes from double to DataStub
end        