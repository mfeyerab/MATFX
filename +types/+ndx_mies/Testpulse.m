classdef Testpulse < types.untyped.MetaClass & types.untyped.GroupClass
% TESTPULSE Testpulse data


% PROPERTIES
properties
    testpulsedevice; % Device for the testpulse data
end

methods
    function obj = Testpulse(varargin)
        % TESTPULSE Constructor for Testpulse
        %     obj = TESTPULSE(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % testpulsedevice = TestpulseDevice
        obj = obj@types.untyped.MetaClass(varargin{:});
        
        [obj.testpulsedevice,ivarargin] = types.util.parseAnon('types.ndx_mies.TestpulseDevice', varargin{:});
        varargin(ivarargin) = [];
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.ndx_mies.Testpulse')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.testpulsedevice(obj, val)
        obj.testpulsedevice = obj.validate_testpulsedevice(val);
    end
    %% VALIDATORS
    
    function val = validate_testpulsedevice(obj, val)
        val = types.util.checkDtype('testpulsedevice', 'types.ndx_mies.TestpulseDevice', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.untyped.MetaClass(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.testpulsedevice)
            refs = obj.testpulsedevice.export(fid, [fullpath '/'], refs);
        else
            error('Property `testpulsedevice` is required in `%s`.', fullpath);
        end
    end
end

end