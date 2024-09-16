%% load paramter structure and start using it as workspace structure
run(fullfile(path, 'loadParams.m')); PS = ans; PS.outDest = path; 
%% Initalize folder structure and loop
cellList = dir([path,'\','*.nwb']);                                  % list of cell data files
cellList = cellList(~[cellList.isdir]);

if ~exist(fullfile(PS.outDest, '\peristim'), 'dir')
    mkdir(fullfile(PS.outDest, '\peristim'))
    mkdir(fullfile(PS.outDest, '\IU'))
    mkdir(fullfile(PS.outDest, '\profiles'))
    mkdir(fullfile(PS.outDest, '\firingPattern'))
    mkdir(fullfile(PS.outDest, '\QC'))
    mkdir(fullfile(PS.outDest, '\traces'))
    mkdir(fullfile(PS.outDest, '\betweenSweeps'))
    mkdir(fullfile(PS.outDest, '\AP_Waveforms'))
    mkdir(fullfile(PS.outDest, '\tauFit'))  
    mkdir(fullfile(PS.outDest, '\TP')) 
    mkdir(fullfile(PS.outDest, '\Noise')) 
    mkdir(fullfile(PS.outDest, '\peristim\failedCells'))
    mkdir(fullfile(PS.outDest, '\IU\failedCells'))
    mkdir(fullfile(PS.outDest, '\profiles\failedCells'))
    mkdir(fullfile(PS.outDest, '\firingPattern\failedCells'))
    mkdir(fullfile(PS.outDest, '\QC\failedCells'))
    mkdir(fullfile(PS.outDest, '\traces\failedCells'))
    mkdir(fullfile(PS.outDest, '\betweenSweeps\failedCells'))
    mkdir(fullfile(PS.outDest, '\AP_Waveforms\failedCells'))
    mkdir(fullfile(PS.outDest, '\tauFit\failedCells'))  
    mkdir(fullfile(PS.outDest, '\TP\failedCells')) 

end
%% Initialize feature and QC summary tables
icSum = initICSummary(cellList); 
MetaVarStart = find(contains(icSum.Properties.VariableNames,'Temperature'));
NoiseSum = icSum(:,MetaVarStart:end);

qc_tags = {'SweepsTotal' 'QC_total_pass' 'stRMSE_pre' 'stRMSE_post' ...
        'ltRMSE_pre' 'ltRMSE_post' 'diffVrest' 'Vrest'  'holdingI' ...
        'betweenSweep' 'bridge_balance'};
     
QC_removalsPerTag = array2table(NaN(length(cellList),length(qc_tags)), ...
    'VariableNames', qc_tags,'RowNames', {cellList.name});

QCcellWise = table();                                
LPfilt = lowPassFilt;

