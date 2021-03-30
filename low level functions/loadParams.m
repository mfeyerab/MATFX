function p = loadParams

% plotting functions
p.plot_all = 0;

% spike detection
p.thresholdV = -20;                             % detection threshold for V-based spikes
p.thresholdDVDT = 20;                           % detection threshold for dV/dt-based spikes

% swep-wise root mean square quality control parameters
p.RMSEst = .25;                                 % maximum RMSE measure short term
p.RMSElt = 0.75;                                % maximum RMSE measure long term
p.maxDiffBwBeginEnd = 3.5;                      % maximum difference between beginning and end of sweep
p.maxDiffBwSweeps = 10;                         % maximum difference b/w sweeps
p.minimumRestingPot = -50;                      % minimum resting potential

% rebound slope and spike parameters
p.reboundWindow = 100;                          % window to find maximum rebound peak
p.reboundFitWindow = 150;                       % window from max rebound peak to fit / acquireRes
p.reboundSpWindow = 50;                         % window to look for rebound spikes (ms)

% target sampling parameters
p.sampleRT = 5e4;                               % sample rate we want
p.sampleRTdt = 1000/p.sampleRT;                 % sample rate we want

% spike-wise quality control parameters
p.pcentMaxdVdt = 0.05;                          % threshold = < % of dVdt
p.absdVdt = 2.9;                                % threshold = absolute value
p.minRefract = 0.5;                             % min refractory
p.mindVdt = 5;                                  % minimum amount of dV/dt
p.minDiffThreshold2PeakN = 35;                  % max diff in V bw threshold and peak for narrow 
p.minDiffThreshold2PeakB = 45;                  % max diff in V bw threshold and peak for broad
p.maxDiffThreshold2PeakT = 1.5;                   % max diff in t bw threshold and peak
% p.minDiffPeak2Trough = 30;                      % max diff in V bw peak and trough
% p.maxDiffPeak2TroughT = 10;                     % max diff in t bw peak and trough
p.percentRheobaseHeight = .3;                   % APs must be X percent of Rheobase height
p.maxThreshold = -27.5;                           % above this value APs are eliminated (mV)
p.minTrough = -30;                              % above this value APs are eliminated (mV)

% check p.minTrough (any removals) p.minTrough adjusted to threshold