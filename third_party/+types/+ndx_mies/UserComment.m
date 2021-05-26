classdef UserComment < types.untyped.MetaClass & types.untyped.GroupClass
% USERCOMMENT Free form text notes from the experimenter


% PROPERTIES
properties
    usercommentdevice; % Device for the user text notes
end

methods
    function obj = UserComment(varargin)
        % USERCOMMENT Constructor for UserComment
        %     obj = USERCOMMENT(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        % usercommentdevice = UserCommentDevice
        obj = obj@types.untyped.MetaClass(varargin{:});
        
        [obj.usercommentdevice,ivarargin] = types.util.parseAnon('types.ndx_mies.UserCommentDevice', varargin{:});
        varargin(ivarargin) = [];
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        misc.parseSkipInvalidName(p, varargin);
        if strcmp(class(obj), 'types.ndx_mies.UserComment')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    function obj = set.usercommentdevice(obj, val)
        obj.usercommentdevice = obj.validate_usercommentdevice(val);
    end
    %% VALIDATORS
    
    function val = validate_usercommentdevice(obj, val)
        val = types.util.checkDtype('usercommentdevice', 'types.ndx_mies.UserCommentDevice', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.untyped.MetaClass(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.usercommentdevice)
            refs = obj.usercommentdevice.export(fid, [fullpath '/'], refs);
        else
            error('Property `usercommentdevice` is required in `%s`.', fullpath);
        end
    end
end

end