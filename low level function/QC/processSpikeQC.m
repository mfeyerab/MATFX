function QC = processSpikeQC(CCSers, sp, PS, QC, SwpCt)

if contains(CCSers.stimulus_description, 'Short')
   QC.pass.bad_spikes(SwpCt,1) = 1;
   disp(['No Spike QC for Sweep Nr. ', num2str(CCSers.sweep_number)])
elseif isempty(sp.peak)
   QC.pass.bad_spikes(SwpCt,1) = 0;
else   
    idx(1,:) = logical(zeros(1,length(sp.threshold)));
    temp = find(isnan(sp.maxdVdt));                                            % number of times interval rule is broken
    idx(1,temp) = true;
    SpQC.BrokenInterval{PS.supraCount,1} = idx(1,:);

    idx(2,:) = sp.threshold==0;                                                    % number of times dV/dt rule is broken
    SpQC.BrokenThreshold{PS.supraCount,1} = idx(2,:);

    diffthreshold2peakT = (sp.peakTime-sp.thresholdTime)*1000/CCSers.starting_time_rate;
    idx(5,:) = diffthreshold2peakT > PS.maxDiffThreshold2PeakT;
    SpQC.diffthreshold2peakT{PS.supraCount,1} = idx(5,:);

    if checkVolts(CCSers.data_unit)

            idx(3,:) = sp.maxdVdt*1000 < PS.mindVdt;

            idx(4,:) = sp.threshold*1000 > PS.maxThreshold;

            if length(sp.heightTP)>1
                idx(6,:) = sp.heightTP*1000<...
                        PS.percentRheobaseHeight*sp.heightTP(1)*1000;
            else
                idx(6,:) = logical(zeros(1,length(sp.threshold)));
            end

            if sp.fullWidthTP(1) <= 0.7        % narrow spiking
                idx(7,:) = abs(sp.peak*1000-sp.threshold*1000)< ...
                              PS.minDiffThreshold2PeakN;
            else                                                        % broad spiking
                idx(7,:) = abs(sp.peak-sp.threshold)*1000< ...
                              PS.minDiffThreshold2PeakB;
            end
    elseif ~isempty(sp.peak)  

            idx(3,:) = sp.maxdVdt < PS.mindVdt;
            idx(4,:) = sp.threshold > PS.maxThreshold;    

            if length(sp.heightTP)>1
                idx(6,:) = sp.heightTP<PS.percentRheobaseHeight*sp.heightTP(1);
            else
                idx(6,:) = logical(zeros(1,length(sp.threshold)));
            end

            if sp.fullWidthTP(1) <= 0.7        % narrow spiking
                idx(7,:) = abs(sp.peak-sp.threshold)<PS.minDiffThreshold2PeakN;
            else                                                        % broad spiking
                idx(7,:) = abs(sp.peak-sp.threshold)<PS.minDiffThreshold2PeakB;
            end
    end

    SpQC.maxdVdt{PS.supraCount,1} = idx(3,:);
    SpQC.threshold{PS.supraCount,1} = idx(4,:);
    SpQC.DecreaseheightTP{PS.supraCount,1} = idx(6,:);
    SpQC.BrokenThreshold{PS.supraCount,1} = idx(2,:);
    SpQC.heightTP{PS.supraCount,1} = idx(7,:);
    SpQC.total{PS.supraCount,1} = any(idx);

    if SpQC.total{PS.supraCount,1}(1) || sum(SpQC.total{PS.supraCount,1}==0)/...
         length(SpQC.total{PS.supraCount,1}) < PS.minGoodSpFra 
       QC.pass.bad_spikes(SwpCt,1) = 0;
    else
       QC.pass.bad_spikes(SwpCt,1) = 1;
    end
end