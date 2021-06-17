function params = loadParams

% plotting functions
params.plot_all = 1;
params.plot_format = '-jpg';

% spike detection
params.thresholdV = -20;                             % detection threshold for V-based spikes
params.thresholdDVDT = 20;                           % detection threshold for dV/dt-based spikes

% target sampling parameters
params.sampleRT = 5e4;                               % sample rate we want
params.sampleRTdt = 1000/params.sampleRT;                 % sample rate we want

% cell-wise quality control parameters
params.cutoffInitRa = 25;
params.factorRelaRa = 0.3;
params.noSupra = 1;
params.maxRheoSpikes = 100;

% swep-wise root mean square quality control parameters
params.LPqc_samplWind = 100; params.LPqc_recovTime = 850; 
params.SPqc_samplWind = 100; params.SPqc_recovTime = 600;
params.preAIBS_samplWind = 199;
params.RMSEst = 0.3;                                 % maximum RMSE measure short term
params.RMSElt = 0.75;                                % maximum RMSE measure long term
params.maxDiffBwBeginEnd = 4.5;                        % maximum difference between beginning and end of sweep
params.maximumRestingPot = -50;                      % minimum resting potential
params.holdingI = 100;                               % maximum holding current
params.bridge_balance = 20;                          % maximum bridge balance
params.minGoodSpFra = 0.33;
params.BwSweepMax = 8;

% rebound slope and spike parameters
params.reboundWindow = 100;                          % window to find maximum rebound peak
params.reboundFitWindow = 150;                       % window from max rebound peak to fit / acquireRes
params.reboundSpWindow = 50;                         % window to look for rebound spikes (ms)

% spike-wise quality control parameters
params.pcentMaxdVdt = 0.1;                          % threshold = < % of dVdt
params.absdVdt = 2.9;                                  % threshold = absolute value
params.minRefract = 0.5;                             % min refractory
params.mindVdt = 5;                                  % minimum amount of dV/dt
params.minDiffThreshold2PeakN = 35;                  % max diff in V bw threshold and peak for narrow 
params.minDiffThreshold2PeakB = 45;                  % max diff in V bw threshold and peak for broad
params.maxDiffThreshold2PeakT = 2;                   % max diff in t bw threshold and peak
% params.minDiffPeak2Trough = 30;                      % max diff in V bw peak and trough
% params.maxDiffPeak2TroughT = 10;                     % max diff in t bw peak and trough
params.percentRheobaseHeight = .3;                   % APs must be X percent of Rheobase height
params.maxThreshold = -25;                           % above this value APs are eliminated (mV)
params.minTrough = -30;                              % above this value APs are eliminated (mV)

% check params.minTrough (any removals) params.minTrough adjusted to threshold