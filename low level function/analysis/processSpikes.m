function [modSpikes,sp,QC] = processSpikes(CCSers,PS,modSpikes,SwpCt, QC)

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
    [int4Peak,startPotSp] = int4APs(supraEvents);
    sp = estimatePeak(startPotSp,int4Peak,CCSers);
    if ~isempty(sp)
     sp = getSpikeParameter(CCSers, sp, PS);
     QC = processSpikeQC(CCSers, sp, PS, QC, SwpCt);
                               
%% Save spike parameter

    sp = rmfield(sp, 'dVdt');
    sp = rmfield(sp, 'maxdVdt');
    sp = rmfield(sp, 'maxdVdtTime');

    sp = structfun(@double, sp, 'UniformOutput', false);

    table = array2table(cell2mat(struct2cell(sp))');
    table.Properties.VariableNames = {'peak','peakTi','thres', ...
                 'thresTi', 'trgh','trghTi','htPT', ...
                 'wiPT','peakUpStrk','peakDwStrk', ...
                 'peakStrkRat','fTrgh','fTrghDur',...
                 'sTrgh','sTrghDur', 'wiTP', ...
                 'htTP'};
         
    if checkVolts(CCSers.data_unit)&& string(CCSers.description) ~= "PLACEHOLDER"
        
        table.peak  = table.peak*1000;  
        table.thres  = table.thres*1000;  
        table.trgh  = table.trgh*1000;  
        table.htPT  = table.htPT*1000;  
        table.htTP  = table.htTP*1000;  
        table.fTrgh  = table.fTrgh*1000;  
        table.sTrgh  = table.sTrgh*1000;  
        table.peakUpStrk = table.peakUpStrk*1000;
        table.peakDwStrk = table.peakDwStrk*1000;
    end     

    table.thresTi = ...
        table.thresTi*1000/round(CCSers.starting_time_rate);

    table.peakTi = ...
        table.peakTi*1000/round(CCSers.starting_time_rate);

    table.trghTi = ...
        table.trghTi*1000/round(CCSers.starting_time_rate);

    table = util.table2nwb(table, 'AP processing results');

%% save in dynamic table

    modSpikes.dynamictable.set(PS.SwDat.CurrentName, table);
  
    end
 end
 