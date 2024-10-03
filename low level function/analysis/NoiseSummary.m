function [NoiseSum, PS] = NoiseSummary(nwb, NoiseSum, ClNr, PS, NoiseSpPattrn)

IcephysTab = nwb.general_intracellular_ephys_intracellular_recordings;     % Assign new variable for readability
SwpRespTbl = IcephysTab.responses.response.data.load.timeseries;           % Assign new variable for readability
SwpPaths = {SwpRespTbl.path};                                              % Gets all sweep paths of sweep response table and assigns it to a new variable  
SwpIDs = cellfun(@(a) str2double(a), cellfun(@(v)v(1),...                  % Extract the numbers from the sweep names as doubles  
                                       regexp(SwpPaths,'\d*','Match')));   % inner cellfun necessary if sweep name contains mutliple numbers for example an extra AD01 


Proto = strtrim(string(IcephysTab.dynamictable.map('protocol_type'...
                     ).vectordata.values{1}.data.load));
NoiseIdx = contains(cellstr(Proto),PS.Noisetags);
NoiseIDs = SwpIDs(NoiseIdx);

%% ISI analysis
ISIs = [NoiseSpPattrn.ISIs{:}];

figure('Visible','on'); hold on
if ~isempty(ISIs)
cdfplot(1000./ISIs); grid off; box off;
cdfplot(1000./ISIs); grid off; box off;
end
xlabel('instantenous frequency (Hz)'); 
title('Dynamic frequency range');
legend({'Noise', 'LP'})
      F=getframe(gcf);
      imwrite(F.cdata,fullfile(PS.outDest, 'firingPattern', ...
                                  [PS.cellID,'_NoiseDFR',PS.pltForm]))

NoiseSum.medInstaFreq(ClNr) = 1000/median(ISIs);
NoiseSum.P90(ClNr) = prctile(1000./ISIs,90);
NoiseSum.P10(ClNr) = prctile(1000./ISIs,10);
NoiseSum.IQR(ClNr) = iqr(1000./ISIs);

writetable(ISIexport , fullfile(PS.outDest, 'firingPattern', ...
                                  [PS.cellID,'_NoiseISIs.csv']));

%% export Noise ISIs
% writestruct(NoiseSpPattrn.spTrain  , fullfile(PS.outDest, 'firingPattern', ...
%                                   [PS.cellID,'_Noise.xml']));
% ISIexport = table();
% ISIidx = ISIs.map('ISIs_index').data;
% 
% for s=1:length(NoiseIDs) 
%         ISIexport.SweepID(s) = NoiseIDs(s);
%         if s==1
%          ISIexport.ISIs(s) = {ISIs.map('ISIs').data(1:ISIidx(1))};
%         else
%          ISIexport.ISIs(s) = {ISIs.map('ISIs').data(...
%                                 ISIidx(s-1)+1:ISIidx(s))};
%         end
% end
