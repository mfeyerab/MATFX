%{
summary LP analysis
%}

       %% subthreshold summary parameters                              
        IC.resistance_ss(n,1) = resistance_ss(a.LP);                        % resistance based on steady state
        IC.Vrest(n,1) = restingMP(a.LP);                                    % resting membrane potential
        IC.time_constant(n,1) = round(double(a.LP.subSummary.tauMin),2);
        RheoSweeps = [];
        cycler = 0;
        PotenRheo = [];
        %%
            k = find(ismember(qc.sweepID(n,:),...
                find(round(double(a.LP.sweepAmps)) == -90))==1);            % find -90 pA input
            while length(k) > 0 && cycler < 3                
                if sum(a.LP.stats{k(1), 1}.qc.logicVec) > 0  
                 k(1) = []; 
                end
                cycler = cycler + 1;
            end
            if length(k) > 1
                k = k(1);
            end    
            if ~isempty(k) && sum(a.LP.stats{k(1), 1}.qc.logicVec) == 0 
                getSubthresholdStats                                        % get subthreshold stats
            else                                                            % if no -90 pA sweep
                k = find(ismember(qc.sweepID(n,:),...
                    find(round(double(a.LP.sweepAmps)) == -70))==1);        % find -70 pA sweep
                if length(k)>1
                    k = k(1);
                end
                if ~isempty(k) && sum(a.LP.stats{k(1), 1}.qc.logicVec) == 0 
                    getSubthresholdStats                                    % get subthreshold stats
                else                                                        % if no -70 pA sweep
                    k = find(ismember(qc.sweepID(n,:),...
                        find(round(double(a.LP.sweepAmps)) == -110))==1);   % find -110 pA sweep
                    if length(k)>1
                        k = k(1);
                    end
                    if ~isempty(k) && sum(a.LP.stats{k(1), 1}.qc.logicVec) == 0 
                        getSubthresholdStats                                % get subthreshold stats
                    else                                                    % if no -50 pA sweeps
                        IC.subamp(n,1) = NaN;                               % add NaNs (blank spaces in csv format)
                        IC.submin(n,1) = NaN;
                        IC.rebound_slope(n,1) = NaN;
                        IC.rebound_depolarization(n,1) = NaN;
                        IC.nb_rebound_sp(n,1) = 0;
                        IC.sag(n,1) = NaN;
                        IC.steadystate(n,1) = NaN;
                        IC.sag_ratio(n,1) = NaN;
                    end
                end
            end
            %% find rheobase sweeps and parameters of first spike
            [B,I] = sort(round(double(a.LP.sweepAmps(1:length(a.LP.stats)))));
            int_vec = find(B>0);
            temp = int_vec(find(ismember(int_vec,qc.sweepID(n,:))==1));
            idxLP = I(temp);
            ampLP = B(temp);
            IC.LP_input_current_s(n,1:length(ampLP)) = round(double(a.LP.sweepAmps(idxLP)));
            spCheck = 0;
            cycler = 0;
            for k = 1:length(idxLP)
                if isfield(a.LP.stats{idxLP(k),1},'spTimes') && ...
                        sum(~isnan(a.LP.stats{idxLP(k),1}.spTimes))>0
                    % spike train parameters
                    IC.rate_1s(n,k) = a.LP.stats{idxLP(k),1}.meanFR1000;
                    IC.rate_750ms(n,k) = a.LP.stats{idxLP(k),1}.meanFR750;
                    IC.rate_500ms(n,k) = a.LP.stats{idxLP(k),1}.meanFR500;
                    IC.rate_250ms(n,k) = a.LP.stats{idxLP(k),1}.meanFR250;
                    IC.rate_100ms(n,k) = a.LP.stats{idxLP(k),1}.meanFR100;
                    IC.rate_50ms(n,k) = a.LP.stats{idxLP(k),1}.meanFR50;
                    IC.delay(n,k) = min(round(double(a.LP.stats{idxLP(k),1}.delay),2));
                    IC.burst(n,k) = round(double(a.LP.stats{idxLP(k),1}.burst),2);
                    IC.latency(n,k) = min(round(double(a.LP.stats{idxLP(k),1}.latency),2)); %tag
                    IC.cv_ISI(n,k) = round(double(a.LP.stats{idxLP(k),1}.cvISI),2);
                    IC.adaptation1(n,k) = round(double(a.LP.stats{idxLP(k),1}.adaptIndex),2);
                    IC.adaptation2(n,k) = round(double(a.LP.stats{idxLP(k),1}.adaptIndex2),2);
                    IC.peak_adaptation1(n,k) = round(double(a.LP.stats{idxLP(k),1}.peakAdapt),2);
                    IC.peak_adaptation2(n,k) = round(double(a.LP.stats{idxLP(k),1}.peakAdapt2),2);
                    spCheck = 1;
                end
            end
           meanFR1000 = zeros(1,1);
           delay = zeros(1,1); 
           burst = zeros(1,1); 
           latency = zeros(1,1); 
           peak = zeros(1,1); 
           thresholdRef = zeros(1,1); 
           fullWidthTP = zeros(1,1); 
           fullWidthPT = zeros(1,1); 
           heightTP = zeros(1,1); 
           heightPT = zeros(1,1); 
           peakUpStroke = zeros(1,1); 
           peakDownStroke = zeros(1,1); 
           peakStrokeRatio = zeros(1,1); 
           trough = zeros(1,1); 
           fastTroughDur = zeros(1,1); 
           slowTroughDur = zeros(1,1);
           wavesLP = zeros(1,226);
           for k = 1:length(idxLP)
                if isfield(a.LP.stats{idxLP(k),1},'spTimes') && ...
                        sum(~isnan(a.LP.stats{idxLP(k),1}.spTimes))>0
                   while length(unique(RheoSweeps)) < 3 && cycler < 3 && ...
                           length(idxLP) > k+cycler
                        PotenRheo = idxLP(ampLP==ampLP(k+cycler));
                        for i = 1:length(PotenRheo)
                           if isfield(a.LP.stats{PotenRheo(i),1},'spTimes') &&... 
                               sum(~isnan(a.LP.stats{PotenRheo(i),1}.spTimes)) &&... 
                                length(a.LP.stats{PotenRheo(i),1}.spTimes) < 4
                               RheoSweeps = [RheoSweeps, PotenRheo(i)];
                           end
                        end
                        cycler = cycler +1;
                   end
             RheoSweeps = unique(RheoSweeps);
             IC.rheobaseLP(n,1) = mean(a.LP.sweepAmps(RheoSweeps),1); 
             for r = 1:length(RheoSweeps)
              meanFR1000(1,r) =  a.LP.stats{RheoSweeps(r),1}.meanFR1000;
              delay(1,r) = min(a.LP.stats{RheoSweeps(r),1}.delay);   
              burst(1,r) = a.LP.stats{RheoSweeps(r),1}.burst;
              latency(1,r) = min(a.LP.stats{RheoSweeps(r),1}.latency);
              peak(1,r) = a.LP.stats{RheoSweeps(r),1}.peak(1);
              thresholdRef(1,r) = a.LP.stats{RheoSweeps(r),1}.thresholdRef(1);
              fullWidthTP(1,r) = a.LP.stats{RheoSweeps(r),1}.fullWidthTP(1);
              fullWidthPT(1,r) = a.LP.stats{RheoSweeps(r),1}.fullWidthPT(1);
              heightTP(1,r) = a.LP.stats{RheoSweeps(r),1}.heightTP(1);
              heightPT(1,r) = a.LP.stats{RheoSweeps(r),1}.heightPT(1);
              peakUpStroke(1,r) = a.LP.stats{RheoSweeps(r),1}.peakUpStroke(1);
              peakDownStroke(1,r) = a.LP.stats{RheoSweeps(r),1}.peakDownStroke(1);
              peakStrokeRatio(1,r) = a.LP.stats{RheoSweeps(r),1}.peakStrokeRatio(1);
              trough(1,r) = a.LP.stats{RheoSweeps(r),1}.trough(1);
              fastTroughDur(1,r) = a.LP.stats{RheoSweeps(r),1}.fastTroughDur(1);
              slowTroughDur(1,r) = a.LP.stats{RheoSweeps(r),1}.slowTroughDur(1);
              wavesLP(r,:) = a.LP.stats{RheoSweeps(r),1}.waves;
             end
              IC.rate_1sRheobase(n,1) = mean(meanFR1000);
              IC.delayRheobase(n,1) = round(mean(delay),2);
              IC.burstRheobase(n,1) = round(mean(burst),2);
              IC.latencyRheobase(n,1) = round(mean(latency),2);
              IC.peakLP(n,1) = round(mean(peak),2);
              IC.thresholdLP(n,1) = round(mean(thresholdRef),2);
              IC.half_width_threshold_peak(n,1) = round(mean(fullWidthTP),2);
              IC.half_width_peak_trough(n,1) = round(mean(fullWidthPT),2);
              IC.height_threshold_peak(n,1) = round(mean(heightTP),2);
              IC.height_peak_trough(n,1) = round(mean(heightPT),2);
              IC.peak_up_stroke(n,1) = round(mean(peakUpStroke),2);
              IC.peak_down_stroke(n,1) = round(mean(peakDownStroke),2);
              IC.peak_stroke_ratio(n,1) = round(mean(peakStrokeRatio),2);
              IC.trough(n,1) = round(mean(trough),2);
              IC.fastTrough(n,1) = round(mean(fastTroughDur),2);
              IC.slowTrough(n,1) = round(mean(slowTroughDur),2);
                if IC.slowTrough(n,1) < 2                              %  check if the cell has a true fAHP, its peak should be more depolarized than any other afterhyperpolarizations                         
                    IC.fAHPamp(n,1) = round(mean( ...
                        thresholdRef - trough),2);                     %  amplitude of fAHP from threshold
                else 
                    IC.fAHPamp(n,1) = NaN;
                end
                IC.wfLP(n,:) = mean(wavesLP,1);               
                else
                    IC.rheobaseLP(n,1) = NaN;
                end
            end
            % global spike parameters and Hero sweep selection
            k = [];                                                         % resetting k for indexing sweeps
            flag = 0;                                                       % variable to fire the if condition in while loop only one time
            if spCheck == 1             
                % global spiketrain parameters
                IC.maxFiringRate(n,1) = max(IC.rate_1s(n,:),[],'omitnan');
                IC.mdn_insta_freq(n,1) = median_isi(a.LP);                  % obtain the median ISI of all suprathreshold sweeps

                % picking "Hero sweep" for more spike train parameters per cell
                [~,k] = min(abs(double(B)-(IC.rheobaseLP(n,1)*1.5)));        % hero sweep is 1.5x Rheobase
                if k > 0                                                    % if there is a sweep 1.5x Rheobase
                    while ~ismember(qc.sweepID(n,k),k) ||    ...            % Making sure the k sweep meets other necessary conditions
                            ~isfield(a.LP.stats{k,1},'burst')  ||   ...     % It has spike train analysis fields like burst
                            a.LP.sweepAmps(k) <= IC.rheobaseLP(n,1) || ...  % It is not lower than the rheobase
                                a.LP.sweepAmps(k) > 3*IC.rheobaseLP(n,1)        % It is not more than triple the rheobase 
                        k = k - 1;  
                        if k == 0 && flag == 0
                            [~, k] = min(abs(double(B) - ...
                                (IC.rheobaseLP(n,1)*3)));                   % hero sweep is 8x Rheobase sweep
                            flag = 1;                                       % set if condition to fire
                        end
                        if k == 0 && flag == 1; break; end
                    end  
                end
                if k == 0 
                    IC.rate_1sHero(n,1) = NaN;
                    IC.rate_750msHero(n,1) = NaN;
                    IC.rate_500msHero(n,1) = NaN;
                    IC.rate_250msHero(n,1) = NaN;
                    IC.rate_100msHero(n,1) = NaN;
                    IC.rate_50msHero(n,1) = NaN;
                    IC.burst_hero(n,1) = NaN;
                    IC.delay_hero(n,1) =   NaN;
                    IC.latency_hero(n,1) = NaN;
                    IC.cv_ISI(n,1) =  NaN;
                    IC.adaptation2(n,1) = NaN;
                    IC.hero_amp(n,1) = NaN;
                elseif length(k) > 1
                    IC.rate_1sHero(n,1) = mean(a.LP.stats{k,1}.meanFR1000);
                    IC.rate_750msHero(n,1) = mean(a.LP.stats{k,1}.meanFR750);
                    IC.rate_500msHero(n,1) = mean(a.LP.stats{k,1}.meanFR500);
                    IC.rate_250msHero(n,1) = mean(a.LP.stats{k,1}.meanFR250);
                    IC.rate_100msHero(n,1) = mean(a.LP.stats{k,1}.meanFR100);
                    IC.rate_50msHero(n,1) = mean(a.LP.stats{k,1}.meanFR50);
                    IC.burst_hero(n,1) = mean(train_burst(n,k(1:length(k))));
                    IC.delay_hero(n,1) =   mean(train_delay(n,k(1:length(k))));
                    IC.latency_hero(n,1) = mean(train_latency(n,k(1:length(k))));
                    IC.cv_ISI(n,1) =   mean(train_cv_ISI(n,k(1:length(k))));
                    IC.adaptation1(n,1) = mean(train_adaptation1(n,k(1:length(k))));
                    IC.adaptation2(n,1) = mean(train_adaptation2(n,k(1:length(k))));
                    IC.hero_amp(n,1) = unique(a.LP.sweepAmps(k));       
                else
                    IC.rate_1sHero(n,1) = a.LP.stats{k,1}.meanFR1000;
                    IC.rate_750msHero(n,1) = a.LP.stats{k,1}.meanFR750;
                    IC.rate_500msHero(n,1) = a.LP.stats{k,1}.meanFR500;
                    IC.rate_250msHero(n,1) = a.LP.stats{k,1}.meanFR250;
                    IC.rate_100msHero(n,1) = a.LP.stats{k,1}.meanFR100;
                    IC.rate_50msHero(n,1) = a.LP.stats{k,1}.meanFR50;
                    IC.burst_hero(n,1) =  a.LP.stats{k, 1}.burst;
                    IC.delay_hero(n,1) =   unique(a.LP.stats{k, 1}.delay);
                    IC.latency_hero(n,1) = unique(a.LP.stats{k, 1}.latency);
                    IC.cv_ISI(n,1) =   a.LP.stats{k, 1}.cvISI ;  
                    IC.adaptation1(n,1) = a.LP.stats{k, 1}.adaptIndex; 
                    IC.adaptation2(n,1) = a.LP.stats{k, 1}.adaptIndex2; 
                    IC.hero_amp(n,1) = a.LP.sweepAmps(k);
                end      
            end