MATFX
======

Additional Requirements:
-------
-MATLAB toolboxes:  curve fitting and statistics

-MATNWB repository: Code has been written for Release v2.3.0.1, you find it [here](https://github.com/NeurodataWithoutBorders/matnwb)

-export_fig:  you find it [here](https://www.mathworks.com/matlabcentral/fileexchange/23629-export_fig)

Functionality
-------
-runPipeline is the main script, which produces analysis tables as well as appended NWB files. The new files contain the additional processing data like interspike intervals, QC parameters (RMSE, etc.) as well as binaries that encode pass or fail of the respective sweep in regard of QC, that can be found in the sweeptable.

-runSummary produces the same summary output files, but requires already processed NWB files.

-oldAIBSfiles2NWB is a script to transcribe outdated NWB 1.0 files from the first release of the cell type data base of Allen Insitute for Brain Science into a format that can be processed with runPipeline.
