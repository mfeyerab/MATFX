function ICsummary = initICSummary(cellList)

temp = {cellList.name};
temp = cellfun(@(S) S(1:end-4), temp, 'Uniform', 0);
features = {...
    'Vrest' 'resistanceHD' 'resistanceSS' 'tau' 'Rheo' 'sagVrest' ...
    'sag' 'sag_ratio' 'sagAmp' 'widthTP_LP' 'peakLP' 'thresholdLP' ...
    'fastTroughLP' 'slowTroughLP' 'peakUpStrokeLP' 'peakDownStrokeLP' ...
    'peakStrokeRatioLP' 'heightTP_LP' 'latency' ...
    'CurrentStepSP' 'thresholdSP' 'fastTroughSP' 'slowTroughSP' 'heightTP_SP' ...
    'peakUpStrokeSP' 'peakDownStrokeSP' 'peakStrokeRatioSP' ...
    'latencySP' 'widthTP_SP' 'peakSP' 'MinLastQui'...
    'medInstaRate' 'ISIs_P90' 'ISIs_P10' 'ISIs_IQR' 'AdaptRatioB1B2' ...
    'AdaptRatioB1B20' 'StimAdaptation' 'fI_slope'...
    'maxFiringRate' 'rectification' 'cvISI' 'HeroRate' 'HeroAmp' 'heroLatency' ...
    'peakAdapt' 'adaptIndex' 'burst' 'Temperature' 'resistanceOffset'};

ICsummary = array2table(NaN(length(cellList),length(features)), ...
    'VariableNames', features,'RowNames', temp);

ICsummary.dendriticType(:) = {'NA'};
ICsummary.SomaLayerLoc(:) = {'NA'};
ICsummary.ReporterTag(:) = {'None'}; 
ICsummary.brainOrigin(:) = {'NA'};
ICsummary.Weight(:) = {'NA'};
ICsummary.Sex(:) = {'NA'};
ICsummary.Age(:) = {'NA'};
ICsummary.Species(:) = {'NA'};
end