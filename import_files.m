{
intracellular experiment pipeline
requieres export_fig function
%}

% Matlab startup commands
clear; close all; clc;      % clear your workspace, close figs, clear command window

start = 99;


preSP = 100;                 % first time step pre-stimulus window
postSP = 300;              % last time step pre-stimulus window
preLP = 500;                % first time-step post-stimulus window
postLP = 6000;              % last time-step post-stimulus window
preNONAIBS = 200;           % first time step pre-stimulus window
plotSweeps = 1;             % set to '0' for no plots
missingCountLP = 1;         % count cells with missing LP data
missingCountSP = 1;         % count cells with missing SP data

% enter folder where data resides (each cell needs a folder)
%dataFolder{1} = 'D:\conversion';
dataFolder{1} = 'C:\Users\mjimenez\Downloads\results\results';

% enter path where files and raw data figures should be saved to 
save_path = 'D:\genpath\';

% Initialize
structure_names = ["gapfree", "LP", "SP", "NONAIBS"];

%% generate structures for each cell
for m = 1:length(dataFolder)                                               % folders denoting dataset
    cellList = getNWBfiles(dataFolder{m});                                        % list of cells to analyze with custom dir(), since dir returns some unwanted elements
    Norig = length(cellList);                                              % number of cells in the dataset
    for n = start:Norig                                                        % for each cell
      disp(cellList(n).name)                                             % display cell name
      LPcount = 1; SPcount = 1; GFREEcount = 1; NONAIBScount = 1;        % initialize sweep counters
      getSweepsNWB                                                       % actual import script
      cellList(n).name = cellList(n).name(1:end-4);       
%% checking which structures are present  
   structures2save = [];
   for v = 1:length(structure_names)
     if exist(structure_names(v))
       structures2save = [structures2save,structure_names(v)];
     end
   end                  
%% Plotting sweeps and saving generated structures as .m files        
        if exist('LP') && exist('SP')
            if plotSweeps == 1
                figure('Position',[50 50 800 800]); set(gcf,'color','w');
                if LP.fullStruct == 1
                    for swp = 1:size(LP.V,2)
                        subplot(2,2,1); hold on; plot(LP.V{1,swp},'k','linewidth',0.25);...
                            axis tight; xlabel('ms'); ylabel('mV')
                    end
                    increment = 0.4;
                    subplot(2,2,3);hold on;
                    for i = 1:2:length(LP.testpulse)
                      if ~isempty(LP.testpulse{1,i})
                        plot(LP.testpulse{i}(1,1:2000)...
                          -mean(LP.testpulse{i}(1,1:500))+i*increment,... 
                      'k','linewidth',0.1); axis tight; xlabel('time'); ylabel('delta mV')
                      end
                    end
                else
                    disp(' stim info missing LP')
                    missingListLP{missingCountLP} = cellList(n).name;
                    missingCountLP = missingCountLP + 1;
                end
                if SP.fullStruct == 1
                    for swp = 1:size(SP.V,2)
                        subplot(2,2,2); hold on; plot(SP.V{1,swp},'k','linewidth',0.25); ...
                            axis tight; xlabel('ms'); ylabel('mV')
                    end
                    subplot(2,2,4);hold on;
                    for i = 1:2:sum(~(cellfun(@isempty, SP.testpulse)))
                      plot(SP.testpulse{i}(1,1:2000)...
                          -mean(SP.testpulse{i}(1,1:500))+i*increment,... 
                      'k','linewidth',0.1); axis tight; xlabel('time'); ylabel('delta mV')
                    end
                    
                else
                    disp(' stim info missing SP')
                    missingListSP{missingCountSP} = cellList(n).name;
                    missingCountSP = missingCountSP + 1;
                end
                export_fig([save_path,cellList(n).name,' raw data'],'-pdf','-r100');
                close
            end
            save([save_path,cellList(n,1).name,'.mat'], structures2save{:}, 'Metadata'); 
            clear(structures2save{:}); clear Metadata structures2save
        else
            if plotSweeps == 1
                figure('Position',[50 50 400 300]); set(gcf,'color','w');
                if LP.fullStruct == 1
                    for swp = 1:size(LP.V,2)
                        hold on; plot(LP.V{1,swp},'k','linewidth',0.25); axis tight; xlabel('ms'); ylabel('V')
                    end
                    subplot(2,2,4);hold on;
                    for i = 1:length(LP.testpulse)
                      plot(LP.testpulse{i}(1,1:2000)...
                          -mean(LP.testpulse{i}(1,1:500))+i*increment,... 
                      'k','linewidth',0.1); axis tight; xlabel('ms'); ylabel('delta mV')
                    end
                else
                    disp(' stim info missing LP')
                    missingListLP{missingCountLP} = cellList(n).name;
                    missingCountLP = missingCountLP + 1;
                end
                export_fig([save_path,cellList(n).name,' raw data'],'-pdf','-r100');
                close
            end
            save([save_path,cellList(n,1).name,'.mat'], structures2save{:}, 'Metadata');
            clear(structures2save{:}); clear Metadata structures2save
        end
        clear k fileList
    end
    clear n cellList Norig
end
