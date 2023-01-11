 %% save SpikeQC in ragged array    
 %still missing     
 %% Save QC results in Sweeptable and external   
 QC.pass.bad_spikes(isnan(QC.pass.bad_spikes)) = 1;                        % replace nans with 1s for pass in the bad spike column these are from sweeps without sweeps
 QC.pass.manuTP(isnan(QC.pass.manuTP)) = 1;                                % replace nans with 1s for pass in the bad spike column these are from sweeps without sweeps
 tbl = util.table2nwb(QC.params, 'QC parameter table');                    % convert QC parameter to DynamicTable
 modQC.dynamictable.set('QC_parameter_table', tbl);                        % add DynamicTable to QC processing module
 nwb.processing.set('QC parameter', modQC);                                % add QC processing module to nwb object
 keys = ICEtab.dynamictable.map('quality_control_pass').vectordata.keys;   % Get columns of quality control section of IntracellularRecordingTable
   
for s = 1:height(QC.pass)                                                  % loop through sweeps/rows of QC pass table
   if  sum(isnan(QC.pass{s,4:15})) == 0 && sum(QC.pass{s,4:15}) == 12      % Condition 1: QC pass columns do not contain NaN. Condition 2: All columns have to contain 1
          QC.pass(s,3) = {1};
      elseif sum(isnan(QC.pass{s,4:15})) > 3                               % If row contains more than 3 NaNs the sweep is not QC-able and the total pass parameter should be NaN as well
          QC.pass(s,3) = {NaN};
      else
         QC.pass(s,3) = {0};                                               % sweep has not passed the total QC
   end
end

QC.pass.QC_total_pass(QC.pass.manuTP == 0) = 0;                            % replace nans for total evaulation with fails if it was failed by manual TP review 
QC.pass.QC_total_pass(isnan(QC.pass.QC_total_pass))=0;

for t = 1:length(keys)                                                     % loop through columns of QC pass
    if any(contains(fieldnames(QC.pass),keys(t)))
       ICEtab.dynamictable.values{2}.vectordata.values{t}.data = ...
           QC.pass.(char(keys(t)))';   
    end
end

totalSweeps = height(QC.pass)-sum(isnan(QC.pass.QC_total_pass));           % calculates the number of sweeps being considered during the analysis
QC_removalsPerTag(n,1) = {totalSweeps};                                    % adding total number of sweeps to the removals-per-tag table
QC_removalsPerTag(n,2) = {sum(rmmissing(QC.pass{:,3}))};                   % adding the number of passed sweeps to the removals-per-tag table
QC_removalsPerTag(n,3:end) = array2table(abs(sum(...
                   rmmissing(QC.pass{:,4:14}),1)-totalSweeps));            % adding the number of failed sweeps per QC criterium to the removals-per-tag table
QC.pass(isnan(QC.pass.QC_total_pass),13:14)={NaN};
if contains(PS.cellID, ".")
   PS.cellID = extractBefore(PS.cellID,".");
end
writetable(QC.pass,[PS.outDest, '\QC\', PS.cellID,'_QCpass_',date,'.csv']);  
writetable(QC.params,[...
                   PS.outDest, '\QC\',PS.cellID,'_QCvalues_',date,'.csv']);  

%% save all sweep processing in NWB file

modAPP = fillAPP_Mod(modAPP,SpPattrn);                                     % make AP pattern processing module  
nwb.processing.set('AP Pattern', modAPP);                                  % add AP pattern processing module to nwb obejct
nwb.processing.set('subthreshold parameters', modSubStats);                % add subthreshold parameters processing module to nwb obejct 
nwb.processing.set('AP wave', modSpikes);                                  % add AP wave from processing module to nwb obejct