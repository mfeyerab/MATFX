function [NoiseSum, PS] = NoiseSummary(nwb, NoiseSum, ClNr, PS)

Stats = nwb.processing.map('Noise Stimulus').dynamictable.values{2}.vectordata;
IcephysTab = nwb.general_intracellular_ephys_intracellular_recordings;     % Assign new variable for readability
SwpRespTbl = IcephysTab.responses.response.data.load.timeseries;           % Assign new variable for readability
SwpPaths = {SwpRespTbl.path};                                              % Gets all sweep paths of sweep response table and assigns it to a new variable  
SwpIDs = cellfun(@(a) str2double(a), cellfun(@(v)v(1),...                  % Extract the numbers from the sweep names as doubles  
                                       regexp(SwpPaths,'\d*','Match')));   % inner cellfun necessary if sweep name contains mutliple numbers for example an extra AD01 


Proto = strtrim(string(IcephysTab.dynamictable.map('protocol_type'...
                     ).vectordata.values{1}.data.load));
NoiseIdx = contains(cellstr(Proto),PS.Noisetags);
NoiseIDs = SwpIDs(NoiseIdx);
%% Noise features
NoiseSum.MeanFR1(ClNr) = nanmean(Stats.map('FR1').data) ;
NoiseSum.MeanFR2(ClNr) = nanmean(Stats.map('FR2').data) ;
NoiseSum.MeanFR3(ClNr) = nanmean(Stats.map('FR3').data) ;
NoiseSum.VarFR1(ClNr) = nanvar(Stats.map('FR1').data) ;
NoiseSum.VarFR2(ClNr) = nanvar(Stats.map('FR2').data) ;
NoiseSum.VarFR3(ClNr) = nanvar(Stats.map('FR3').data) ;

if NoiseSum.MeanFR1(ClNr)>2
 NoiseSum.CV1(ClNr) = mean(Stats.map('CV1').data);
else
 NoiseSum.CV1(ClNr) = NaN;
end

if NoiseSum.MeanFR2(ClNr)>2
 NoiseSum.CV2(ClNr) = mean(Stats.map('CV2').data);
else
 NoiseSum.CV2(ClNr) = NaN;
end

NoiseSum.CV3(ClNr) = mean(Stats.map('CV3').data);


%% ISI analysis
ISIs = nwb.processing.map('Noise Stimulus').dynamictable.values{...
                    1}.vectordata;
LP_ISIs = nwb.processing.map('AP Pattern').dynamictable.map(...
              'ISIs').vectordata.values{1}.data;  
LP_ISIs = LP_ISIs(~isnan(LP_ISIs)); LP_ISIs(LP_ISIs==0) = [];               % get rid of 0 and nans  



%% export Noise ISIs
% writestruct(NoiseSpPattrn.spTrain  , fullfile(PS.outDest, 'firingPattern', ...
%                                   [PS.cellID,'_Noise.xml']));
ISIexport = table();
ISIidx = ISIs.map('ISIs_index').data;

for s=1:length(NoiseIDs) 
        ISIexport.SweepID(s) = NoiseIDs(s);
        if s==1
         ISIexport.ISIs(s) = {ISIs.map('ISIs').data(1:ISIidx(1))};
        else
         ISIexport.ISIs(s) = {ISIs.map('ISIs').data(...
                                ISIidx(s-1)+1:ISIidx(s))};
        end
end

figure('Visible','on'); hold on
if ~isempty(ISIs.map('ISIs').data)
cdfplot(1000./ISIs.map('ISIs').data); grid off; box off;
cdfplot(1000./LP_ISIs); grid off; box off;
end
xlabel('instantenous frequency (Hz)'); 
title('Dynamic frequency range');
legend({'Noise', 'LP'})
      F=getframe(gcf);
      imwrite(F.cdata,fullfile(PS.outDest, 'firingPattern', ...
                                  [PS.cellID,'_NoiseDFR',PS.pltForm]))

writetable(ISIexport , fullfile(PS.outDest, 'firingPattern', ...
                                  [PS.cellID,'_NoiseISIs.csv']));
