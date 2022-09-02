%% load paramter structure and start using it as workspace structure
PS = loadParams; PS.outDest = outDest; 
%% Initalize folder structure and loop
cellList = dir([mainFolder,'\','*.nwb']);                                  % list of cell data files
cellList = cellList(~[cellList.isdir]);

if ~exist(fullfile(PS.outDest, '\peristim'), 'dir')
    mkdir(fullfile(PS.outDest, '\peristim'))
    mkdir(fullfile(PS.outDest, '\resistance'))
    mkdir(fullfile(PS.outDest, '\profiles'))
    mkdir(fullfile(PS.outDest, '\firingPattern'))
    mkdir(fullfile(PS.outDest, '\QC'))
    mkdir(fullfile(PS.outDest, '\traces'))
    mkdir(fullfile(PS.outDest, '\betweenSweeps'))
    mkdir(fullfile(PS.outDest, '\AP_Waveforms'))
    mkdir(fullfile(PS.outDest, '\tauFit'))  
    mkdir(fullfile(PS.outDest, '\TP')) 
end
%% Initialize feature and QC summary tables
ICsummary = initICSummary(cellList); 

qc_tags = {'SweepsTotal' 'QC_total_pass' 'stRMSE_pre' 'stRMSE_post' ...
        'ltRMSE_pre' 'ltRMSE_post' 'diffVrest' ...
        'Vrest'  'holdingI' 'betweenSweep' ...
        'bridge_balance_abs' 'bridge_balance_rela' 'bad_spikes' ...
         };
     
QC_removalsPerTag = array2table(NaN(length(cellList),length(qc_tags)), ...
    'VariableNames', qc_tags,'RowNames', {cellList.name});

QCcellWise = table();                                
LPfilt = lowPassFilt;