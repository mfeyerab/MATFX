if PS.manTPremoval
   assert(height(QC.pass.manuTP)==height(TPtab.TP),...
    'Number of sweeps between test pulse table and nwb file do not match')
   QC.pass.manuTP = TPtab.TP;                                              % assign binary from results of test pulse review to QC pass table
 end



