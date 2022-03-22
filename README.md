#MATFX
======

##Overview:
-------

This MATLAB code is meant for feature extraction and quality control of intracellular electrophysiology recordings in the NWB format. 
It was developed in the Martinez Lab for said purpose. This code is meant to be used for laboratories who also convert their intracellular recordings 
into NWB files following certain standards and conventions in documentation and organization of metadata. You can find MATLAB code used for conversion 
of recordings following said standards from various different software and hardware [here](https://github.com/neuronex-wm/irg2_conversion). This code 
has been used sucsessfully to analzye data originally recorded in formats such as abf (molecular devices, MultiClamp700), dat (HEKA, Patchmaster) and 
cfs (Camebridge electronic devices). See more on required nwb conversion standards [here](#NWB-conversion-standards). So far the code is meant for 
extracting features from standard electrophysiological characterization protocols: i.e. a long square pulse (hyperpolaizing and depolarizing; 
subthreshold and suprathreshold) and a short square pulse meant to elicit a single spike (depolarizing suprathreshold).

##Additional Requirements:
-------
-This code has been developed in MATLAB2020b and requires the following additional toolboxes: curve fitting and statistics. Compatability with other versions has not been tested.

-MATNWB repository: Code has been written using Release v2.4, you find it [here](https://github.com/NeurodataWithoutBorders/matnwb) and should be compatabile with  v2.4.0; 
for analysis of NWB 1.0 files a transcription with the script \utilites\oldAIBSfiles2NWB is necessary. This code was specifcally written for first release of the cell type 
data base of Allen Insitute for Brain Science into a format that can be processed with runPipeline.

##Independent functions
-------
**1) runPipeline:**  this is the main script. It determines which cells or sweeps do not pass quality control (QC) and disregards these for generating the electrophysiological feature summary. 
It produces several additional tables with analysis results, various plots as well as appended NWB files that contain QC-independent processing moduls with all interim analysis. 
This additional data contains all extracted features for individual sweeps and spikes such as all action potential waveform parameters, spike count, interspike intervals, QC parameters and so on.
In addition the intracellular sweep table contains for documenting pass or fail of the respective sweep in regard of the used QC. A detailed description of number and nature of the input arguments
can be found within the function [here](https://github.com/mfeyerab/MATFX/blob/dev/runPipeline.m). Name and method for determined features can be found under utilites\FeatureTable.   

**2) loadParams:** this function contains all parameters assigned manually by the analyist; such as cut-offs for spike detection and QC, time windows for determining certain QC parameters 
 as well as tags and nature of the desired and undesired protocol types.

**3) runQCsummary(in development):** this function creates several plots to visualize the distribution of QC parameters and their impact on the removal of cells and sweeps. 
If the file naming convention is followed (see [here](#NWB-conversion-standards)), plots are also created for each individual experimenter/rig.

**3) runSummary(in development):** 
runSummary is meant to produce the same output files as runPipeline, but using already processed NWB files as input.

##NWB conversion standards:
-------
