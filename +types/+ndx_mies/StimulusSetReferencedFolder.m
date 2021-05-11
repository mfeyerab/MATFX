classdef StimulusSetReferencedFolder < types.untyped.MetaClass & types.untyped.GroupClass
% STIMULUSSETREFERENCEDFOLDER Folder


% PROPERTIES
properties
    stimulussetreferencedfolder; % Nested Folder
    stimulussetreferencedwaveform; % Additional stimulus set waveform data. Some epoch types for stimulus sets allow to include arbitrary waveform data. These waveforms are stored in a tree structure here. The stimulus set parameter referencing these waveforms has the path to these entries with colons (:) separated.
end

methods
    function obj = StimulusSetReferencedFolder(varargin)
        % STIMULUSSETREFERENCEDFOLDER Constructor for StimulusSetReferencedFolder
        %     obj = STIMULUSSETREFERENCEDFOLDER(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % stimulussetreferencedfolder = StimulusSetReferencedFolder
        % stimulussetreferencedwaveform = StimulusSetReferencedWaveform
        obj = obj@types.untyped.MetaClass(varargin{:});
        [obj.stimulussetreferencedfolder, ivarargin] = types.util.parseConstrained(obj,'stimulussetreferencedfolder', 'types.ndx_mies.StimulusSetReferencedFolder', varargin{:});
        varargin(ivarargin) = [];
        [obj.stimulussetreferencedwaveform, ivarargin] = types.util.parseConstrained(obj,'stimulussetreferencedwaveform', 'types.ndx_mies.StimulusSetReferencedWaveform', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.ndx_mies.StimulusSetReferencedFolder')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.stimulussetreferencedfolder(obj, val)
        obj.stimulussetreferencedfolder = obj.validate_stimulussetreferencedfolder(val);
    end
    function obj = set.stimulussetreferencedwaveform(obj, val)
        obj.stimulussetreferencedwaveform = obj.validate_stimulussetreferencedwaveform(val);
    end
    %% VALIDATORS
    
    function val = validate_stimulussetreferencedfolder(obj, val)
        constrained = {'types.ndx_mies.StimulusSetReferencedFolder'};
        types.util.checkSet('stimulussetreferencedfolder', struct(), constrained, val);
    end
    function val = validate_stimulussetreferencedwaveform(obj, val)
        constrained = { 'types.ndx_mies.StimulusSetReferencedWaveform' };
        types.util.checkSet('stimulussetreferencedwaveform', struct(), constrained, val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.untyped.MetaClass(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.stimulussetreferencedfolder)
            refs = obj.stimulussetreferencedfolder.export(fid, fullpath, refs);
        end
        if ~isempty(obj.stimulussetreferencedwaveform)
            refs = obj.stimulussetreferencedwaveform.export(fid, fullpath, refs);
        end
    end
end

end