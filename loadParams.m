function PS = loadParams


% Definitions LP and SP tags  (stimulus description giving away the stim length)
PS.LPtags = ["LP","SubThresh", "SupraThresh", "LS", "Long Pulse"];
PS.SPtags = ["SP","C1SS"];
PS.LPlength = 1;
PS.SPlength = 0.003;
PS.SkipTags = ["Ramp",...
    "Search","SQCAP","C1RP", "CHIRP", "COARSE", "EXPEND", "I-V", "unknown"];

% plotting functions
PS.plot_all = 0;
PS.pltForm = '-jpg';
PS.Webexport=0; 

% spike detection
PS.thresholdV = -15;                             % detection threshold for V-based spikes
PS.thresholdDVDT = 20;                           % detection threshold for dV/dt-based spikes

% target sampling PSmeters
PS.sampleRT = 5e4;                               % sample rate we want
PS.sampleRTdt = 1000/PS.sampleRT;                 % sample rate we want

% cell-wise quality control PSmeters
PS.cutoffInitRa = 24;
PS.factorRelaRa = 0.25;
PS.noSupra = 1;
PS.maxRheoSpikes = 100;

% swep-wise root mean square quality control PSmeters
PS.LPqc_samplWind = 100; PS.LPqc_recovTime = 850; 
PS.SPqc_samplWind = 100; PS.SPqc_recovTime = 600;
PS.preAIBS_samplWind = 199;
PS.RMSEst = 0.3;                                 % maximum RMSE measure short term
PS.RMSElt = 0.75;                                 % maximum RMSE measure long term
PS.RMSEdiff = 0.2; 
PS.maxDiffBwBeginEnd = 8;                        % maximum difference between beginning and end of sweep
PS.maximumRestingPot = -49;                      % minimum resting potential
PS.holdingI = 100;                               % maximum holding current
PS.bridge_balance = 24;                          % maximum bridge balance
PS.minGoodSpFra = 0.25;
PS.BwSweepMax = 4.5;

% rebound slope and spike PSmeters
PS.reboundWindow = 100;                          % window to find maximum rebound peak
PS.reboundFitWindow = 150;                       % window from max rebound peak to fit / acquireRes
PS.reboundSpWindow = 50;                         % window to look for rebound spikes (ms)
PS.GF = 0.85;                                    % goodness of fit for exponential fit for tau

% spike-wise quality control PSmeters
PS.pcentMaxdVdt = 0.1;                           % threshold = < % of dVdt
PS.absdVdt = 2.9;                                % threshold = absolute value
PS.minRefract = 0.5;                             % min refractory
PS.mindVdt = 5;                                  % minimum amount of dV/dt
PS.minDiffThreshold2PeakN = 35;                  % max diff in V bw threshold and peak for narrow 
PS.minDiffThreshold2PeakB = 45;                  % max diff in V bw threshold and peak for broad
PS.maxDiffThreshold2PeakT = 2;                   % max diff in t bw threshold and peak
% PS.minDiffPeak2Trough = 30;                      % max diff in V bw peak and trough
% PS.maxDiffPeak2TroughT = 10;                     % max diff in t bw peak and trough
PS.percentRheobaseHeight = .3;                   % APSms must be X percent of Rheobase height
PS.maxThreshold = -18;                           % above this value APs are eliminated (mV)
PS.minTrough = -30;                              % above this value APs are eliminated (mV)

% check PSms.minTrough (any removals) PSms.minTrough adjusted to threshold