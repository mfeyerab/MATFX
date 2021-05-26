function vecIndName = addVecInd(DynamicTable, colName, tablepath)
%ADDVECIND Add VectorIndex object to DynamicTable
validateattributes(colName, {'char'}, {'scalartext'});
validateattributes(tablepath, {'char'}, {'scalartext'});
assert(~isempty(tablepath),...
    'MatNWB:DynamicTable:AddRow:MissingTablePath',...
    ['addRow cannot create ragged arrays without a full HDF5 path to the Dynamic Table. '...
    'Please either add the full expected HDF5 path under the keyword argument `tablepath` '...
    'or call addRow with row data only.']);
vecIndName = [colName '_index']; % arbitrary convention of appending '_index' to data column names
if ~endsWith(tablepath, '/')
    tablepath = [tablepath '/'];
end
vecTarget = types.untyped.ObjectView([tablepath colName]);
oldDataHeight = 0;
if isKey(DynamicTable.vectordata, colName) || isprop(DynamicTable, colName)
    if isprop(DynamicTable, colName)
        VecData = DynamicTable.(colName);
    else
        VecData = DynamicTable.vectordata.get(colName);
    end
    if isa(VecData.data, 'types.untyped.DataPipe')
        oldDataHeight = VecData.data.offset;
    else
        oldDataHeight = size(VecData.data, 1);
    end
end

% we presume that if data already existed in the vectordata, then
% it was never a ragged array and thus its elements corresponded
% directly to each row index.
VecIndex = types.hdmf_common.VectorIndex(...
    'target', vecTarget,...
    'data', [0:(oldDataHeight-1)] .'); %#ok<NBRAK>
if isprop(DynamicTable, vecIndName)
    DynamicTable.(vecIndName) = VecIndex;
else
    DynamicTable.vectorindex.set(vecIndName, VecIndex);
end
end