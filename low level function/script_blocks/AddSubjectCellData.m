  %% Add subject data, dendritic type and reporter status   
  
  if nwb.processing.Count > 0
  AnaDat = nwb.processing.Map('misc').dynamictable.values{1}.vectordata;
   if string(nwb.general_institution) == "Allen Institute of Brain Science"% if the cell is from the AIBS 
      icSum.brainOrigin(n) = {info.values{...
        1}.location(1:find(info.values{...
           1}.location==',')-1)};                                          % assign part of the description of as brain area to summary table 
    %% Subject data and reporter line 
      icSum.Species(n) = {nwb.general_subject.species};
      if string(nwb.processing.Map('Anatomical data').dynamictable.values{...
               1}.vectordata.values{3}.data.load) == "positive" && ...
                string(nwb.general_subject.species)== "Mus musculus" 

         icSum.ReporterTag(n) = {nwb.general_subject.genotype};        % assigning genotype to summary table  
      else

         icSum.ReporterTag(n) = {'None'} ;
      end 
   else %% Not AIBS
      if isa(info.values{1}.location,'char')
          icSum.brainOrigin(n) = {info.values{1}.location};                % assign brain area to summary table              
      else
          icSum.brainOrigin(n) = {info.values{1}.location.load};           
      end

      icSum.iRa(n) = str2double(info.values{1}.initial_access_resistance);

      if isa(nwb.general_subject.species,'char')                           % assign species to summary table 
         icSum.Species(n) = {nwb.general_subject.species};  
      else
         icSum.Species(n) = {nwb.general_subject.species.load};   
      end

      if isa(nwb.general_subject.weight,'char')                  % assign weight to summary table        
         icSum.Weight(n) = {str2num(nwb.general_subject.weight)};
      elseif ~isempty(nwb.general_subject.weight)         
         icSum.Weight(n) = {str2num(nwb.general_subject.weight.load)};     
      end
                          
      if isa(nwb.general_subject.sex,'char')                                % assign sex to summary table 
         icSum.Sex(n) = {nwb.general_subject.sex};
      elseif ~isempty(nwb.general_subject.sex)
         icSum.Sex(n) = {nwb.general_subject.sex.load};
      end
      
      if  isa(nwb.general_subject.age,'char')                                 % assign age to summary table 
         icSum.Age(n) = {str2num(nwb.general_subject.age)};     
      elseif  ~isempty(nwb.general_subject.age)   
         icSum.Age(n) = {str2num(nwb.general_subject.age.load)};      
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
   if ~isempty(AnaDat.Map('DendriticType'))                                % and there is data on dendritic type of the cell
                    
         icSum.dendriticType(n) = {AnaDat.Map('DendriticType').data.load}; % assigning dendritic type to summary table
         icSum.SomaLayerLoc(n) = {AnaDat.Map('SomaLayerLoc').data.load};   % assigning soma layer location to summary table
        if any(contains(AnaDat.keys,'PyrID')) && ...
                ~contains(AnaDat.Map('PyrID').data.load,'NA') && ...
                  ~isempty(AnaDat.Map('PyrID').data.load) 
          icSum.PyrID(n) = str2num(AnaDat.Map('PyrID').data.load);
        else
          icSum.PyrID(n) = NaN;    
        end
      else
       [icSum.dendriticType(n),icSum.SomaLayerLoc(n)] = ...
           deal({'NA'});                                                   % NA for soma layer location and dendritic type of cells without entries 
   end  
  end