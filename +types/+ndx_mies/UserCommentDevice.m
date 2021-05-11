classdef UserCommentDevice < types.core.Device & types.untyped.GroupClass
% USERCOMMENTDEVICE Device for the user text notes


% PROPERTIES
properties
    usercommentstring; % device specific user text notes
end

methods
    function obj = UserCommentDevice(varargin)
        % USERCOMMENTDEVICE Constructor for UserCommentDevice
        %     obj = USERCOMMENTDEVICE(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % usercommentstring = UserCommentString
        obj = obj@types.core.Device(varargin{:});
        
        [obj.usercommentstring,ivarargin] = types.util.parseAnon('types.ndx_mies.UserCommentString', varargin{:});
        varargin(ivarargin) = [];
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.ndx_mies.UserCommentDevice')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.usercommentstring(obj, val)
        obj.usercommentstring = obj.validate_usercommentstring(val);
    end
    %% VALIDATORS
    
    function val = validate_usercommentstring(obj, val)
        val = types.util.checkDtype('usercommentstring', 'types.ndx_mies.UserCommentString', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.Device(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.usercommentstring)
            refs = obj.usercommentstring.export(fid, [fullpath '/'], refs);
        else
            error('Property `usercommentstring` is required in `%s`.', fullpath);
        end
    end
end

end