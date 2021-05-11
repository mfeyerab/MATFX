classdef TestpulseMetadata < types.core.NWBData & types.untyped.DatasetClass
% TESTPULSEMETADATA Metadata about the Testpulse: Rows are the running index, Columns are active AD channels (up to version <= 7) or headstages (version >= 8), the data is in the Layers.



methods
    function obj = TestpulseMetadata(varargin)
        % TESTPULSEMETADATA Constructor for TestpulseMetadata
        %     obj = TESTPULSEMETADATA(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.core.NWBData(varargin{:});
        if strcmp(class(obj), 'types.ndx_mies.TestpulseMetadata')
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