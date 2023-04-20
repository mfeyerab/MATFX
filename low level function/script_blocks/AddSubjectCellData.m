  %% Add subject data, dendritic type and reporter status   
  AnaDat = nwb.processing.values{3}.dynamictable.values{1}.vectordata;
   if string(nwb.general_institution) == "Allen Institute of Brain Science"% if the cell is from the AIBS 
      icSum.brainOrigin(n) = {info.values{...
        1}.location(1:find(info.values{...
           1}.location==',')-1)};                                          % assign part of the description of as brain area to summary table 
    %% Subject data and reporter line 
      icSum.Species(n) = {nwb.general_subject.species};
      if string(nwb.processing.map('Anatomical data').dynamictable.values{...
               1}.vectordata.values{3}.data.load) == "positive" && ...
                string(nwb.general_subject.species)== "Mus musculus" 

         icSum.ReporterTag(n) = {nwb.general_subject.genotype};        % assigning genotype to summary table  
      else

         icSum.ReporterTag(n) = {'None'} ;
      end 
   else %% Not AIBS
      if isa(info.values{1}.location,'char')
          icSum.brainOrigin(n) = {info.values{1}.location};                % assign brain area to summary table          
          icSum.Species(n) = {nwb.general_subject.species};                % assign species to summary table   
          if ~isempty(nwb.general_subject.weight)
           icSum.Weight(n) = {str2num(nwb.general_subject.weight)};           % assign weight to summary table    
          end
          if ~isempty(nwb.general_subject.sex)
           icSum.Sex(n) = {nwb.general_subject.sex};                     % assign sex to summary table 
          end
          if ~isempty(nwb.general_subject.age)
            icSum.Age(n) = {str2num(nwb.general_subject.age)};                 % assign weight to summary table    
          end
      else
          icSum.brainOrigin(n) = {info.values{1}.location.load};                % assign brain area to summary table          
          icSum.Species(n) = {nwb.general_subject.species.load};                % assign species to summary table   
          if ~isempty(nwb.general_subject.weight)
           icSum.Weight(n) = {str2num(nwb.general_subject.weight)};           % assign weight to summary table    
          end
          if ~isempty(nwb.general_subject.sex.load)
           icSum.Sex(n) = {nwb.general_subject.sex.load};                     % assign sex to summary table 
          end
          if ~isempty(nwb.general_subject.age)
            icSum.Age(n) = {str2num(nwb.general_subject.age)};                 % assign weight to summary table    
          end
      end
   end  

   if ~isempty(info.values{1}.slice)                                       % if there is information on brain slice of experiment
        temperature = regexp(info.values{...
                                  1}.slice, '(\d+,)*\d+(\.\d*)?', 'match');% extracting values for temperature
        if isempty(temperature)                                            % if there is no temperature values
           icSum.Temperature(n) = NaN;
        else
            icSum.Temperature(n) = str2double(cell2mat(temperature));  % assign temperature values to summary table
        end
   end
    %% Dendritic Type
   if nwb.processing.isKey('Anatomical data') && ~isempty(...              
           nwb.processing.values{3}.dynamictable.values{...                % if there is an anatomical data processing module
                        1}.vectordata.values{1}.data)                      % and there is data on dendritic type of the cell
                    
         icSum.dendriticType(n) = {AnaDat.map('DendriticType').data.load}; % assigning dendritic type to summary table
          icSum.SomaLayerLoc(n) = {AnaDat.map('SomaLayerLoc').data.load};  % assigning soma layer location to summary table
        if any(contains(AnaDat.keys,'PyrID')) && ...
                ~contains(AnaDat.map('PyrID').data.load,'NA') && ...
                  ~isempty(AnaDat.map('PyrID').data.load) 
          icSum.PyrID(n) = str2num(AnaDat.map('PyrID').data.load);
        else
          icSum.PyrID(n) = NaN;    
        end
      else
       [icSum.dendriticType(n),icSum.SomaLayerLoc(n)] = ...
           deal({'NA'});                                                   % NA for soma layer location and dendritic type of cells without entries 
   end  