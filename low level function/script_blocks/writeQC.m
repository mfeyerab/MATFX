QC = types.core.ProcessingModule(...
    'description', 'holds data from sweep QC');
QC.nwbdatainterface.set('data', VPs);
cellFile.processing.set('VPs', QC);

QC = types.core.ProcessingModule(...
    'description', 'holds data from sweep QC');
QC.nwbdatainterface.set('data', ltRMSE);
cellFile.processing.set('ltRMSE', QC);

% QC = types.core.ProcessingModule(...
%     'description', 'holds data from sweep QC');
% QC.nwbdatainterface.set('data', stRMSE);
% cellFile.processing.set('stRMSE', QC);