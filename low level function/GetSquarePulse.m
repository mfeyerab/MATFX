function [StimOn, StimOff] = GetSquarePulse(CCStimSeries) 
            temp = highpass(CCStimSeries.data.load,10,250);
            temp = temp(1:length(temp)-round(CCStimSeries.starting_time_rate)*0.02);
            if std(temp) > 1
                 temp(abs(temp)<std(temp)*4) = 0;
            else
                temp(abs(temp)<max(temp)/3.5) = 0;
            end            
            StimOff = round(find(diff(temp>=0),1, 'last'),-2);
            if contains(CCStimSeries.stimulus_description, 'Short') 
              StimOn = StimOff - round(CCStimSeries.starting_time_rate*0.003);
            elseif contains(CCStimSeries.stimulus_description, 'Long') 
              StimOn = StimOff - round(CCStimSeries.starting_time_rate);
            elseif StimOff < 5000
                StimOn = Nan;
            else
               disp("unknown stimulus type")    
            end
            if StimOn < 0
                StimOn = NaN;
            end              
end