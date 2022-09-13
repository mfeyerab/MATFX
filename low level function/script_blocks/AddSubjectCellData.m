  %% Add subject data, dendritic type and reporter status   
   if string(nwb.general_institution) == "Allen Institute of Brain Science"% if the cell is from the AIBS 
      ICsummary.brainOrigin(n) = {info.values{...
        1}.location(1:find(info.values{...
           1}.location==',')-1)};                                          % assign part of the description of as brain area to summary table 
   else
      ICsummary.brainOrigin(n) = {info.values{1}.location};                % assign brain area to summary table          
      ICsummary.Species(n) = {nwb.general_subject.species};                % assign species to summary table   
      if ~isempty(nwb.general_subject.weight)
        ICsummary.Weight(n) = {str2num(nwb.general_subject.weight)};       % assign weight to summary table    
      end
      if ~isempty(nwb.general_subject.sex)
        ICsummary.Sex(n) = {nwb.general_subject.sex};                      % assign sex to summary table 
      end
      if ~isempty(nwb.general_subject.age)
        ICsummary.Age(n) = {str2num(nwb.general_subject.age)};             % assign weight to summary table    
      end
      if nwb.processing.isKey('Anatomical data') && ~isempty(...              
           nwb.processing.values{3}.dynamictable.values{...                % if there is an anatomical data processing module
                        1}.vectordata.values{1}.data)                      % and there is data on dendritic type of the cell
                    
         ICsummary.dendriticType(n) = ...
       {nwb.processing.values{3}.dynamictable.values{1}.vectordata.map(...
               'DendriticType').data.load};                                % assigning dendritic type to summary table
          ICsummary.SomaLayerLoc(n) = ...
       {nwb.processing.values{3}.dynamictable.values{1}.vectordata.map(...
               'SomaLayerLoc').data.load};                                 % assigning soma layer location to summary table
      else
       [ICsummary.dendriticType(n),ICsummary.SomaLayerLoc(n)] = ...
           deal({'NA'});                                                   % NA for soma layer location and dendritic type of cells without entries 
      end
   end  
   if nwb.general.Count ~= 0                                               % if  
       ICsummary.Weight(n) = {nwb.general_subject.weight};
       ICsummary.Sex(n) = {nwb.general_subject.sex};
       ICsummary.Age(n) = {nwb.general_subject.age};  
       ICsummary.species(n) = {nwb.general_subject.species};
   end 
   if ~isempty(info.values{1}.slice)                                       % if there is information on brain slice of experiment
        temperature = regexp(info.values{...
                                  1}.slice, '(\d+,)*\d+(\.\d*)?', 'match');% extracting values for temperature
        if isempty(temperature)                                            % if there is no temperature values
           ICsummary.Temperature(n) = NaN;
        else
            ICsummary.Temperature(n) = str2double(cell2mat(temperature));  % assign temperature values to summary table
        end
   end
    
   if nwb.general.Count ~= 0 && ...
           string(nwb.general_subject.species)== "Mus musculus" 
       if string(cellFile.processing.values{4}.dynamictable.values{1 ...
                           }.vectordata.values{3}.data.load) == "positive"
         ICsummary.ReporterTag(n) = {nwb.general_subject.genotype};        % assigning genotype to summary table  
       else
         ICsummary.ReporterTag(n) = {'None'} ;
       end
   end       