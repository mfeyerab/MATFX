classdef TestpulseDevice < types.untyped.MetaClass & types.untyped.GroupClass
% TESTPULSEDEVICE Device for the testpulse data


% PROPERTIES
properties
    testpulsemetadata; % Metadata about the Testpulse: Rows are the running index, Columns are active AD channels (up to version <= 7) or headstages (version >= 8), the data is in the Layers.
    testpulserawdata; % Raw AD testpulse data
end

methods
    function obj = TestpulseDevice(varargin)
        % TESTPULSEDEVICE Constructor for TestpulseDevice
        %     obj = TESTPULSEDEVICE(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % testpulsemetadata = TestpulseMetadata
        % testpulserawdata = TestpulseRawData
        obj = obj@types.untyped.MetaClass(varargin{:});
        [obj.testpulsemetadata, ivarargin] = types.util.parseConstrained(obj,'testpulsemetadata', 'types.ndx_mies.TestpulseMetadata', varargin{:});
        varargin(ivarargin) = [];
        [obj.testpulserawdata, ivarargin] = types.util.parseConstrained(obj,'testpulserawdata', 'types.ndx_mies.TestpulseRawData', varargin{:});
        varargin(ivarargin) = [];
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.ndx_mies.TestpulseDevice')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.testpulsemetadata(obj, val)
        obj.testpulsemetadata = obj.validate_testpulsemetadata(val);
    end
    function obj = set.testpulserawdata(obj, val)
        obj.testpulserawdata = obj.validate_testpulserawdata(val);
    end
    %% VALIDATORS
    
    function val = validate_testpulsemetadata(obj, val)
        constrained = { 'types.ndx_mies.TestpulseMetadata' };
        types.util.checkSet('testpulsemetadata', struct(), constrained, val);
    end
    function val = validate_testpulserawdata(obj, val)
        constrained = { 'types.ndx_mies.TestpulseRawData' };
        types.util.checkSet('testpulserawdata', struct(), constrained, val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.untyped.MetaClass(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.testpulsemetadata)
            refs = obj.testpulsemetadata.export(fid, fullpath, refs);
        end
        if ~isempty(obj.testpulserawdata)
            refs = obj.testpulserawdata.export(fid, fullpath, refs);
        end
    end
end

end