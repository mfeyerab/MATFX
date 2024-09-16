prndRow = [];                                                        % initialize variable to prune rows
for r = 1:height(LPexport)                                    % loop through rows of the table
 if sum(LPexport{r,3}) == 0                                % if the sweep is zero 
   prndRow = [prndRow; r];                                     % save values in variables
 end
end
LPexport(prndRow,:) = [];                                     % pruning empty sweeps
writetable(LPexport, fullfile(PS.outDest, '\traces\', [nwb.identifier, '.csv'])) % export table of raw sweep data as csv