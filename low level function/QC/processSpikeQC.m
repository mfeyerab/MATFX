function [SpQC, QCpass] = processSpikeQC(CCSeries, sp, params, ...
                                    supraCount, SpQC, QCpass, SweepCount)

                                
idx(1,:) = boolean(zeros(1,length(sp.threshold)));
temp = find(isnan(sp.maxdVdt));                                            % number of times interval rule is broken
idx(1,temp) = true;
SpQC.BrokenInterval{supraCount,1} = idx(1,:);

idx(2,:) = sp.threshold==0;                                                    % number of times dV/dt rule is broken
SpQC.BrokenThreshold{supraCount,1} = idx(2,:);

diffthreshold2peakT = (sp.peakTime-sp.thresholdTime)*1000/CCSeries.starting_time_rate;
idx(5,:) = diffthreshold2peakT > params.maxDiffThreshold2PeakT;
SpQC.diffthreshold2peakT{supraCount,1} = idx(5,:);
                                
if checkVolts(CCSeries.data_unit)

        idx(3,:) = sp.maxdVdt*1000 < params.mindVdt;

        idx(4,:) = sp.threshold*1000 > params.maxThreshold;

        if length(sp.heightTP)>1
            idx(6,:) = sp.heightTP*1000<...
                    params.percentRheobaseHeight*sp.heightTP(1)*1000;
        else
            idx(6,:) = boolean(zeros(1,length(sp.threshold)));
        end

        if sp.fullWidthTP(1) <= 0.7        % narrow spiking
            idx(7,:) = abs(sp.peak*1000-sp.threshold*1000)< ...
                          params.minDiffThreshold2PeakN;
        else                                                        % broad spiking
            idx(7,:) = abs(sp.peak-sp.threshold)*1000< ...
                          params.minDiffThreshold2PeakB;
        end
else   

        idx(3,:) = sp.maxdVdt < params.mindVdt;
        idx(4,:) = sp.threshold > params.maxThreshold;    

        if length(sp.heightTP)>1
            idx(6,:) = sp.heightTP<params.percentRheobaseHeight*sp.heightTP(1);
        else
            idx(6,:) = boolean(zeros(1,length(sp.threshold)));
        end

        if sp.fullWidthTP(1) <= 0.7        % narrow spiking
            idx(7,:) = abs(sp.peak-sp.threshold)<params.minDiffThreshold2PeakN;
        else                                                        % broad spiking
            idx(7,:) = abs(sp.peak-sp.threshold)<params.minDiffThreshold2PeakB;
        end
end

SpQC.maxdVdt{supraCount,1} = idx(3,:);
SpQC.threshold{supraCount,1} = idx(4,:);
SpQC.DecreaseheightTP{supraCount,1} = idx(6,:);
SpQC.BrokenThreshold{supraCount,1} = idx(2,:);
SpQC.heightTP{supraCount,1} = idx(7,:);
SpQC.total{supraCount,1} = any(idx);

if SpQC.total{supraCount,1}(1) || sum(SpQC.total{supraCount,1}==0)/...
     length(SpQC.total{supraCount,1}) < params.minGoodSpFra 
   QCpass.bad_spikes(SweepCount,1) = 0;
else
   QCpass.bad_spikes(SweepCount,1) = 1;

end