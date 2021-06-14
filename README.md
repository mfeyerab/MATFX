# MATFX

requieres curve fitting and statistics_toolbox

runPipeline is the main script, which produces analysis tables as well as appended NWB files. The new files contain the additional processing data like interspike intervals, QC parameters (RMSE, etc.) as well as binaries that encode pass or fail of the respective sweep in regard of QC, that can be found in the sweeptable.

runSummary produces the same summary output files, but requires already processed NWB files.
