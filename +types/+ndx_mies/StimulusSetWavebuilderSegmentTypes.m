classdef StimulusSetWavebuilderSegmentTypes < types.core.NWBData & types.untyped.DatasetClass
% STIMULUSSETWAVEBUILDERSEGMENTTYPES Stimulus set parameters for the full set. See also https://alleninstitute.github.io/MIES/file/_m_i_e_s___wave_data_folder_getters_8ipf.html#_CPPv418GetSegmentTypeWavev.



methods
    function obj = StimulusSetWavebuilderSegmentTypes(varargin)
        % STIMULUSSETWAVEBUILDERSEGMENTTYPES Constructor for StimulusSetWavebuilderSegmentTypes
        %     obj = STIMULUSSETWAVEBUILDERSEGMENTTYPES(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.core.NWBData(varargin{:});
        if strcmp(class(obj), 'types.ndx_mies.StimulusSetWavebuilderSegmentTypes')
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