classdef LabNotebook < types.untyped.MetaClass & types.untyped.GroupClass
% LABNOTEBOOK Labnotebooks


% PROPERTIES
properties
    labnotebookdevice; % Device for the labnotebooks
end

methods
    function obj = LabNotebook(varargin)
        % LABNOTEBOOK Constructor for LabNotebook
        %     obj = LABNOTEBOOK(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % labnotebookdevice = LabNotebookDevice
        obj = obj@types.untyped.MetaClass(varargin{:});
        
        [obj.labnotebookdevice,ivarargin] = types.util.parseAnon('types.ndx_mies.LabNotebookDevice', varargin{:});
        varargin(ivarargin) = [];
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.ndx_mies.LabNotebook')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.labnotebookdevice(obj, val)
        obj.labnotebookdevice = obj.validate_labnotebookdevice(val);
    end
    %% VALIDATORS
    
    function val = validate_labnotebookdevice(obj, val)
        val = types.util.checkDtype('labnotebookdevice', 'types.ndx_mies.LabNotebookDevice', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.untyped.MetaClass(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.labnotebookdevice)
            refs = obj.labnotebookdevice.export(fid, [fullpath '/'], refs);
        else
            error('Property `labnotebookdevice` is required in `%s`.', fullpath);
        end
    end
end

end