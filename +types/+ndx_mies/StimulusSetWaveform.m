classdef StimulusSetWaveform < types.core.NWBData & types.untyped.DatasetClass
% STIMULUSSETWAVEFORM Stimulus set waveform data. This is only present if not all three parameter waves could be found or a third-party stimset was used. One column per sweep.



methods
    function obj = StimulusSetWaveform(varargin)
        % STIMULUSSETWAVEFORM Constructor for StimulusSetWaveform
        %     obj = STIMULUSSETWAVEFORM(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.core.NWBData(varargin{:});
        if strcmp(class(obj), 'types.ndx_mies.StimulusSetWaveform')
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