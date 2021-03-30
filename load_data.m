
clear; close all; clc

% Set variables manually here


preSP = 20;                 % first time step pre-stimulus window
postSP = 75;                % last time step pre-stimulus window
preLP = 600;                % first time-step post-stimulus window
postLP = 2000;              % last time-step post-stimulus window
preRAMP1 = 30;
postRAMP1 = 1030;
preNOISE1 = 1000;
postNOISE2 = 2000;
preHALFMILLISEC = 3.5;
postHALFMILLISEC = 104.5 ;
preNANOAMP = 1156;
postNANOAMP = 1159;
plotSweeps = 1;             % set to '0' for no plots
missingCountSP = 1;         % count cells with missing SP data
missingCountRAMP = 1;
missingCountNoise1 = 1;
missingCountHALFMILLISEC = 1;
noise_files = [];
structure_names = ["LP", "SP", "NOISE1", "RAMP1", "HALFMILLISEC", "NANOAMP"];

save_path = 'H:\NHP cell type database\matlab_files\original\';

% GFcount 
% SSPcount
% RampUpcount
% RampNewcount
% 
% Chirpcount

% indicate path of data
 
dataFolder{1} = 'H:\Michael Feyerabend\Ephys files\Data_archive\Final_LP_selection_all_included\';
 
 % generating structure for each cell
 
 for m = 1:length(dataFolder)
    cellList = dir(dataFolder{m}); cellList = cellList(4:end);         % list of cells to analyze
    Norig = length(cellList);   
    for n = 1:Norig
        disp(cellList(n).name)                                              % display cell name
        fileList = dir([dataFolder{m},'\',cellList(n,1).name,'\']);         % could contain various protocol                                                                          %     
        fileList = fileList(3:end);                                         %
        LPcount = 1; SPcount = 1;NOISE1count = 1;RAMP1count =1; ...
            HALFMILLISECcount = 1; NANOAMPcount = 1;
        for k = 1:length(fileList)
            exten = fileList(k,1).name(end-2:end);
            if sum(exten == 'abf')==3
                getSweepsABF
            elseif sum(exten == 'nwb')==3
                getSweepsNWB
            end
            clear exten
          
        end
        if ~isempty(noise_files)
        ABF_NOISE1
        NOISE1.fullStruct = 1;
        noise_files = [];
        end
        clear k fileList
        structures2save = [];
        for v = 1:length(structure_names)
          if exist(structure_names(v))
            structures2save = [structures2save,structure_names(v)];
          end
        end
        if length(structures2save) == 2
        save([save_path,cellList(n,1).name,'.mat'], structures2save(1), structures2save(2))
        elseif length(structures2save) == 3
        save([save_path,cellList(n,1).name,'.mat'], structures2save(1), structures2save(2), ...
           structures2save(3)) 
        elseif length(structures2save) == 4 
        save([save_path,cellList(n,1).name,'.mat'], structures2save(1), structures2save(2), ...
           structures2save(3), structures2save(4))
        elseif length(structures2save) == 5
        save([save_path,cellList(n,1).name,'.mat'], structures2save(1), structures2save(2), ...
           structures2save(3), structures2save(4),structures2save(5))
        elseif length(structures2save) == 6
        save([save_path,cellList(n,1).name,'.mat'], structures2save(1), structures2save(2), ...
           structures2save(3), structures2save(4),structures2save(5), structures2save(6))
        end
        clear LP SP RAMP1 NOISE1 HALFMILLISEC NANOAMP structures2save        
    end
    clear n cellList Norig
end

        
