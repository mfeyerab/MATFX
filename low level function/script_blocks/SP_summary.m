%{
summary SP analysis
%}

[ampSP,idxSP] = sort(round(double(a.SP.sweepAmps(1:length(a.SP.stats)))));
IC.SP_input_current_s(n,1:length(ampSP)) = round(double(a.SP.sweepAmps(idxSP)));
PotenRheo = [];
RheoSweeps = [];
cycler = 0;

           for k = 1:length(idxSP)
                if isfield(a.SP.stats{idxSP(k),1},'spTimes') && ...
                        ~isnan(a.SP.stats{idxSP(k),1}.spTimes)==1
                   while length(unique(RheoSweeps)) < 3 && k+cycler <= length(ampSP)
                        PotenRheo = idxSP(ampSP==ampSP(k+cycler));
                        for i = 1:length(PotenRheo)
                           if isfield(a.SP.stats{PotenRheo(i),1},'spTimes') &&... 
                               ~isnan(a.SP.stats{PotenRheo(i),1}.spTimes )
                               RheoSweeps = [RheoSweeps, PotenRheo(i)];
                           end
                        end
                        cycler = cycler +1;
                   end
               RheoSweeps = unique(RheoSweeps);
               IC.rheobaseSP(n,1) = mean(a.SP.sweepAmps(RheoSweeps),1);
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
               wavesSP = zeros(1,226);
               for r = 1:length(RheoSweeps)
                  delay(1,r) = unique(a.SP.stats{RheoSweeps(r),1}.delay);
                  burst(1,r) = a.SP.stats{RheoSweeps(r),1}.burst;
                  latency(1,r) = unique(a.SP.stats{RheoSweeps(r),1}.latency);
                  peak(1,r) = a.SP.stats{RheoSweeps(r),1}.peak(1);
                  thresholdRef(1,r) = a.SP.stats{RheoSweeps(r),1}.thresholdRef(1);
                  fullWidthTP(1,r) = a.SP.stats{RheoSweeps(r),1}.fullWidthTP(1);
                  fullWidthPT(1,r) = a.SP.stats{RheoSweeps(r),1}.fullWidthPT(1);
                  heightTP(1,r) = a.SP.stats{RheoSweeps(r),1}.heightTP(1);
                  heightPT(1,r) = a.SP.stats{RheoSweeps(r),1}.heightPT(1);
                  peakUpStroke(1,r) = a.SP.stats{RheoSweeps(r),1}.peakUpStroke(1);
                  peakDownStroke(1,r) = a.SP.stats{RheoSweeps(r),1}.peakDownStroke(1);
                  peakDownStroke(1,r) = a.SP.stats{RheoSweeps(r),1}.peakStrokeRatio(1);
                  trough(1,r) = a.SP.stats{RheoSweeps(r),1}.trough(1);
                  fastTroughDur(1,r) = a.SP.stats{RheoSweeps(r),1}.fastTroughDur(1);
                  slowTroughDur(1,r) = a.SP.stats{RheoSweeps(r),1}.slowTroughDur(1);
                  wavesSP(r,:) = a.SP.stats{RheoSweeps(r),1}.waves;
               end
                   
               IC.delayRheobaseSP(n,1) = round(mean(delay),2);
               IC.latencyRheobaseSP(n,1) = round(mean(latency),2);
               IC.peakSP(n,1) = round(mean(peak),2);
                    IC.thresholdSP(n,1) = round(mean(thresholdRef),2);
                    IC.half_width_threshold_peakSP(n,1) = round(mean(fullWidthTP),2);
                    IC.half_width_peak_troughSP(n,1) = round(mean(fullWidthPT),2);
                    IC.height_threshold_peakSP(n,1) = round(mean(heightTP),2);
                    IC.height_peak_troughSP(n,1) = round(mean(heightPT),2);
                    IC.peak_up_strokeSP(n,1) = round(mean(peakUpStroke),2);
                    IC.peak_down_strokeSP(n,1) = round(mean(peakDownStroke),2);
                    IC.peak_stroke_ratioSP(n,1) = round(mean(peakStrokeRatio),2);
                    IC.troughSP(n,1) = round(mean(trough),2);
                    IC.fastTroughSP(n,1) = round(mean(fastTroughDur),2);
                    IC.slowTroughSP(n,1) = round(mean(slowTroughDur),2);
                    if IC.slowTroughSP(n,1) < 2                              %  check if the cell has a true fAHP, its peak should be more depolarized than any other afterhyperpolarizations                         
                        IC.fAHPampSP(n,1) = round(mean( ...
                            thresholdRef - trough),2);                     %  amplitude of fAHP from threshold
                    else 
                        IC.fAHPampSP(n,1) = NaN;
                    end
                    IC.wfSP(n,:) = mean(wavesSP,1);               
                else
                    IC.rheobaseSP(n,1) = NaN;
                    IC.delayRheobaseSP(n,1) = NaN;
                    IC.latencyRheobaseSP(n,1) =  NaN;
                    IC.peakSP(n,1) =  NaN;
                    IC.thresholdSP(n,1) =  NaN;
                    IC.half_width_threshold_peakSP(n,1) =  NaN;
                    IC.half_width_peak_troughSP(n,1) =  NaN;
                    IC.height_threshold_peakSP(n,1) =  NaN;
                    IC.height_peak_troughSP(n,1) =  NaN;
                    IC.peak_up_strokeSP(n,1) =  NaN;
                    IC.peak_down_strokeSP(n,1) =  NaN;
                    IC.peak_stroke_ratioSP(n,1) =  NaN;
                    IC.troughSP(n,1) =  NaN;
                    IC.fastTroughSP(n,1) =  NaN;
                    IC.slowTroughSP(n,1) =  NaN;
                    IC.wfSP(n,:) = nan(1,226);
                    IC.fAHPampSP(n,1) = NaN;
                end
           end

           
           