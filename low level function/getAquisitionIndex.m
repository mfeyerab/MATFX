function [AquiIdx, SwTabIdxAll] = getAquisitionIndex(cellFile, sweepNr)
 SwTabIdxAll = find(...
      cellFile.general_intracellular_ephys_sweep_table.sweep_number.data.load== ...
                sweepNr);    
  AllPaths = {cellFile.general_intracellular_ephys_sweep_table.series.data.path};          
 
  AquiIdx = deal(SwTabIdxAll(contains({AllPaths{SwTabIdxAll}}, 'acquisition')));     
  
  if length(SwTabIdxAll)> 2   % multiple electrode recording
    AquiIdx = AquiIdx(2);
  end   