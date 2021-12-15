function [module_spikes, sp, SpQC, QCpass] = ...
    processSpikes(CCSeries, SwData, params, supraCount, ...
           module_spikes, SpQC, QCpass, SweepCount)

 if checkVolts(CCSeries.data_unit) && string(CCSeries.description) ~= "PLACEHOLDER"
    
    supraEvents = find(...
        CCSeries.data.load(SwData.StimOn:SwData.StimOff+round(...
        CCSeries.starting_time_rate*0.005))>=params.thresholdV/1000)-1+SwData.StimOn;
 else 
    supraEvents = find(...
        CCSeries.data.load(SwData.StimOn:SwData.StimOff+round(...
        CCSeries.starting_time_rate*0.005))>=params.thresholdV)-1+SwData.StimOn;
 end
sp = [];
if ~isempty(supraEvents)
    [int4Peak,startPotSp] = int4APs(supraEvents);
    sp = estimatePeak(startPotSp,int4Peak,CCSeries);
    if ~isempty(sp)
     sp = getSpikeParameter(CCSeries, sp, params, SwData.StimOff);
     [SpQC, QCpass] = processSpikeQC(CCSeries, sp, params, ...
                                   supraCount, SpQC, QCpass, SweepCount);
                               
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
         
    if checkVolts(CCSeries.data_unit)&& string(CCSeries.description) ~= "PLACEHOLDER"
        
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
        table.thresTi*1000/round(CCSeries.starting_time_rate);

    table.peakTi = ...
        table.peakTi*1000/round(CCSeries.starting_time_rate);

    table.trghTi = ...
        table.trghTi*1000/round(CCSeries.starting_time_rate);

    table = util.table2nwb(table, 'AP processing results');

%% save in dynamic table

    module_spikes.dynamictable.set(SwData.CurrentName, table);
  
    end
 end
 