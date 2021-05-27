    module_spikes = types.core.ProcessingModule(...
             'description','AP processing',...
             'dynamictable', []  ...
                   );
               
    module_subStats = types.core.ProcessingModule(...
         'description', 'subthreshold parameters',...
         'dynamictable', []  ...
               );
           
    module_ISIs = types.core.ProcessingModule(...
                         'description', 'Table with ISIs per sweep',...
                         'dynamictable', []  ...
                               );    
    module_QC = types.core.ProcessingModule(...
                         'description', 'Table with QC parameter',...
                         'dynamictable', []  ...
                               );     