QC = types.core.ProcessingModule(...
    'description', 'holds data from sweep QC');
QC.nwbdatainterface.set('data', VPs);
nwb.processing.set('VPs', QC);

QC = types.core.ProcessingModule(...
    'description', 'holds data from sweep QC');
QC.nwbdatainterface.set('data', ltRMSE);
nwb.processing.set('ltRMSE', QC);

QC = types.core.ProcessingModule(...
    'description', 'holds data from sweep QC');
QC.nwbdatainterface.set('data', stRMSE);
nwb.processing.set('stRMSE', QC);