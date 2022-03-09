%% For plotting profile
  [PS.sagSwpTabPos,PS.rheoSwpTabPos, PS.heroSwpTabPos, ...
  PS.rheoSwpDat, PS.SPSwpDat, PS.SPSwpTbPos, PS.heroSwpAPPDat] = deal([]); % initialize variabels to store sweep table position in plotting structure
  [PS.sagSwpSers,PS.rheoSwpSers, PS.heroSwpSers, PS.SPSwpSers] = ...
      deal(types.core.CurrentClampSeries); 
%% Setting up QC tables and initializing variables
  QC.params = table(); QC.testpulse = cell(0,0);                              % creating empty MATLAB table for QC paramters
  QC.params.SweepID = repmat({''},length(nwb.acquisition.keys),1);         % initializing SweepID column of QC paramters table
  QC.params.Protocol = repmat({''},length(nwb.acquisition.keys),1);        % initializing Protocol column of QC paramters table
  QC.params(:,3:length(qc_tags(2:end))+2) = array2table(NaN(...         
    length(nwb.acquisition.keys), length(qc_tags)-1));                     % initializing actual parameter variables with NaNs
  QC.params.Properties.VariableNames(3:width(QC.params)) = ...        
      [qc_tags(3:end), {'CapaComp'}];                                      % naming parameter variables
  QC.pass = table();                                                       % creating empty MATLAB table for QC passing logic 
  QC.pass.SweepID = repmat({''},length(nwb.acquisition.keys),1);           % initializing SweepID column of QC passing table 
  QC.pass.Protocol = repmat({''},length(nwb.acquisition.keys),1);          % initializing Protocol column of QC passing table
  QC.pass(:,3:length(qc_tags)+1) = ...
      array2table(NaN(length(nwb.acquisition.keys), length(qc_tags)-1));   % initializing logic values for passing table
  QC.pass.Properties.VariableNames(3:width(QC.pass)) = qc_tags(2:end);      % naming passing parameters variables
  
  SpPattrn.ISIs = {}; SpPattrn.spTrain = struct(); QC.Spike = struct();    % initializing variables for interspike intervals, spike train parameters, spike QC 
  PS.subCount = 1; PS.supraCount = 1;                                      % starting counting variables for sub- and suprathreshold variables
  SpPattrn.spTrainIDs = {}; SpPattrn.BinTbl = zeros(0,13);                 % initializing variables to save spike train sweep IDs and binned spike train table
  SpPattrn.RowNames = {};                                                  %
  LPexport = table();                                                      % initializing table for exporting raw data traces as csv 
 %% Improve readibility by creating additonal variables with shorter names
 ICEtab = nwb.general_intracellular_ephys_intracellular_recordings;   % assigning IntracellularRecordinsTable to new variable for readability of subsequent code
 RespTbl = ICEtab.responses.response.data.load;                   % loading all sweep response from IntracellularRecordingsTable
 ProtoTags = ICEtab.dynamictable.values{1}.vectordata.values{1}.data.load;
 info = nwb.general_intracellular_ephys;   

 
 %% Initialize processing moduls and new columns for Sweep table
 initProceModules                                                         % initialize processing modules
 nwb  = addColumns2SwTabl(nwb,qc_tags);                                   % add initialized QC to sweep table 