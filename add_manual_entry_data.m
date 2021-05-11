mainFolder = 'C:\Users\mjimenez\Documents\GitHub\QC_PCTD\';            % main folder (EDIT HERE)
start = 1;

outDest = 'C:\Users\mjimenez\Documents\GitHub\QC_PCTD\';                                             % general path
cellList = dir([mainFolder,'*.nwb']);                                          % list of cell data files
T = readtable('manual_entry_data.csv');
tic;                                                                       % initialize clock
for n = start:length(cellList)                                                 % for all cells in directory
    cellID = cellList(n).name(1:length(cellList(n).name)-4);               % cell ID (used for saving data)
    disp(cellID)                                                           % display ID number
    cellFile = nwbRead([mainFolder,cellList(n).name]);                                                      % load nwb file
    idx = find(strcmp(T.IDS, cellID));
    types.core.Subject( ...
    'description', T.SubjectID(idx), 'age', T.SubjectAge(idx), ...
    'sex', T.SubjectSex(idx), 'species', T.SubjectBreed(idx));
    nwbExport(cellFile, cellList(n).name);
end