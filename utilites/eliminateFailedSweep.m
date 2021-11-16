function eliminateFailedSweep(input_path)

fileList = dir(fullfile(input_path, 'QC', '*.csv'));
fileList = fileList(contains({fileList(:).name}, 'pass'));

T = readtable(fullfile(input_path, 'box2_ephys.csv'));

for f = 1:length(fileList)
    ID = fileList(f).name;
    chuncks = regexp(ID,'\_','split');
    ID = [chuncks{2}, '_', chuncks{3},'_', chuncks{4}, '_', chuncks{5}];

    if any(ismember(T.internalID, {ID}))
    index = [];
    QC = readtable(fullfile(fileList(f).folder, fileList(f).name));
    QC.bad_spikes(isnan(QC.bad_spikes)) = 1;
        if ~isempty(QC) && exist(fullfile(input_path, '\traces', [ID, '.csv']), 'file')
            QC = QC(contains(QC.Protocol, 'LP'),:);   
            index = all(table2array(QC(:,3:13)),2);
            index = [true; index];        % first row contains timepoints and has to be added 
            Traces = readtable(fullfile(input_path, '\traces',[ID, '.csv']));
            new_ID = NHP_ID_conversion(ID);
            writetable(Traces(index,:), fullfile(input_path, ...
                                    '\traces', [num2str(new_ID), '.csv']));
        end
    end
end
end
