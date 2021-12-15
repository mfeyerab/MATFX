function module_APP = fillAPP_Mod(module_APP, SpPattrn, version)
   [data_vector, data_index] = util.create_indexed_column(SpPattrn.ISIs, 'path');
   
   if compareVersions({version}, '2.3.0')
       
       ISI_table = types.hdmf_common.DynamicTable(...
            'colnames', 'ISIs',...
            'description', 'ISI table',...
            'id', types.hdmf_common.ElementIdentifiers('data', ...
                                   [0:length(data_vector.data)]) ,...
            'ISIs', types.hdmf_common.VectorData(...
                                    'data', data_vector.data,...
                                    'description', 'Interspike Intervals'...
                                ),...
            'ISIs_index', types.hdmf_common.VectorIndex(...
                                    'data', data_index.data,...
                                    'target', types.untyped.ObjectView(...
                                      '/processing/AP Pattern/ISIs/'), ...
                            'description', 'Index indicating sweep of ISI'));  

   else
      
      ISI_table = types.hdmf_common.DynamicTable(...
                    'colnames', 'ISIs',...
                    'description', 'ISI table',...
                    'id', types.hdmf_common.ElementIdentifiers('data', ...
                                           [0:length(data_vector.data)]) ,...
                    'ISIs', types.hdmf_common.VectorData(...
                                            'data', data_vector.data,...
                                            'description', 'Interspike Intervals'...
                                        ),...
                    'ISIs_index', types.hdmf_common.VectorIndex(...
                                            'data', data_index.data,...
                                            'target', types.untyped.ObjectView(...
                                              '/processing/AP Pattern/ISIs/'))); 
   end
                                          
   module_APP.dynamictable.set('ISIs', ISI_table);  
   
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