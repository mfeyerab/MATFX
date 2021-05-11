classdef MIESMetaData < types.core.LabMetaData & types.untyped.GroupClass
% MIESMETADATA Additional data and metadata from MIES


% PROPERTIES
properties
    generatedby; % Software provenance information as key (first column) value (second column) pairs.
    labnotebook; % Labnotebooks
    stimulussets; % Stimulus Sets: Parameter waves, referenced custom waves and third-party stimsets
    testpulse; % Testpulse data
    usercomment; % Free form text notes from the experimenter
end

methods
    function obj = MIESMetaData(varargin)
        % MIESMETADATA Constructor for MIESMetaData
        %     obj = MIESMETADATA(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % generatedby = GeneratedBy
        % labnotebook = LabNotebook
        % usercomment = UserComment
        % stimulussets = StimulusSets
        % testpulse = Testpulse
        obj = obj@types.core.LabMetaData(varargin{:});
        
        [obj.generatedby,ivarargin] = types.util.parseAnon('types.ndx_mies.GeneratedBy', varargin{:});
        varargin(ivarargin) = [];
        [obj.labnotebook,ivarargin] = types.util.parseAnon('types.ndx_mies.LabNotebook', varargin{:});
        varargin(ivarargin) = [];
        [obj.usercomment,ivarargin] = types.util.parseAnon('types.ndx_mies.UserComment', varargin{:});
        varargin(ivarargin) = [];
        [obj.stimulussets,ivarargin] = types.util.parseAnon('types.ndx_mies.StimulusSets', varargin{:});
        varargin(ivarargin) = [];
        [obj.testpulse,ivarargin] = types.util.parseAnon('types.ndx_mies.Testpulse', varargin{:});
        varargin(ivarargin) = [];
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.ndx_mies.MIESMetaData')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.generatedby(obj, val)
        obj.generatedby = obj.validate_generatedby(val);
    end
    function obj = set.labnotebook(obj, val)
        obj.labnotebook = obj.validate_labnotebook(val);
    end
    function obj = set.stimulussets(obj, val)
        obj.stimulussets = obj.validate_stimulussets(val);
    end
    function obj = set.testpulse(obj, val)
        obj.testpulse = obj.validate_testpulse(val);
    end
    function obj = set.usercomment(obj, val)
        obj.usercomment = obj.validate_usercomment(val);
    end
    %% VALIDATORS
    
    function val = validate_generatedby(obj, val)
        val = types.util.checkDtype('generatedby', 'types.ndx_mies.GeneratedBy', val);
    end
    function val = validate_labnotebook(obj, val)
        val = types.util.checkDtype('labnotebook', 'types.ndx_mies.LabNotebook', val);
    end
    function val = validate_stimulussets(obj, val)
        val = types.util.checkDtype('stimulussets', 'types.ndx_mies.StimulusSets', val);
    end
    function val = validate_testpulse(obj, val)
        val = types.util.checkDtype('testpulse', 'types.ndx_mies.Testpulse', val);
    end
    function val = validate_usercomment(obj, val)
        val = types.util.checkDtype('usercomment', 'types.ndx_mies.UserComment', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.LabMetaData(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.generatedby)
            refs = obj.generatedby.export(fid, [fullpath '/'], refs);
        else
            error('Property `generatedby` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.labnotebook)
            refs = obj.labnotebook.export(fid, [fullpath '/'], refs);
        else
            error('Property `labnotebook` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.stimulussets)
            refs = obj.stimulussets.export(fid, [fullpath '/'], refs);
        end
        if ~isempty(obj.testpulse)
            refs = obj.testpulse.export(fid, [fullpath '/'], refs);
        end
        if ~isempty(obj.usercomment)
            refs = obj.usercomment.export(fid, [fullpath '/'], refs);
        else
            error('Property `usercomment` is required in `%s`.', fullpath);
        end
    end
end

end