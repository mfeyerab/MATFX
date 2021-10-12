function [StimOn, StimOff] = GetSquarePulse(CCStimSeries, params) 
            if contains(CCStimSeries.stimulus_description, params.SPtags)
             temp =  CCStimSeries.data.load;
             temp(abs(temp)<std(temp)*4) = 0;  
             temp = (diff(temp));  
             temp(abs(temp)<std(temp)*20) = 0; 
             StimOff = find(diff(temp>=0),1, 'last');
            else    
                temp = highpass(CCStimSeries.data.load,10,250);
                temp = temp(1:length(temp)-round(CCStimSeries.starting_time_rate)*0.02);
                if std(temp) > 1
                     temp(abs(temp)<std(temp)*4) = 0;
                else
                    temp(abs(temp)<max(temp)/3.5) = 0;
                end            
                StimOff = round(find(diff(temp>=0),1, 'last'),-1);
            end
            if StimOff < 5000
                StimOn = NaN;
            elseif contains(CCStimSeries.stimulus_description, params.LPtags) 
              StimOn = StimOff - round(CCStimSeries.starting_time_rate);
            elseif contains(CCStimSeries.stimulus_description, params.SPtags) 
              StimOn = StimOff - round(CCStimSeries.starting_time_rate*0.003);
            else
               disp(['unknown stimulus type: ',CCStimSeries.stimulus_description])    
            end
            if ~isempty(StimOff)
                if StimOn < 0 || StimOn==StimOff
                    StimOn = NaN;
                end
            end             
end