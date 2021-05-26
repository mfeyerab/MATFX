classdef StimulusSets < types.untyped.MetaClass & types.untyped.GroupClass
% STIMULUSSETS Stimulus Sets: Parameter waves, referenced custom waves and third-party stimsets


% PROPERTIES
properties
    stimulussetreferenced; % Additional stimulus set waveform data is store here in tree structure.
    stimulussetwavebuilderparameter; % Numerical part of the stimulus set parameter waves for recreating the stimset in MIES. Rows are the data entries, Columns are the index of the segment/epoch and Layers hold different stimulus waveform types. See also https://alleninstitute.github.io/MIES/file/_m_i_e_s___wave_data_folder_getters_8ipf.html#_CPPv423GetWaveBuilderWaveParamv.
    stimulussetwavebuilderparametertext; % Textual part of the stimulus set parameter waves for recreating the stimset in MIES. Rows are the data entries, Columns are the index of the segment/epoch (last index holds settings for the full set) and Layers hold different stimulus waveform types. See also https://alleninstitute.github.io/MIES/file/_m_i_e_s___wave_data_folder_getters_8ipf.html#_CPPv427GetWaveBuilderWaveTextParamv.
    stimulussetwavebuildersegmenttypes; % Stimulus set parameters for the full set. See also https://alleninstitute.github.io/MIES/file/_m_i_e_s___wave_data_folder_getters_8ipf.html#_CPPv418GetSegmentTypeWavev.
    stimulussetwaveform; % Stimulus set waveform data. This is only present if not all three parameter waves could be found or a third-party stimset was used. One column per sweep.
end

methods
    function obj = StimulusSets(varargin)
        % STIMULUSSETS Constructor for StimulusSets
        %     obj = STIMULUSSETS(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % stimulussetreferenced = StimulusSetReferenced
        % stimulussetwavebuilderparameter = StimulusSetWavebuilderParameter
        % stimulussetwavebuilderparametertext = StimulusSetWavebuilderParameterText
        % stimulussetwavebuildersegmenttypes = StimulusSetWavebuilderSegmentTypes
        % stimulussetwaveform = StimulusSetWaveform
        obj = obj@types.untyped.MetaClass(varargin{:});
        [obj.stimulussetwavebuilderparameter, ivarargin] = types.util.parseConstrained(obj,'stimulussetwavebuilderparameter', 'types.ndx_mies.StimulusSetWavebuilderParameter', varargin{:});
        varargin(ivarargin) = [];
        [obj.stimulussetwavebuilderparametertext, ivarargin] = types.util.parseConstrained(obj,'stimulussetwavebuilderparametertext', 'types.ndx_mies.StimulusSetWavebuilderParameterText', varargin{:});
        varargin(ivarargin) = [];
        [obj.stimulussetwavebuildersegmenttypes, ivarargin] = types.util.parseConstrained(obj,'stimulussetwavebuildersegmenttypes', 'types.ndx_mies.StimulusSetWavebuilderSegmentTypes', varargin{:});
        varargin(ivarargin) = [];
        [obj.stimulussetwaveform, ivarargin] = types.util.parseConstrained(obj,'stimulussetwaveform', 'types.ndx_mies.StimulusSetWaveform', varargin{:});
        varargin(ivarargin) = [];
        [obj.stimulussetreferenced,ivarargin] = types.util.parseAnon('types.ndx_mies.StimulusSetReferenced', varargin{:});
        varargin(ivarargin) = [];
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.ndx_mies.StimulusSets')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.stimulussetreferenced(obj, val)
        obj.stimulussetreferenced = obj.validate_stimulussetreferenced(val);
    end
    function obj = set.stimulussetwavebuilderparameter(obj, val)
        obj.stimulussetwavebuilderparameter = obj.validate_stimulussetwavebuilderparameter(val);
    end
    function obj = set.stimulussetwavebuilderparametertext(obj, val)
        obj.stimulussetwavebuilderparametertext = obj.validate_stimulussetwavebuilderparametertext(val);
    end
    function obj = set.stimulussetwavebuildersegmenttypes(obj, val)
        obj.stimulussetwavebuildersegmenttypes = obj.validate_stimulussetwavebuildersegmenttypes(val);
    end
    function obj = set.stimulussetwaveform(obj, val)
        obj.stimulussetwaveform = obj.validate_stimulussetwaveform(val);
    end
    %% VALIDATORS
    
    function val = validate_stimulussetreferenced(obj, val)
        val = types.util.checkDtype('stimulussetreferenced', 'types.ndx_mies.StimulusSetReferenced', val);
    end
    function val = validate_stimulussetwavebuilderparameter(obj, val)
        constrained = { 'types.ndx_mies.StimulusSetWavebuilderParameter' };
        types.util.checkSet('stimulussetwavebuilderparameter', struct(), constrained, val);
    end
    function val = validate_stimulussetwavebuilderparametertext(obj, val)
        constrained = { 'types.ndx_mies.StimulusSetWavebuilderParameterText' };
        types.util.checkSet('stimulussetwavebuilderparametertext', struct(), constrained, val);
    end
    function val = validate_stimulussetwavebuildersegmenttypes(obj, val)
        constrained = { 'types.ndx_mies.StimulusSetWavebuilderSegmentTypes' };
        types.util.checkSet('stimulussetwavebuildersegmenttypes', struct(), constrained, val);
    end
    function val = validate_stimulussetwaveform(obj, val)
        constrained = { 'types.ndx_mies.StimulusSetWaveform' };
        types.util.checkSet('stimulussetwaveform', struct(), constrained, val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.untyped.MetaClass(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.stimulussetreferenced)
            refs = obj.stimulussetreferenced.export(fid, [fullpath '/'], refs);
        else
            error('Property `stimulussetreferenced` is required in `%s`.', fullpath);
        end
        if ~isempty(obj.stimulussetwavebuilderparameter)
            refs = obj.stimulussetwavebuilderparameter.export(fid, fullpath, refs);
        end
        if ~isempty(obj.stimulussetwavebuilderparametertext)
            refs = obj.stimulussetwavebuilderparametertext.export(fid, fullpath, refs);
        end
        if ~isempty(obj.stimulussetwavebuildersegmenttypes)
            refs = obj.stimulussetwavebuildersegmenttypes.export(fid, fullpath, refs);
        end
        if ~isempty(obj.stimulussetwaveform)
            refs = obj.stimulussetwaveform.export(fid, fullpath, refs);
        end
    end
end

end