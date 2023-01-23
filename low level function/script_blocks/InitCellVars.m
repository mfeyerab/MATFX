%% For plotting profile
 [PS.sagSwpTabPos,PS.rheoSwpTabPos, PS.heroSwpTabPos, ...
  PS.rheoSwpDat, PS.SPSwpDat, PS.SPSwpTbPos, PS.heroSwpAPPDat] = deal([]); % initialize variabels to store sweep table position in plotting structure
 [PS.sagSwpSers,PS.rheoSwpSers, PS.heroSwpSers, PS.SPSwpSers] = ...
      deal(types.core.CurrentClampSeries.empty); 
%% Setting up QC tables and initializing variables
  if PS.manTPremoval && ...                                                % if manual removal due to test pulse is enabled
              exist(fullfile(mainFolder, 'inputTabsTP', [PS.cellID,'_TP.csv']))     % if table with results of manual test pulse review exists
          
    TPtab = readtable(fullfile(mainFolder, 'inputTabsTP', [PS.cellID,'_TP.csv']));  % read table with results of manual test pulse review
  elseif PS.manTPremoval
      error('No result file for manual test pulse review')
  end
  SpPattrn.ISIs = {}; SpPattrn.spTrain = struct(); QC.Spike = struct();    % initializing variables for interspike intervals, spike train parameters, spike QC 
  PS.subCount = 1; PS.supraCount = 1;                                      % starting counting variables for sub- and suprathreshold variables
  SpPattrn.spTrainIDs = {}; SpPattrn.BinTbl = zeros(0,13);                 % initializing variables to save spike train sweep IDs and binned spike train table
  SpPattrn.RowNames = {};                                                  %
  LPexport = table();                                                      % initializing table for exporting raw data traces as csv 