    PS.SwDat = struct(); PS.SwDat.testOn =0;                               % initialize  structure for variabels containing sweep specific Data       
    PS.SwDat.CurrentPath = table2array(RespTbl(SwpCt,3)).path;             % get path to sweep within nwb file 
    PS.SwDat.StimData = nwb.resolve(...
        ICEtab.stimuli.stimulus.data.load().timeseries(SwpCt).path).data.load;
    PS.SwDat.CurrentName = PS.SwDat.CurrentPath(find(...
     PS.SwDat.CurrentPath=='/',1,'last')+1:length(PS.SwDat.CurrentPath));  % extracts name of the sweep                
    [QC.params.SweepID(SwpCt), QC.pass.SweepID(SwpCt)] = ...
        deal({PS.SwDat.CurrentName});                                      % saves the sweep name in QC tables        
    [QC.params.Protocol(SwpCt), QC.pass.Protocol(SwpCt)] = ...
        deal({ProtoTags(SwpCt,:)});                                        % saves the protocol name/type in QC tables   