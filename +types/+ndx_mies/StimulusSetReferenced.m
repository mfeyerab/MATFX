classdef StimulusSetReferenced < types.untyped.MetaClass & types.untyped.GroupClass
% STIMULUSSETREFERENCED Additional stimulus set waveform data is store here in tree structure.


% PROPERTIES
properties
    stimulussetreferencedfolder; % Folder
end

methods
    function obj = StimulusSetReferenced(varargin)
        % STIMULUSSETREFERENCED Constructor for StimulusSetReferenced
        %     obj = STIMULUSSETREFERENCED(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % stimulussetreferencedfolder = StimulusSetReferencedFolder
        obj = obj@types.untyped.MetaClass(varargin{:});
        [obj.stimulussetreferencedfolder, ivarargin] = types.util.parseConstrained(obj,'stimulussetreferencedfolder', 'types.ndx_mies.StimulusSetReferencedFolder', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.ndx_mies.StimulusSetReferenced')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.stimulussetreferencedfolder(obj, val)
        obj.stimulussetreferencedfolder = obj.validate_stimulussetreferencedfolder(val);
    end
    %% VALIDATORS
    
    function val = validate_stimulussetreferencedfolder(obj, val)
        constrained = {'types.ndx_mies.StimulusSetReferencedFolder'};
        types.util.checkSet('stimulussetreferencedfolder', struct(), constrained, val);
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
    end
end

end