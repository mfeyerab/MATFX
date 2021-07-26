function ICsummary = appendAnalysis(varargin) 

if length(varargin) == 1 
    folderpath = char(varargin);
end

if length(varargin) == 2
    for f = 1:2
       if any(size(dir(fullfile(varargin{f}, '*.csv' )),1))
           csvList = dir(fullfile(varargin{f}, '*.csv' ));
           for t = 1:length(csvList)
               if  contains(csvList(t).name, 'ephys_features')
                   tablepath =  csvList(t).name;
               end
           end
       end
    end
   
    
    
end