function AquiIdx = getAquisitionIndex(cellFile, sweepNr)
 AquiIdx = find(...
      cellFile.general_intracellular_ephys_sweep_table.sweep_number.data.load== ...
                sweepNr);    
  AllPaths = {cellFile.general_intracellular_ephys_sweep_table.series.data.path};          
 
  AquiIdx = AquiIdx(contains({AllPaths{AquiIdx}}, 'acquisition'));               