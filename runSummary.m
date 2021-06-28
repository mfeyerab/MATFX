
clear

start = 1;
mainFolder = 'D:\output_ressource\QC\';            % main folder (EDIT HERE)
cellList = dir([mainFolder,'*.nwb']);  
params = loadParams;                                                       % load parameters to workspace
ICsummary = initICSummary(cellList); 

for n = start:length(cellList)                                             % for all cells in directory
    cellID = cellList(n).name(1:length(cellList(n).name)-4);               % cell ID (used for saving data)
    disp(cellID)                                                           % display ID number
    cellFile = nwbRead([mainFolder,cellList(n).name]); 
   
    Ri_preqc = inputResistance(cellFile.processing.values{6}.dynamictable);
    
    %%Feature Extraction and summary
    
    if  ~isempty(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) && ...
           (string(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ~= "NaN" && ...
               string(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ~= ...
                   "has to be entered manually")
      
       if str2double(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ...
                 <= params.cutoffInitRa && ...
          str2double(cellFile.general_intracellular_ephys.values{1}.('initial_access_resistance')) ...
                 <= Ri_preqc*params.factorRelaRa
       
       [cellFile, ICsummary, PlotStruct] = ...
                            LPsummary(cellFile, ICsummary, n, params);
       plotCellProfile(cellFile, PlotStruct, mainFolder, params)
       %SP_summary
       else
           display(['         was excluded by cell-wide QC']);
      end              
   else
       [cellFile, ICsummary, PlotStruct] = ...
                            LPsummary(cellFile, ICsummary, n, params);
       plotCellProfile(cellFile, PlotStruct, mainFolder, params)
       %SP_summary

    end    
   
  %% Add dendritic type and reporter    
    ICsummary.dendriticType(n) = ...
       {cellFile.processing.values{4}.dynamictable.values{1}.vectordata.values{1}.data.load};
    ICsummary.SomaLayerLoc(n) = ...
       {cellFile.processing.values{4}.dynamictable.values{1}.vectordata.values{2}.data.load};
    
    if string(cellFile.general_subject.species) == "Mus musculus" && ...
        string(cellFile.processing.values{4}.dynamictable.values{1}.vectordata.values{3}.data.load) == "positive"
   
       ICsummary.ReporterTag(n) = {cellFile.general_subject.genotype};
    else
       ICsummary.ReporterTag(n) = {'None'} ;
    end
end

