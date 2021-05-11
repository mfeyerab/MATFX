classdef StimulusSetWavebuilderParameter < types.core.NWBData & types.untyped.DatasetClass
% STIMULUSSETWAVEBUILDERPARAMETER Numerical part of the stimulus set parameter waves for recreating the stimset in MIES. Rows are the data entries, Columns are the index of the segment/epoch and Layers hold different stimulus waveform types. See also https://alleninstitute.github.io/MIES/file/_m_i_e_s___wave_data_folder_getters_8ipf.html#_CPPv423GetWaveBuilderWaveParamv.



methods
    function obj = StimulusSetWavebuilderParameter(varargin)
        % STIMULUSSETWAVEBUILDERPARAMETER Constructor for StimulusSetWavebuilderParameter
        %     obj = STIMULUSSETWAVEBUILDERPARAMETER(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        obj = obj@types.core.NWBData(varargin{:});
        if strcmp(class(obj), 'types.ndx_mies.StimulusSetWavebuilderParameter')
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