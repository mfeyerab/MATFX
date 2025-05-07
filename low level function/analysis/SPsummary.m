function [icSum, PS] = SPsummary(nwb, icSum, cellNr, PS, QC, APTab)

IcephysTab = nwb.general_intracellular_ephys_intracellular_recordings;     % Assign new variable for readability
SwpRespTbl = IcephysTab.responses.response.data.load;                      % Assign new variable for readability
SwpAmps = IcephysTab.stimuli.vectordata.values{1}.data.load;               % Assign new variable for readability
Proto = strtrim(string(IcephysTab.vectordata.Map('protocol_type').data.load));
SPIdx = contains(cellstr(Proto),PS.SPtags);  
IdxPassSwps = SPIdx & QC.pass.QC_total_pass;                               % creates indices from passing QC (sweeps x 1)and LP type indices                              
SwpPaths = {SwpRespTbl.timeseries.path};                                              % Gets all sweep paths of sweep response table and assigns it to a new variable  
SwpIDs = cellfun(@(a) str2double(a), cellfun(@(v)v(1),...                  % Extract the numbers from the sweep names as doubles  
                                       regexp(SwpPaths,'\d*','Match')));   % inner cellfun necessary if sweep name contains mutliple numbers for example an extra AD01 
IdPassSwps = SwpIDs(IdxPassSwps);                                          % Variable contains numbers of sweeps which passed QC  
IdPassSwpsC = cellstr(string(IdPassSwps));
if ~isempty(IdPassSwps)
 SpikeIDs =  regexp([APTab.SweepID{:}],'\d*','Match');
%% find SP "rheobase" sweeps and parameters of first spike
 if any(ismember(SpikeIDs,IdPassSwpsC))
   SupraIDs = cellfun(@(a) str2double(a), cellfun(@(v)v(1),...                  % Extract the numbers from the sweep names as doubles  
               regexp(APTab.SweepID,'\d*','Match')));
   tempSPIdx = find(ismember(SupraIDs, IdPassSwps));
   [icSum.CurrentStepSP(cellNr,1), SPIdx]  = min(...
                       SwpAmps(ismember(IdPassSwps,SupraIDs(tempSPIdx))));
   SPTab = APTab(tempSPIdx(SPIdx),:);
   SPID = str2num(string(regexp(SPTab.SweepID{:},'\d*','Match')));
   SPSwpSers =  nwb.resolve(['acquisition/', SPTab.SweepID{:}]);
   SPStart = single(SwpRespTbl.idx_start(ismember(SwpIDs,SPID)));
   icSum.latencySP(cellNr,1) = (SPTab.thresTi{:}-SPStart)*1000/SPSwpSers.starting_time_rate;
   icSum.widthTP_SP(cellNr,1) = SPTab.wiTP{:};
   icSum.peakSP(cellNr,1) = SPTab.peak{:}; 
   icSum.thresholdSP(cellNr,1) = SPTab.thres{:}; 
   icSum.fastTroughSP(cellNr,1) = SPTab.fTrgh{:}; 
   icSum.slowTroughSP(cellNr,1) = SPTab.sTrgh{:}; 
   icSum.peakUpStrokeSP(cellNr,1) = SPTab.peakUpStrk{:}; 
   icSum.peakDownStrokeSP(cellNr,1) = SPTab.peakDwStrk{:}; 
   icSum.peakStrokeRatioSP(cellNr,1) = SPTab.peakStrkRat{:};    
   icSum.heightTP_SP(cellNr,1) = SPTab.htTP{:};     
   PS.SPSwpSers = SPSwpSers; PS.SPStart = SPStart;
 end    
end