function module_spTrain = makeSpTrainModule(spTrain, spTrainIDs)
   module_spTrain = types.core.ProcessingModule(...
                         'description', 'Table with AP pattern parameter',...
                         'dynamictable', []  ...
                               );                               
   table = array2table(cell2mat(struct2cell(spTrain)'));
   if ~isempty(table)

       removals = find(cellfun(@isempty, spTrainIDs));
       table([removals],:) = [];     
       spTrainIDs(removals) = [];
   else
       table(1,:) = num2cell(NaN(1,15));
       spTrainIDs = NaN;
   end    
   table.Properties.VariableNames = { ...
                     'meanFR50','meanFR100','meanFR250', ...
                     'meanFR500','meanFR750', 'meanFR1000',...
                     'latency','peakAdapt', 'meanISI','cvISI',...
                     'adaptIndex', 'adaptIndex2','peakAdapt2',...
                     'delay','burst'};
   if isa(spTrainIDs, 'double') && isnan(spTrainIDs)
       table.SweepIDs = spTrainIDs;
   else
       table.SweepIDs = str2double(...
          cellfun(@cell2mat,(regexp(spTrainIDs,'\d*','Match')),'UniformOutput',false));
   end
   
   DynTbl = table2nwb(table, 'AP Pattern results');
   module_spTrain.dynamictable.set('AP Pattern results', DynTbl);  
end