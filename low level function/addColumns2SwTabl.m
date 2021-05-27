function cellFile  = addColumns2SwTabl(cellFile,qc_tags)
new_sweep_table_descriptions = {...
         'Binary for total QC evaluation of sweep; pass = 1, fail=0'
         'Binary for short-term root mean sqaure evaluation of prestimulus interval; pass = 1, fail=0'
         'Binary for short-term root mean sqaure evaluation of poststimulus interval; pass = 1, fail=0'
         'Binary for long-term root mean sqaure evaluation of prestimulus interval; pass = 1, fail=0'
         'Binary for long-term root mean sqaure evaluation of poststimulus interval; pass = 1, fail=0'
         'Binary for QC evaluation of voltage difference between pre and post stimulus intervall; pass = 1, fail=0'
         'Binary for QC evaluation of prestimulus membrane potential; pass = 1, fail=0'
         'Binary for QC evaluation of absolute bridge balance value; pass = 1, fail=0'
         'Binary for QC evaluation of relative bridge balance value; pass = 1, fail=0'
         'Binary for QC evaluation of holding current value; pass = 1, fail=0'
         'Binary for QC evaluation of across sweep variability (i.e. drift) of the prestimulus membrane potential; pass = 1, fail=0'
         'Binary for QC evaluation of sweeps with bad spike wave forms; pass = 1, fail=0'
         };
     
    for t = 2:length(qc_tags)
        cellFile.general_intracellular_ephys_sweep_table.colnames{t+1} = ...
            qc_tags{t};
        cellFile.general_intracellular_ephys_sweep_table.vectordata.map(qc_tags{t}) = ...
          types.hdmf_common.VectorData(...
           'description', new_sweep_table_descriptions{t-1},...
           'data', zeros(...
              cellFile.general_intracellular_ephys_sweep_table.sweep_number.data.dims,1)...
              );   
    end
    
   if ~cellFile.general_intracellular_ephys_sweep_table.vectordata.isKey('SweepAmp')
      cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
        'SweepAmp') = ...
          types.hdmf_common.VectorData(...
           'description', 'amplitdue of the current step injected (if square pulse)',...
           'data', zeros(...
              cellFile.general_intracellular_ephys_sweep_table.sweep_number.data.dims,1)...
              ); 
          
              cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
        'StimOn') = ...
          types.hdmf_common.VectorData(...
           'description', 'Index of stimulus onset',...
           'data', zeros(...
              cellFile.general_intracellular_ephys_sweep_table.sweep_number.data.dims,1)...
              );   
              
              cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
        'StimOff') = ...
          types.hdmf_common.VectorData(...
           'description', 'Index of end of stimulus',...
           'data', zeros(...
              cellFile.general_intracellular_ephys_sweep_table.sweep_number.data.dims,1)...
              );   
    end
end