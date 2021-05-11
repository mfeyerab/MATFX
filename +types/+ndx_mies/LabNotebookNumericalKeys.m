classdef LabNotebookNumericalKeys < types.core.NWBData & types.untyped.DatasetClass
% LABNOTEBOOKNUMERICALKEYS Numerical labnotebook keys: First row is the name, second row is the unit and third row is the tolerance. Columns are the running index. See also https://alleninstitute.github.io/MIES/labnotebook-docs.html.



methods
    function obj = LabNotebookNumericalKeys(varargin)
        % LABNOTEBOOKNUMERICALKEYS Constructor for LabNotebookNumericalKeys
        %     obj = LABNOTEBOOKNUMERICALKEYS(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.core.NWBData(varargin{:});
        if strcmp(class(obj), 'types.ndx_mies.LabNotebookNumericalKeys')
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