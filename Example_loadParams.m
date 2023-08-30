function PS = loadParams
%function for loading manually set parameters relevant for processing and
%visualization; the analyist can change parameters here to the desired
%values.

%% Definitions of protocol tags (stimulus description giving away the stim structure)
%these tags are used for detecting protocol types from nwb files from the AIBS
%both the pre-PatchSeq (Gouwens et al. 2019) and the PatchSeq dataset (Gouwens 
%et al. 2020). 
%Additionally length of the long pulse and short pulse can be  
%manipulated. This might be helpful to apply some of the analysis to other types
%of protocols such as 500 ms long pulse, but this has not been tested as  
%of now April 2022. 
%SkipTags are character patterns which indicate a protocol type that cannot or 
%should not  be analyzed with the current code such as Ramp or Chirp stimulus.
%The tag "unknown" is used in the NeuroNex conversion pipeline for protocols 
%with a stimulus structure that does not much either long pulse or short pulse

PS.LPtags = ["LP","SubThresh", "SupraThresh", "LS", "Long"];                 
PS.SPtags = ["SP","C1SS", "Short"];
PS.LPlength = 1;
PS.SPlength = 0.003;
PS.SkipTags = ["Ramp","Search","SQCAP","C1RP", "CHIRP", "COARSE", "EXPEND"...
   , "I-V", "unknown", "Unknown", "Noise", "0.5ms", "Triple", ...
   "2s", "-80mV", "-60mV", "-70mV"];

%% plotting parameters
%plot_all can be either: 0 for a minimal amount of additional visualization;
%1 for standard visualization, 2 for extensive visualizations (includes 
%raw voltage data of RMSE integration window for each sweep)

PS.plot_all = 1;
PS.pltForm = '.png';
PS.Webexport=0; 

%% spike detection and analysis
PS.thresholdV = -15;                                                       % detection threshold for V-based spikes
PS.thresholdDVDT = 20;                                                     % detection threshold for dV/dt-based spikes
PS.refPeakSlop = 1;                                                        % refined peak up and down stroke are filtered before max/min analysis => needs much more processing time  
PS.enableSpQC = 0;                                                         % parameter to determine if spike "quality" will be evaluated
PS.ThresHFNoise = 0.125;                                                   % minimum length of a separate suprathreshold event to be considered a potential spike in ms
PS.minISI = 1;                                                             % minimum time for checking for the next spike    
%% resampling
PS.sampleRT = 5e4;                                                         % sample rate we want
PS.sampleRTdt = 1000/PS.sampleRT;                                          % sample rate we want

%% cell-wise quality control parameters
PS.cutoffInitRa = 60;                                                      % cut off for absolute value of intial access resistance  
PS.factorRelaRa = 0.25;                                                    % cut off for relative value of intial access resistance  
PS.noSupraSub = 1;                                                         % binary variable for kicking cells without suprathreshold features
PS.maxRheoSpikes = 100;                                                    % maximum number of spikes the rheobase sweep is allowed to have 
PS.maxCellBasLinPot = -55;                                                 %
PS.InitRa = 0;                                                             %
%% sweep-wise quality control parameters and integration windows
PS.LPqc_samplWind = 0.375; PS.LPqc_recovTime = 4.75;                       % determine length and distance (in seconds) to stimulus end for window of RMSE calculations for the long pulse  
PS.SPqc_samplWind = 0.25; PS.SPqc_recovTime = 0.650;                       % determine length and distance (in seconds) to stimulus end for window of RMSE calculations for the short pulse 
PS.preTP= 0.015; PS.TPtrace = 0.08;                                        % determine length (in seconds) of prestimulus intervall and length of voltage trace for test pulse
PS.RMSEst = 0.3;                                                           % maximum RMSE measure short term
PS.RMSElt = 0.65;                                                           % maximum RMSE measure long term
PS.RMSEdiff = 0.2; 
PS.maxDiffBwBeginEnd = 2.5;                                                  % maximum difference between beginning and end of sweep
PS.maxSwpBasLinPot = -52.5;                                                % minimum resting potential
PS.holdingI = 300;                                                         % maximum holding current
PS.bridge_balance = 35;                                                    % maximum bridge balance
PS.bridge_balance_HEKA = 55; 
PS.minGoodSpFra = 0.25;                                                    % minimum fraction of good spikes to pass sweep QC
PS.BwSwpMode = 2;                                                          %1: target determined by a robust average of the first five sweeps: between sweep quality 
                                                                           %2: deviations from the robust average of all sweeps.
PS.BwSweepMax = 6;                                                         % maximum allowed deviation of the baseline membrane potential to initial resting membrane potential
PS.manTPremoval = 1;                                                       % binary variable to enable/disable manual TP removal 
PS.rRA = 0;
%% parameters for subthreshold analysis
PS.reboundWindow = 100;                                                    % window to find maximum rebound peak
PS.reboundFitWindow = 150;                                                 % window from max rebound peak to fit / acquireRes
PS.reboundSpWindow = 50;                                                   % window to look for rebound spikes (ms)
PS.GF = 0.85;                                                              % goodness of fit for exponential fit for tau
PS.maxDefl = -11;                                                          % maximum deflection in mV for determining tau
PS.WinHD = 0.2;                                                            % time window from stimulus onset to search for point of highest deflection
PS.postFilt = 1;
%% spike-wise quality control parameters
PS.pcentMaxdVdt = 0.1;                                                     % threshold = < % of dVdt
PS.absdVdt = 2.9;                                                          % threshold = absolute value
PS.minRefract = 0.5;                                                       % min refractory
PS.mindVdt = 5;                                                            % minimum amount of dV/dt
PS.minDiffThreshold2PeakN = 35;                                            % max diff in V bw threshold and peak for narrow 
PS.minDiffThreshold2PeakB = 45;                                            % max diff in V bw threshold and peak for broad
PS.maxDiffThreshold2PeakT = 2;                                             % max diff in t bw threshold and peak
% PS.minDiffPeak2Trough = 30;                                              % max diff in V bw peak and trough
% PS.maxDiffPeak2TroughT = 10;                                             % max diff in t bw peak and trough
PS.percentRheobaseHeight = .3;                                             % APSms must be X percent of Rheobase height
PS.maxThreshold = -18;                                                     % above this value APs are eliminated (mV)
PS.minTrough = -30;                                                        % above this value APs are eliminated (mV)

% check PSms.minTrough (any removals) PSms.minTrough adjusted to threshold