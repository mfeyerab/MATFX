classdef LabNotebookDevice < types.core.Device & types.untyped.GroupClass
% LABNOTEBOOKDEVICE Device for the labnotebooks


% PROPERTIES
properties
    labnotebooknumericalkeys; % Numerical labnotebook keys: First row is the name, second row is the unit and third row is the tolerance. Columns are the running index. See also https://alleninstitute.github.io/MIES/labnotebook-docs.html.
    labnotebooknumericalvalues; % Numerical labnotebook values: Rows are the running index, Columns hold the different entry names, Layers (up to nine) hold the headstage dependent data in the first 8 and the headstage independent data in the 9th layer. See also https://alleninstitute.github.io/MIES/labnotebook-docs.html.
    labnotebooktextualkeys; % Textual labnotebook keys: First row is the name, second row is the unit and third row is the tolerance. Columns are the running index. See also https://alleninstitute.github.io/MIES/labnotebook-docs.html.
    labnotebooktextualvalues; % Textual labnotebook values: Rows are the running index, Columns hold the different entry names, Layers (up to nine) hold the headstage dependent data in the first 8 and the headstage independent data in the 9th layer. See also https://alleninstitute.github.io/MIES/labnotebook-docs.html.
end

methods
    function obj = LabNotebookDevice(varargin)
        % LABNOTEBOOKDEVICE Constructor for LabNotebookDevice
        %     obj = LABNOTEBOOKDEVICE(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % labnotebooknumericalkeys = LabNotebookNumericalKeys
        % labnotebooknumericalvalues = LabNotebookNumericalValues
        % labnotebooktextualkeys = LabNotebookTextualKeys
        % labnotebooktextualvalues = LabNotebookTextualValues
        obj = obj@types.core.Device(varargin{:});
        
        [obj.labnotebooknumericalkeys,ivarargin] = types.util.parseAnon('types.ndx_mies.LabNotebookNumericalKeys', varargin{:});
        varargin(ivarargin) = [];
        [obj.labnotebooknumericalvalues,ivarargin] = types.util.parseAnon('types.ndx_mies.LabNotebookNumericalValues', varargin{:});
        varargin(ivarargin) = [];
        [obj.labnotebooktextualkeys,ivarargin] = types.util.parseAnon('types.ndx_mies.LabNotebookTextualKeys', varargin{:});
        varargin(ivarargin) = [];
        [obj.labnotebooktextualvalues,ivarargin] = types.util.parseAnon('types.ndx_mies.LabNotebookTextualValues', varargin{:});
        varargin(ivarargin) = [];
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.ndx_mies.LabNotebookDevice')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.labnotebooknumericalkeys(obj, val)
        obj.labnotebooknumericalkeys = obj.validate_labnotebooknumericalkeys(val);
    end
    function obj = set.labnotebooknumericalvalues(obj, val)
        obj.labnotebooknumericalvalues = obj.validate_labnotebooknumericalvalues(val);
    end
    function obj = set.labnotebooktextualkeys(obj, val)
        obj.labnotebooktextualkeys = obj.validate_labnotebooktextualkeys(val);
    end
    function obj = set.labnotebooktextualvalues(obj, val)
        obj.labnotebooktextualvalues = obj.validate_labnotebooktextualvalues(val);
    end
    %% VALIDATORS
    
    function val = validate_labnotebooknumericalkeys(obj, val)
        val = types.util.checkDtype('labnotebooknumericalkeys', 'types.ndx_mies.LabNotebookNumericalKeys', val);
    end
    function val = validate_labnotebooknumericalvalues(obj, val)
        val = types.util.checkDtype('labnotebooknumericalvalues', 'types.ndx_mies.LabNotebookNumericalValues', val);
    end
    function val = validate_labnotebooktextualkeys(obj, val)
        val = types.util.checkDtype('labnotebooktextualkeys', 'types.ndx_mies.LabNotebookTextualKeys', val);
    end
    function val = validate_labnotebooktextualvalues(obj, val)
        val = types.util.checkDtype('labnotebooktextualvalues', 'types.ndx_mies.LabNotebookTextualValues', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.Device(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.labnotebooknumericalkeys)
            refs = obj.labnotebooknumericalkeys.export(fid, [fullpath '/'], refs);
        else
            error('Property `labnotebooknumericalkeys` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.labnotebooknumericalvalues)
            refs = obj.labnotebooknumericalvalues.export(fid, [fullpath '/'], refs);
        else
            error('Property `labnotebooknumericalvalues` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.labnotebooktextualkeys)
            refs = obj.labnotebooktextualkeys.export(fid, [fullpath '/'], refs);
        else
            error('Property `labnotebooktextualkeys` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.labnotebooktextualvalues)
            refs = obj.labnotebooktextualvalues.export(fid, [fullpath '/'], refs);
        else
            error('Property `labnotebooktextualvalues` is required in `%s`.', fullpath);
        end
    end
end

end