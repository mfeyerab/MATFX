function LP_TracesExport = exportSweepCSV(CCSeries, SwData, SweepCount, LP_TracesExport)

                                 
original = CCSeries.data.load(SwData.StimOn-CCSeries.starting_time_rate*0.05:...
                                 SwData.StimOff+CCSeries.starting_time_rate*0.2);

if CCSeries.starting_time_rate > 20000
  original = downsample(original, round(CCSeries.starting_time_rate/25000));
end
oL = length(original);
output = interp1(1:oL,original, linspace(1,oL,8001), 'cubic');
newSmplInt = (1/CCSeries.starting_time_rate)*(oL/8001);
timeseries = 0:newSmplInt:newSmplInt*8001 -newSmplInt;

if isempty(LP_TracesExport)   
    LP_TracesExport(1,1) =  {'time'};
    LP_TracesExport(1,2) =  {NaN};
    LP_TracesExport(1,3) = {timeseries}; 
    LP_TracesExport.Properties.VariableNames{1} = 'SweepName';
    LP_TracesExport.Properties.VariableNames{2} = 'StimAmp';
    LP_TracesExport(SweepCount+1,1) =  {SwData.CurrentName};  
    LP_TracesExport(SweepCount+1,2) =  {SwData.sweepAmp};
    LP_TracesExport(SweepCount+1,3) = {round(output,2)};

elseif ~isequal(table2array(LP_TracesExport(1,3)),timeseries)
    
    disp("Sampling rate not consistent across cell")
    
else                                                                       
    LP_TracesExport(SweepCount+1,1) =  {SwData.CurrentName};  
    LP_TracesExport(SweepCount+1,2) =  {SwData.sweepAmp};
    LP_TracesExport(SweepCount+1,3) = {round(output,2)};

end