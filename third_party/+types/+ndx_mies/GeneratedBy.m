classdef GeneratedBy < types.core.NWBData & types.untyped.DatasetClass
% GENERATEDBY Software provenance information as key (first column) value (second column) pairs.



methods
    function obj = GeneratedBy(varargin)
        % GENERATEDBY Constructor for GeneratedBy
        %     obj = GENERATEDBY(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.core.NWBData(varargin{:});
        if strcmp(class(obj), 'types.ndx_mies.GeneratedBy')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_data(obj, val)
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.NWBData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end