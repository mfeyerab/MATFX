function TP = getTP(CStimData,CRespData,SmplRate)
%gets the testpulse out of a CurrentClampSeries object.
%




%% If current trace is in nanoAmpere
if range(CStimData)>2
 CStimData = CStimData/1000;
end

%%
if round(range(CStimData)/2,3) < 0                    % if test pulse is hyperpolarizing 
 [~, testOn] = findpeaks(-diff(CStimData),'SortStr','descend','NPeaks',1);
 TP = CRespData(testOn-0.015*SmplRate):testOn+(0.075*SmplRate);
elseif round(range(CStimData)/2,3)  > 0                % if test pulse is hyperpolarizing 
 [~, testOn] = findpeaks(diff(CStimData),'SortStr','descend','NPeaks',1);
 TP = CRespData(testOn-(0.015*SmplRate):testOn+(0.075*SmplRate));
else
    disp('Sweep has no detectable test pulse')
    TP = nan(1,4501);
end