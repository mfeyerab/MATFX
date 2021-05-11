classdef LabNotebookNumericalValues < types.core.NWBData & types.untyped.DatasetClass
% LABNOTEBOOKNUMERICALVALUES Numerical labnotebook values: Rows are the running index, Columns hold the different entry names, Layers (up to nine) hold the headstage dependent data in the first 8 and the headstage independent data in the 9th layer. See also https://alleninstitute.github.io/MIES/labnotebook-docs.html.



methods
    function obj = LabNotebookNumericalValues(varargin)
        % LABNOTEBOOKNUMERICALVALUES Constructor for LabNotebookNumericalValues
        %     obj = LABNOTEBOOKNUMERICALVALUES(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.core.NWBData(varargin{:});
        if strcmp(class(obj), 'types.ndx_mies.LabNotebookNumericalValues')
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