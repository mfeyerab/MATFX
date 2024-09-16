   
  if PS.manTPremoval && ...                                                % if manual removal due to test pulse is enabled
              exist(fullfile(path, 'inputTabsTP', [PS.cellID,'_TP.csv']))     % if table with results of manual test pulse review exists
          
    TPtab = readtable(fullfile(path, 'inputTabsTP', [PS.cellID,'_TP.csv']));  % read table with results of manual test pulse review
  elseif PS.manTPremoval
      error('No result file for manual test pulse review')
  end
