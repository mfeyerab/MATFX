function [TabIn,QC] = processSpikes(CCSers,PS,TabIn, QC)

 if checkVolts(CCSers.data_unit) && string(CCSers.description) ~= "PLACEHOLDER"
    
    supraEvents = find(...
        CCSers.data.load(PS.SwDat.StimOn:PS.SwDat.StimOff+round(...
        CCSers.starting_time_rate*0.005))>=PS.thresholdV/1000)-1+PS.SwDat.StimOn;
 else 
    supraEvents = find(...
        CCSers.data.load(PS.SwDat.StimOn:PS.SwDat.StimOff+round(...
        CCSers.starting_time_rate*0.005))>=PS.thresholdV)-1+PS.SwDat.StimOn;
 end
sp = [];
if ~isempty(supraEvents)
    [int4Peak,startPotSp] = int4APs(supraEvents, PS);
    sp = estimatePeak(startPotSp,int4Peak,CCSers.data.load);
    if ~isempty(sp)
     sp = getSpikeParameter(CCSers.data.load, sp, PS);
%%  Clean up and saving of spike parameter
 
    sp = rmfield(sp, 'dVdt');
    sp = rmfield(sp, 'maxdVdt');
    sp = rmfield(sp, 'maxdVdtTime');
    if checkVolts(CCSers.data_unit) && string(CCSers.description) ~= "PLACEHOLDER"   
      Idx = abs(sp.peak-sp.threshold)>5/1000;
    else 
      Idx = abs(sp.peak-sp.threshold)>5;
    end
        
    sp = structfun(@(F) F(find(Idx)), sp, 'uniform', 0);
    sp = structfun(@double, sp, 'UniformOutput', false);

    if checkVolts(CCSers.data_unit)&& string(CCSers.description) ~= "PLACEHOLDER"
            
            sp.peak  = sp.peak*1000;  
            sp.threshold  = sp.threshold*1000;  
            sp.trough  = sp.trough*1000;  
            sp.heightTP  = sp.heightTP*1000;  
            sp.fast_trough  = sp.fast_trough*1000;  
            sp.slow_trough  = sp.slow_trough*1000;  
            sp.peakUpStroke = sp.peakUpStroke*1000;
            sp.peakDownStroke = sp.peakDownStroke*1000;
    end     
    if isempty(TabIn)        
        [TabIn.peak, TabIn.peakTi, TabIn.thres, TabIn.thresTi, ...
         TabIn.trgh, TabIn.trghTi, ...
         TabIn.peakUpStrk, TabIn.peakDwStrk, TabIn.peakStrkRat, ...
         TabIn.fTrgh, TabIn.fTrghDur, TabIn.sTrgh, TabIn.sTrghDur, ...
         TabIn.wiTP, TabIn.htTP] = deal({NaN}); SPcount = 0;
    else
        SPcount = sum(contains(TabIn.ProtoTag,'SP'));
    end
    TabIn.SweepID(PS.supraCount+SPcount) = {PS.SwDat.CurrentName};
    TabIn.ProtoTag(PS.supraCount+SPcount) = {PS.SwDat.Tag};
    TabIn{PS.supraCount+SPcount,1:end-2} = struct2cell(sp)';    
    end
    end
end
 