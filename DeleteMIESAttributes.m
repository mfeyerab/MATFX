
main = 'D:\conversion\Allen\000020';

cellList = dir([main,'\','**\*.nwb*']);
cellList = cellList(~[cellList.isdir]);

for n = 1:length(cellList)

info = h5info(fullfile(cellList(n).folder,cellList(n).name));
fid = H5F.open(fullfile(cellList(n).folder,cellList(n).name),'H5F_ACC_RDWR','H5P_DEFAULT');
% 
% for s = 1:length(info.Groups(1).Groups)
%     gid = H5G.open(fid,[info.Groups(1).Groups(s).Name]);
%     dest_id = H5D.open(gid, 'data'); 
%     data_info = H5O.get_info(dest_id);
%     attr_names = cell(data_info.num_attrs,1);
%     for idx = 0:data_info.num_attrs-1
%      attr_id = H5A.open_by_idx(gid,'data','H5_INDEX_NAME','H5_ITER_DEC',idx);
%      attr_names(idx+1) = {H5A.get_name(attr_id)};
%     end
%     if any(contains(attr_names, 'IGOR'))
%         H5A.delete(dest_id,'IGORWaveUnits')
%         H5A.delete(dest_id,'IGORWaveNote')
%         H5A.delete(dest_id,'IGORWaveType')
%         H5A.delete(dest_id,'IGORWaveScaling')
%     end  
%     if any(strcmp({info.Groups(1).Groups(s).Attributes.Value},'CurrentClampSeries'))  
%        if H5L.exists(gid,'bias_current','H5P_DEFAULT') 
%          dest_id = H5D.open(gid, 'bias_current'); 
%          H5A.delete(dest_id,'unit')
%        end
%        if H5L.exists(gid,'capacitance_compensation','H5P_DEFAULT') 
%          dest_id = H5D.open(gid, 'capacitance_compensation'); 
%          H5A.delete(dest_id,'unit')
%        end
%        if H5L.exists(gid,'bridge_balance','H5P_DEFAULT') 
%          dest_id = H5D.open(gid, 'bridge_balance'); 
%          H5A.delete(dest_id,'unit')
%        end
%     end
% end
% 
% for s = 1:length(info.Groups(6).Groups(1).Groups)
%     gid = H5G.open(fid,[info.Groups(6).Groups(1).Groups(s).Name]);
%     dest_id = H5D.open(gid, 'data'); 
%     data_info = H5O.get_info(dest_id);
%     attr_names = cell(data_info.num_attrs,1);
%     for idx = 0:data_info.num_attrs-1
%      attr_id = H5A.open_by_idx(gid,'data','H5_INDEX_NAME','H5_ITER_DEC',idx);
%      attr_names(idx+1) = {H5A.get_name(attr_id)};
%     end
%     if any(contains(attr_names, 'IGOR'))
%         H5A.delete(dest_id,'IGORWaveUnits')
%         H5A.delete(dest_id,'IGORWaveNote')
%         H5A.delete(dest_id,'IGORWaveType')
%         H5A.delete(dest_id,'IGORWaveScaling')
%     end
% end
% 
% %% Lab book
% gid = H5G.open(fid,[info.Groups(3).Groups(3).Groups.Name]);
% 
% for d = 1:length(info.Groups(3).Groups(3).Groups.Datasets)
% dest_id = H5D.open(gid, info.Groups(3).Groups(3).Groups(1).Datasets(d).Name); 
% H5A.delete(dest_id,'IGORWaveType')
% H5A.delete(dest_id,'IGORWaveNote')
% H5A.delete(dest_id,'IGORWaveDimensionLabels')
% end
% 
% %% Stimsets
% gid = H5G.open(fid,[info.Groups(3).Groups(4).Name]);
% 
% for st =1:length(info.Groups(3).Groups(4).Datasets)
%     dest_id = H5D.open(gid, info.Groups(3).Groups(4).Datasets(st).Name); 
%     data_info = H5O.get_info(dest_id);
%     if data_info.num_attrs == 6
%         H5A.delete(dest_id,'IGORWaveType')
%         H5A.delete(dest_id,'IGORWaveNote')
%         H5A.delete(dest_id,'IGORWaveDimensionLabels')
%     elseif data_info.num_attrs == 4
%         H5A.delete(dest_id,'IGORWaveType')
%     elseif data_info.num_attrs == 5
%         H5A.delete(dest_id,'IGORWaveType')
%         H5A.delete(dest_id,'IGORWaveNote')
%     end
% end

%% Testpulse
gid = H5G.open(fid,[info.Groups(3).Groups(6).Name]);

for d = 2:length(info.Groups(3).Groups(6).Groups.Datasets)
    dest_id = H5D.open(gid, [info.Groups(3).Groups(6).Groups.Name,...
        '/',info.Groups(3).Groups(6).Groups.Datasets(d).Name]);
    H5A.delete(dest_id,'IGORWaveType')
    H5A.delete(dest_id,'IGORWaveNote')
    H5A.delete(dest_id,'IGORWaveScaling')
    H5A.delete(dest_id,'IGORWaveUnits')
    H5A.delete(dest_id,'IGORWaveDimensionLabels')
end
%% Close
H5F.close(fid);
end