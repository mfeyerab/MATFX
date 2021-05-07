% in case there is no final analysis of the cell      
% 0 is a non-sensical value in most variables and should be NaN

        IC.Vrest(n,1) = NaN;                                                  
        IC.resistance_ss(n,1)= NaN;                              
        IC.time_constant(n,1)= NaN;
        IC.sag_sweep(n,1)= NaN;                           
        IC.sag_ratio(n,1)= NaN;                                        
        IC.mdn_insta_freq(n,1)= NaN;  
        IC.rheobaseLP(n,1)= NaN;  
        IC.firing_rate_s(n,1)= NaN;
        IC.rate_1sHero(n,1) = NaN;
        IC.rate_750msHero(n,1) = NaN;
        IC.rate_500msHero(n,1) = NaN;
        IC.rate_250msHero(n,1) = NaN;
        IC.rate_100msHero(n,1) = NaN;
        IC.rate_50msHero(n,1) = NaN;
        IC.burst_hero(n,1) =  NaN;
        IC.delay_hero(n,1) =   NaN;
        IC.latency_hero(n,1) = NaN;
        IC.cv_ISI(n,:) =  NaN ;  
        IC.adaptation1(n,:) = NaN ; 
        IC.adaptation2(n,:) = NaN ; 
        IC.hero_amp(n,1) = NaN;
        IC.rheobaseLP(n,1) = NaN;
        IC.rate_1sRheobase(n,1) = NaN;
        IC.delayRheobase(n,1) = NaN;
        IC.burstRheobase(n,1) = NaN;
        IC.latencyRheobase(n,1) = NaN;
        IC.peakLP(n,1) = NaN;
        IC.thresholdLP(n,1) = NaN;
        IC.half_width_threshold_peak(n,1) = NaN;
        IC.half_width_peak_trough(n,1) = NaN;
        IC.height_threshold_peak(n,1) = NaN;
        IC.height_peak_trough(n,1) = NaN;
        IC.peak_up_stroke(n,1) = NaN;
        IC.peak_down_stroke(n,1) = NaN;
        IC.peak_stroke_ratio(n,1) = NaN;
        IC.trough(n,1) = NaN;
        IC.fastTrough(n,1) = NaN;
        IC.slowTrough(n,1) = NaN;
        IC.fAHPamp(n,1) = NaN;
        IC.subamp(n,1) = NaN;                              
        IC.submin(n,1) = NaN;
        IC.rebound_slope(n,1) = NaN;
        IC.rebound_depolarization(n,1) = NaN;
        IC.nb_rebound_sp(n,1) = NaN;
        IC.sag(n,1) = NaN;
        IC.steadystate(n,1) = NaN;
        IC.sag_ratio(n,1) = NaN;
        IC.rate_1s(n,:) = NaN;
        IC.rate_750ms(n,:) = NaN;
        IC.rate_500ms(n,:) = NaN;
        IC.rate_250ms(n,:) = NaN;
        IC.rate_100ms(n,:) = NaN;
        IC.rate_50ms(n,:) = NaN;
        IC.delay(n,:) = NaN;
        IC.burst(n,:) = NaN;
        IC.latency(n,:) = NaN;
        IC.cv_ISI(n,:) = NaN;
        IC.adaptation1(n,:) = NaN;
        IC.adaptation2(n,:) = NaN;
        IC.peak_adaptation1(n,:) = NaN;
        IC.peak_adaptation2(n,:) = NaN;
        IC.maxFiringRate(n,1) = NaN;
        IC.rheobaseSP(n,1) = NaN;
        IC.latencySP(n,1) = NaN;
        IC.peakSP(n,1) = NaN;
        IC.thresholdSP(n,1) = NaN;
        IC.half_width_threshold_peakSP(n,1) = NaN;
        IC.half_width_peak_troughSP(n,1) = NaN;
        IC.height_threshold_peakSP(n,1) = NaN;
        IC.height_peak_troughSP(n,1) = NaN;
        IC.peak_up_strokeSP(n,1) = NaN;
        IC.peak_down_strokeSP(n,1) = NaN;
        IC.peak_stroke_ratioSP(n,1) = NaN;
        IC.troughSP(n,1) = NaN;
        IC.wfSP(n,:) = nan(1,226);
        IC.wfLP(n,:) = nan(1,226);