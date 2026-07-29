# MATFX

## Overview
This MATLAB code is meant for feature extraction and quality control of intracellular characterizations of cellular biophysical properties in current clamp, saved in the NWB format. It was developed in the Martinez Lab.

This code is intended for laboratories that also convert their intracellular recordings into NWB files following certain standards and conventions in the documentation and organization of metadata. You can find MATLAB code used for conversion of recordings following those standards, from various different software and hardware, [here](https://github.com/neuronex-wm/irg2_conversion). This code has been used successfully to analyze data originally recorded in formats such as abf (Molecular Devices, MultiClamp 700), dat (HEKA, Patchmaster) and cfs (Cambridge Electronic Design). See more on the required NWB conversion standards [here](#nwb-conversion-standards).

So far the code is meant for extracting features from standard electrophysiological characterization protocols: a long square pulse (hyperpolarizing and depolarizing; subthreshold and suprathreshold) and a short square pulse meant to elicit a single spike (depolarizing suprathreshold).

## Additional Requirements

- This code has been developed in MATLAB 2020b and requires the following additional toolboxes: Curve Fitting and Statistics. Compatibility with other versions has not been tested.

- **MATNWB repository:** Code has been written using Release v2.4, which you can find [here](https://github.com/NeurodataWithoutBorders/matnwb), and should be compatible with v2.4.0. For analysis of NWB 1.0 files, a transcription using the script `\utilites\oldAIBSfiles2NWB` is necessary. That script was written specifically to transcribe the first release of the Allen Institute for Brain Science cell types database into a format that can be processed with `runPipeline`.

## Independent functions

**1) runPipeline:** This is the main script. It determines which cells or sweeps do not pass quality control (QC) and disregards these when generating the electrophysiological feature summary. It produces several additional tables with analysis results, various plots, and appended NWB files containing QC-independent processing modules with all interim analysis. This additional data contains all extracted features for individual sweeps and spikes, such as action potential waveform parameters, spike count, interspike intervals, QC parameters and so on. In addition, the intracellular sweep table contains a column documenting the pass or fail status of each sweep with regard to the QC applied. A detailed description of the number and nature of the input arguments and the possible output files can be found within the function [here](https://github.com/mfeyerab/MATFX/blob/dev/runPipeline.m). Names and methods for the extracted features can be found under `utilites\FeatureTable`.

**2) loadParams:** This function contains all parameters assigned manually by the analyst, such as cut-offs for spike detection and QC, time windows for determining certain QC parameters, and the tags and nature of the desired and undesired protocol types. Creation of plots and web exports can be disabled here.

**3) runQCsummary** *(in development)*: This function creates several plots to visualize the distribution of QC parameters and their impact on the removal of cells and sweeps. If the file naming convention is followed (see [here](#nwb-conversion-standards)), plots are also created for each individual experimenter/rig.

**4) runSummary** *(in development)*: `runSummary` is meant to produce the same output files as `runPipeline`, but using already processed NWB files as input.

## NWB conversion standards

### File name

**SSS_EE_WW_CC** — S: 3 characters for the subject ID; E: 2 characters for the experimenter/rig ID (for example, initials or a number); W: 2 characters for the slice ID, which could be the name of the cell culture well in which the slice was fixed (such as A1); C: 2 characters for the cell ID. This is helpful for histological processing and when there are multiple cells in one slice. However, this information is not used anywhere in the code so far.

### Protocol names and addenda to the intracellular recordings table

Each NWB file based on the 2.4 schema contains, under `general/intracellular_ephys/intracellular_recordings/`, an object called `IntracellularRecordingsTable` (all MATNWB objects mentioned here share the same prefix, so the full name is `types.core.IntracellularRecordingsTable`). It provides an overview of the different electrodes (dual recordings, for example), sweeps, stimuli, responses and so on — see [here](https://neurodatawithoutborders.github.io/matnwb/tutorials/html/icephys.html) for a detailed explanation.

Our standard adds another column to this table, called `protocol_type`, to designate which sweep is a long pulse (label must be `LP`) and which is a short pulse (label must be `SP`). Protocols that match neither of these types must be labelled `unknown` and are ignored during analysis.

In addition, current amplitudes are added in a similar manner under `/stimuli/current_amplitude/`, to give an easy aggregate of the various current steps for the respective square pulse. These values should be in picoamperes, and if they are extracted from the raw current channel they should be rounded to the nearest whole pA value (159.987 pA → 160 pA).

### Test pulse

The use of a test pulse is strongly recommended, but its use has not been explicitly embedded in the NWB schema. Hence the amplitude, duration and voltage response of the test pulse can only be accessed by going through the `data` property of the `CurrentClampStimulusSeries` and `CurrentClampSeries` objects respectively. MATFX aims to detect a single test pulse ahead of the actual stimulus onset of the protocol by examining the raw current data in `CurrentClampStimulusSeries`.

### Metadata

**1)** Metadata associated with an entire run (meaning an individual patch attempt) are saved in the `IntracellularElectrode` object. Without information in the optional property `initial_access_resistance`, the automated QC will not be able to assess the cell properly and may throw errors. Temperature during the recording is saved under the property `slice`, but there is no QC evaluation of temperature.

**2)** Metadata associated with a specific sweep or protocol are saved in the `CurrentClampSeries` object, which is designed specifically for the voltage channel of a current clamp recording. Without information in the following optional properties, the automated QC may not be able to assess the sweep properly and may cause errors: `bias_current` and `bridge_balance`.

&nbsp;&nbsp;**a)** According to NWB convention, `bias_current` is supposed to be reported in amperes, but saving the value in the more practical picoamperes should also work. It is not sufficient to save only the corresponding raw current channel as a `CurrentClampStimulusSeries` object without extracting a baseline value as holding current and saving it in the `CurrentClampSeries`.

&nbsp;&nbsp;**b)** According to NWB convention, `bridge_balance` is supposed to be reported in ohms, but saving the value in the more practical megaohms should also work. Not all recording equipment documents the bridge value automatically. For devices using MultiClamp
