% collect subthreshold data

IC.subamp(n,1) = a.LP.sweepAmps(k,1);
IC.submin(n,1) = round(double(a.LP.stats{k,1}.minV),2);
IC.rebound_slope(n,1) = round(double(a.LP.stats{k,1}.reboundSlope),2);
IC.rebound_depolarization(n,1) = round(double(a.LP.stats{k,1}.reboundDepolarization),2);
IC.sag(n,1) = round(double(a.LP.stats{k,1}.sag),2);
IC.steadystate(n,1) = round(double(a.LP.stats{k,1}.subSteadyState),2);
IC.sag_ratio(n,1) = round(double(a.LP.stats{k,1}.sagRatio),2);
if sum(isnan(a.LP.stats{k,1}.reboundAPs))==0
    IC.nb_rebound_sp(n,1) = length(a.LP.stats{k,1}.reboundAPs);
else
    IC.nb_rebound_sp(n,1) = 0;
end