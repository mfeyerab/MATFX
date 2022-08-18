function [testOn, TPtrace] = getTestPulse(PS, CCSers, StimData)

[~, posPeak] = findpeaks(diff(StimData), 'NPeaks', 1,'SortStr', 'descend');
[~, negPeak] = findpeaks(-diff(StimData), 'NPeaks', 1,'SortStr', 'descend');

if posPeak > negPeak
   testOn = negPeak;
elseif posPeak < negPeak
   testOn = posPeak;
else
    disp([PS.SwDat.CurrentName, ' has no detectable test pulse'])
    TPtrace = nan(1,(PS.preTP+PS.TPtrace)*CCSers.starting_time_rate+1); 
    testOn = [];
end

if ~isempty(testOn) && PS.preTP*CCSers.starting_time_rate>testOn
    
 TPtrace = CCSers.data.load(1:testOn+(PS.TPtrace*CCSers.starting_time_rate));
elseif  ~isempty(testOn)   
 TPtrace = CCSers.data.load(testOn-(PS.preTP*CCSers.starting_time_rate-1):...
                       testOn+(PS.TPtrace*CCSers.starting_time_rate));
end