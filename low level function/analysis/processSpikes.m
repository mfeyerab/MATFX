function [module_spikes, sp, SpQC, QCpass] = ...
    processSpikes(CCSeries, StimOn, StimOff, ...
     params, supraCount, module_spikes, SpQC, QCpass, SweepCount, CurrentName)

 if checkVolts(CCSeries.data_unit) && string(CCSeries.description) ~= "PLACEHOLDER"
    
    supraEvents = find(...
        CCSeries.data.load(StimOn:StimOff+round(CCSeries.starting_time_rate*0.005))>=params.thresholdV/1000)-1+StimOn;
 else 
    supraEvents = find(...
        CCSeries.data.load(StimOn:StimOff+round(CCSeries.starting_time_rate*0.005))>=params.thresholdV)-1+StimOn;
 end
sp = [];
if ~isempty(supraEvents)
    [int4Peak,startPotSp] = int4APs(supraEvents);
    sp = estimatePeak(startPotSp,int4Peak,CCSeries);
    if ~isempty(sp)
     sp = getSpikeParameter(CCSeries, sp, params, StimOff);
     [SpQC, QCpass] = processSpikeQC(CCSeries, sp, params, ...
                                   supraCount, SpQC, QCpass, SweepCount);
                               
%% Save spike parameter

    sp = rmfield(sp, 'dVdt');
    sp = rmfield(sp, 'maxdVdt');
    sp = rmfield(sp, 'maxdVdtTime');

    sp = structfun(@double, sp, 'UniformOutput', false);

    table = array2table(cell2mat(struct2cell(sp))');
    table.Properties.VariableNames = {'peak','peakTime','threshold', ...
                 'thresholdTime', 'through','throughTime','heightPT', ...
                 'fullWidthPT','peakUpStroke','peakDownStroke', ...
                 'peakStrokeRatio','fast_trough','fast_trough_dur',...
                 'slow_trough','slow_trough_dur', 'fullWidthTP', ...
                 'heightTP'};
         
    if checkVolts(CCSeries.data_unit)&& string(CCSeries.description) ~= "PLACEHOLDER"
        
        table.peak  = table.peak*1000;  
        table.threshold  = table.threshold*1000;  
        table.trough  = table.through*1000;  
        table.heightPT  = table.heightPT*1000;  
        table.heightTP  = table.heightTP*1000;  
        table.fast_trough  = table.fast_trough*1000;  
        table.slow_trough  = table.slow_trough*1000;  
        table.peakUpStroke = table.peakUpStroke*1000;
        table.peakDownStroke = table.peakDownStroke*1000;
    end     

    table.thresholdTime = ...
        table.thresholdTime*1000/round(CCSeries.starting_time_rate);

    table.peakTime = ...
        table.peakTime*1000/round(CCSeries.starting_time_rate);

    table.throughTime = ...
        table.throughTime*1000/round(CCSeries.starting_time_rate);

    table = util.table2nwb(table, 'AP processing results');

%% save in dynamic table

    module_spikes.dynamictable.set(CurrentName, table);
  
    end
 end
 