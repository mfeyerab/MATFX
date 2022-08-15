classdef DynamicTable < types.hdmf_common.Container & types.untyped.GroupClass
% DYNAMICTABLE A group containing multiple datasets that are aligned on the first dimension (Currently, this requirement if left up to APIs to check and enforce). These datasets represent different columns in the table. Apart from a column that contains unique identifiers for each row, there are no other required datasets. Users are free to add any number of custom VectorData objects (columns) here. DynamicTable also supports ragged array columns, where each element can be of a different size. To add a ragged array column, use a VectorIndex type to index the corresponding VectorData type. See documentation for VectorData and VectorIndex for more details. Unlike a compound data type, which is analogous to storing an array-of-structs, a DynamicTable can be thought of as a struct-of-arrays. This provides an alternative structure to choose from when optimizing storage for anticipated access patterns. Additionally, this type provides a way of creating a table without having to define a compound type up front. Although this convenience may be attractive, users should think carefully about how data will be accessed. DynamicTable is more appropriate for column-centric access, whereas a dataset with a compound type would be more appropriate for row-centric access. Finally, data size should also be taken into account. For small tables, performance loss may be an acceptable trade-off for the flexibility of a DynamicTable.


% PROPERTIES
properties
    colnames; % The names of the columns in this table. This should be used to specify an order to the columns.
    description; % Description of what is in this dynamic table.
    id; % Array of unique identifiers for the rows of this dynamic table.
    vectordata; % Vector columns, including index columns, of this dynamic table.
end

methods
    function obj = DynamicTable(varargin)
        % DYNAMICTABLE Constructor for DynamicTable
        %     obj = DYNAMICTABLE(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % colnames = char
        % description = char
        % id = ElementIdentifiers
        % vectordata = VectorData
        obj = obj@types.hdmf_common.Container(varargin{:});
        [obj.vectordata, ivarargin] = types.util.parseConstrained(obj,'vectordata', 'types.hdmf_common.VectorData', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'colnames',[]);
        addParameter(p, 'description',[]);
        addParameter(p, 'id',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.colnames = p.Results.colnames;
        obj.description = p.Results.description;
        obj.id = p.Results.id;
        if strcmp(class(obj), 'types.hdmf_common.DynamicTable')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.colnames(obj, val)
        obj.colnames = obj.validate_colnames(val);
    end
    function obj = set.description(obj, val)
        obj.description = obj.validate_description(val);
    end
    function obj = set.id(obj, val)
        obj.id = obj.validate_id(val);
    end
    function obj = set.vectordata(obj, val)
        obj.vectordata = obj.validate_vectordata(val);
    end
    %% VALIDATORS
    
    function val = validate_colnames(obj, val)
        val = types.util.checkDtype('colnames', 'char', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = val.dims;
        elseif istable(val)
            valsz = height(val);
        elseif ischar(val)
            valsz = size(val, 1);
        else
            valsz = size(val);
        end
        validshapes = {[Inf]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
        if isa(val, 'types.untyped.DataStub')
            valsz = val.dims;
        elseif istable(val)
            valsz = height(val);
        elseif ischar(val)
            valsz = size(val, 1);
        else
            valsz = size(val);
        end
        validshapes = {[1]};
        types.util.checkDims(valsz, validshapes);
    end
    function val = validate_id(obj, val)
        val = types.util.checkDtype('id', 'types.hdmf_common.ElementIdentifiers', val);
    end
    function val = validate_vectordata(obj, val)
        constrained = { 'types.hdmf_common.VectorData' };
        types.util.checkSet('vectordata', struct(), constrained, val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.Container(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.colnames)
            io.writeAttribute(fid, [fullpath '/colnames'], obj.colnames, 'forceArray');
        else
            error('Property `colnames` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.description)
            io.writeAttribute(fid, [fullpath '/description'], obj.description);
        else
            error('Property `description` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.id)
            refs = obj.id.export(fid, [fullpath '/id'], refs);
        else
            error('Property `id` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.vectordata)
            refs = obj.vectordata.export(fid, fullpath, refs);
        end
    end
    %% ROW METHODS
    function addRow(obj, varargin)
        types.util.dynamictable.addRow(obj, varargin{:});
    end
    
    function row = getRow(obj, id, varargin)
        row = types.util.dynamictable.getRow(obj, id, varargin{:});
    end
    
    function clear(obj)
        types.util.dynamictable.clear(obj);
    end
end

end