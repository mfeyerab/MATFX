%% For plotting profile
 [PS.sagSwpTabPos,PS.rheoSwpTabPos, PS.heroSwpTabPos, PS.SPSwpTbPos] = ...
     deal([]); %                                                           initialize variabels to store sweep table position in plotting structure
 [PS.sagSwpSers,PS.rheoSwpSers, PS.heroSwpSers, PS.SPSwpSers] = ...
      deal(types.core.CurrentClampSeries.empty); 
%% Setting up QC tables and initializing variables

  SpPattrn.ISIs = {}; NoiseSpPattrn.ISIs = {};
  SpPattrn.Tab = table(); NoiseSpPattrn.spTrain = struct();   
  PS.subCount = 1; PS.supraCount = 1; PS.NoiseCount = 1;                   % starting counting variables for sub- and suprathreshold variables
  SpPattrn.spTrainIDs = {}; NoiseSpPattrn.spTrainIDs = {}; 
  SpPattrn.BinTbl = zeros(0,13);                                           % initializing variables to save spike train sweep IDs and binned spike train table
  SpPattrn.SpTimes = {};                                                   %
  NoiseSpPattrn.RowNames = {};  NoiseSpPattrn.SpTimes = {}; 
  LPexport = table();                                                      % initializing table for exporting raw data traces as csv 
  SubStats = struct();
  APTab = table();

   %% Initialize QC

 QC.params = table(); 
 QC.pass = table(); 
 QC.testpulse = cell(0,0);                                                 % creating empty MATLAB table for QC paramters
 QC.params.SweepID = repmat({''},length(nwb.acquisition.keys),1);          % initializing SweepID column of QC paramters table
 QC.params.Protocol = repmat({''},length(nwb.acquisition.keys),1);         % initializing Protocol column of QC paramters table
 TmpColIdx = width(QC.params)+1;

 QC.params(:,TmpColIdx:length(qc_tags(2:end))+2) = ...
     array2table(NaN(length(nwb.acquisition.keys), length(qc_tags)-1));    % initializing actual parameter variables with NaNs
 QC.params.Properties.VariableNames(TmpColIdx:width(QC.params)) = ...        
      [qc_tags(TmpColIdx:end), {'CapaComp'}];                              % naming parameter variables
 QC.pass.SweepID = repmat({''},length(nwb.acquisition.keys),1);            % initializing SweepID column of QC passing table 
 QC.pass.Protocol = repmat({''},length(nwb.acquisition.keys),1);           % initializing Protocol column of QC passing table
 QC.pass(:,TmpColIdx:length(qc_tags)+2) = ...
      array2table(NaN(length(nwb.acquisition.keys), length(qc_tags)));     % initializing logic values for passing table
 QC.pass.Properties.VariableNames(TmpColIdx:width(QC.pass)-1) = ...
     qc_tags(2:end);                                                       % naming passing parameters variables
 QC.pass.Properties.VariableNames(width(QC.pass)) = {'manuTP'};            % initializing additional variable for sweep wise QC encoding manual test pulse review
 %% Improve readability by creating additonal variables with shorter names
 ICEtab = nwb.general_intracellular_ephys_intracellular_recordings;        % assigning IntracellularRecordinsTable to new variable for readability of subsequent code
     
 RespTbl = ICEtab.responses.response.data.load;                            % loading all sweep response from IntracellularRecordingsTable
 ProtoTags = deblank(string(...
             ICEtab.vectordata.values{1}.data.load));% Gets all protocol names without white space
 info = nwb.general_intracellular_ephys;   