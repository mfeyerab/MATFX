# MATFX

## Overview:
This MATLAB code is meant for feature extraction and quality control of intracellular characterizations of cellular biopysical properties in current clamp 
saved in the NWB format. It was developed in the Martinez Lab. 
This code is meant to be used for laboratories who also convert their intracellular recordings into NWB files following certain standards 
and conventions in documentation and organization of metadata. You can find MATLAB code used for conversion 
of recordings following said standards from various different software and hardware [here](https://github.com/neuronex-wm/irg2_conversion). This code 
has been used sucsessfully to analzye data originally recorded in formats such as abf (molecular devices, MultiClamp700), dat (HEKA, Patchmaster) and 
cfs (Camebridge electronic devices). See more on required nwb conversion standards [here](#NWB-conversion-standards). So far the code is meant for 
extracting features from standard electrophysiological characterization protocols: i.e. a long square pulse (hyperpolaizing and depolarizing; 
subthreshold and suprathreshold) and a short square pulse meant to elicit a single spike (depolarizing suprathreshold).

## Additional Requirements:
-This code has been developed in MATLAB2020b and requires the following additional toolboxes: curve fitting and statistics. Compatability with other versions has not been tested.

-MATNWB repository: Code has been written using Release v2.4, you find it [here](https://github.com/NeurodataWithoutBorders/matnwb) and should be compatabile with  v2.4.0; 
for analysis of NWB 1.0 files a transcription with the script \utilites\oldAIBSfiles2NWB is necessary. This code was specifcally written for first release of the cell type 
data base of Allen Insitute for Brain Science into a format that can be processed with runPipeline.

## Independent functions
**1) runPipeline:**  this is the main script. It determines which cells or sweeps do not pass quality control (QC) and disregards these for generating the electrophysiological feature summary. 
It produces several additional tables with analysis results, various plots as well as appended NWB files that contain QC-independent processing moduls with all interim analysis. 
This additional data contains all extracted features for individual sweeps and spikes such as all action potential waveform parameters, spike count, interspike intervals, QC parameters and so on.
In addition the intracellular sweep table contains for documenting pass or fail of the respective sweep in regard of the used QC. A detailed description of number and nature of the input arguments 
and possible output files can be found within the function [here](https://github.com/mfeyerab/MATFX/blob/dev/runPipeline.m). 
Name and method for determined features can be found under utilites\FeatureTable.   

**2) loadParams:** this function contains all parameters assigned manually by the analyist; such as cut-offs for spike detection and QC, time windows for determining certain QC parameters 
 as well as tags and nature of the desired and undesired protocol types. It is possible to disable the creation of plots and web exports here.

**3) runQCsummary(in development):** this function creates several plots to visualize the distribution of QC parameters and their impact on the removal of cells and sweeps. 
If the file naming convention is followed (see [here](#NWB-conversion-standards)), plots are also created for each individual experimenter/rig.

**3) runSummary(in development):** 
runSummary is meant to produce the same output files as runPipeline, but using already processed NWB files as input.

## NWB conversion standards:
### file name
**SSS_EE_SS_CC** S: 3 characters for the Subject ID, E: 2 characters for experimenter/rig id (for example initials or number), W: 2 characters for slice id, this could be for example the name of cell culture well,
the slice was fixed (like A1). This is helpful for histological processing and if there are multiple cells in 1 slice. However, this information is not used in any of the code so far.

### protocol names and addendums to the intracellular recordings table
Each nwb file based on the 2.4 schema contains under general/intracellular_ephys/intracellular_recordings/ an object called IntracellularRecordingsTable 
(all MATNWB objects mentioned here have the following names with the same prefix, so the proper name is types.core.IntracellularRecordingsTable) to provide an overview of different
electrodes (think of dual recordings for example), sweeps, stimuli, responses and so on (see [here](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/icephys.html) for a detailed explanation). 
Our standard adds another column to this table called 'protocol_type' to designate which sweep is a long pulse (label has to be 'LP') and which is a short pulse (label has to be 'SP'). Protocols that do not
match either of these types have to be labeled 'unknown' and are ignored through the analysis. 
In addition, current amplitudes are added in a similar manner under /stimuli/current_amplitude/, to have an easy aggregate of various current steps for the respective square pulse. These values should be in picoAmpere.
and if they are extracted from the raw current channel, they should be rounded to nearest full pA value (159.987 pA -> 160 pA).  

### testpulse
The use of a testpulse is strongly recommendend, but its use has not been explicitly embedded into the nwb schema. Hence, amplitude, duration and voltage response of the testpulse can only be appreciated
by going through the data property of the CurrentClampStimulusSeries object CurrentClampSeries object, respectivly. MATFX is aimed to detect a single test pulse in front of the actual stimulus onset of the protocol 
by examining the raw current data in CurrentClampStimulusSeries.
  
### metadata
1) Metadata associated with the entire run (meaning the individual patch attempt) are saved in the IntracellularElectrode object. 
Without information in the optional property 'initial_access_resistance' the automated QC will not be able to asses the cell proberly and might even throw errors. 
Temperature during the recording is saved under the property 'slice', but there is no QC evaluation of the temperature.
 
2) Metadata associated with the certain sweep or protocol are saved in the CurrentClampSeries object. This object is specifcally designed for
the voltage channel of a current clamp recording. Without information in the following optional properties the automated QC might not be able to asses the sweep 
proberly and may cause errors:  'bias_current', 'bridge_balance'
 a) According to NWB convention the bias_current is suppose to be reported in Ampere, but saving the value in the more practical picoAmpere should also work; 
    it is not sufficient to only save the corresponding raw current channel as CurrentClampStimulusSeries object without extracting a baseline value 
	as holding current and saving it in the .CurrentClampSeries!
 b) According to NWB convention the bridge balance is suppose to be reported in Ohm, but saving the value in the more practical MegaOhm should also work; not all 
    recording equipment does document the value of the bridge automatically. For devices using the MultiClampCommander (molecular devices) use the 
	python script mcc_get_settings.py developed from the Allen Brain Insitute from [here](https://github.com/AllenInstitute/ipfx/tree/master/ipfx/bin).	

    