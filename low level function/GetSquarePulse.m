function [StimOn, StimOff] = GetSquarePulse(data) 
            temp = highpass(data.load,10,250);
            temp(abs(temp)<sum(abs(temp))/200) = 0;
            find(temp(1:end-1)>0 & temp(2:end) < 0);
            StimOn = find(diff(temp>=0),1, 'first');
            StimOff = find(diff(temp>=0),1, 'last');
end           