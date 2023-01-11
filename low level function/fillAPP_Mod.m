function module_APP = fillAPP_Mod(module_APP, SpPattrn)
   [ISIs_data_vector, ISIs_data_index] = util.create_indexed_column(SpPattrn.ISIs, 'path');
   [SpTis_data_vector, SpTis_data_index] = util.create_indexed_column(SpPattrn.SpTimes, 'path');
      
   ISI_table = types.hdmf_common.DynamicTable(...
                    'colnames', 'ISIs',...
                    'description', ...
                    'Table with all inter spike intervalls per sweep',...
                    'id', types.hdmf_common.ElementIdentifiers('data', ...
                                           0:length(ISIs_data_vector.data)) ,...
                    'ISIs', types.hdmf_common.VectorData(...
                                            'data', ISIs_data_vector.data,...
                                            'description', 'Interspike Intervals'...
                                        ),...
                    'ISIs_index', types.hdmf_common.VectorIndex(...
                                            'data', ISIs_data_index.data,...
                                            'target', types.untyped.ObjectView(...
                                              '/processing/AP Pattern/ISIs/'))); 

   SpTi_table = types.hdmf_common.DynamicTable(...
                    'colnames', 'SpikeTimes',...
                    'description', 'Table with all spike times (at threshold) per sweep',...
                    'id', types.hdmf_common.ElementIdentifiers('data', ...
                                           0:length(SpTis_data_vector.data)) ,...
                    'time', types.hdmf_common.VectorData(...
                                            'data', SpTis_data_vector.data,...
                                            'description', 'spike times in milliseconds'...
                                        ),...
                    'time_index', types.hdmf_common.VectorIndex(...
                                            'data', SpTis_data_index.data,...
                                            'target', types.untyped.ObjectView(...
                                              '/processing/AP Pattern/SpikeTimes/'))); 
                                          
   module_APP.dynamictable.set('ISIs', ISI_table);  
   module_APP.dynamictable.set('SpikeTimes', SpTi_table);  

   
   T = array2table(SpPattrn.BinTbl);
   T.Properties.VariableNames = {...
     'B1','B2','B3','B4','B5','B6','B7','B8','B9','B10','B11','B12','B13'};
   T.Properties.RowNames = SpPattrn.RowNames;
   BinnedSpCountsTbl =  util.table2nwb(T, 'Binned Spike Counts');
   module_APP.dynamictable.set('Binned Spike Counts', BinnedSpCountsTbl); 
                             
   T = array2table(cell2mat(struct2cell(SpPattrn.spTrain)'));
   if ~isempty(T)

       removals = find(cellfun(@isempty, SpPattrn.spTrainIDs));
       T([removals],:) = [];     
       SpPattrn.spTrainIDs(removals) = [];
   else
       T(1,:) = num2cell(NaN(1,11));
       SpPattrn.spTrainIDs = NaN;
   end    
   T.Properties.VariableNames = {
                     'firRt', 'lat','peakAdapt', 'meanISI','cvISI',...
                     'adaptIdx', 'adaptIdx2','peakAdapt2',...
                     'delay','burst', 'lastQuisc'};
   if isa(SpPattrn.spTrainIDs, 'double') && isnan(SpPattrn.spTrainIDs)
       T.SwpID = SpPattrn.spTrainIDs;
   else
       T.SwpID = cellfun(@(v)v(1),...
          regexp(SpPattrn.spTrainIDs,'\d*','Match'));
   end
   
   DynTbl = util.table2nwb(T, 'AP Pattern results');
   module_APP.dynamictable.set('AP Pattern parameter', DynTbl);  
end