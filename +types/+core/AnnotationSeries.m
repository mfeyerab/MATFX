classdef AnnotationSeries < types.core.TimeSeries & types.untyped.GroupClass
% ANNOTATIONSERIES Stores user annotations made during an experiment. The data[] field stores a text array, and timestamps are stored for each annotation (ie, interval=1). This is largely an alias to a standard TimeSeries storing a text array but that is identifiable as storing annotations in a machine-readable way.



methods
    function obj = AnnotationSeries(varargin)
        % ANNOTATIONSERIES Constructor for AnnotationSeries
        %     obj = ANNOTATIONSERIES(parentname1,parentvalue1,..,parentvalueN,parentargN,name1,value1,...,nameN,valueN)
        varargin = [{'comments' 'no comments' 'data_conversion' types.util.correctType(1, 'float32') 'data_resolution' types.util.correctType(-1, 'float32') 'data_unit' 'n/a' 'description' 'no description'} varargin];
        obj = obj@types.core.TimeSeries(varargin{:});
        if strcmp(class(obj), 'types.core.AnnotationSeries')
            types.util.checkUnset(obj, unique(varargin(1:2:end)));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_comments(obj, val)
        val = types.util.checkDtype('comments', 'char', val);
    end
    function val = validate_data(obj, val)
        val = types.util.checkDtype('data', 'char', val);
    end
    function val = validate_data_conversion(obj, val)
        val = types.util.checkDtype('data_conversion', 'float32', val);
    end
    function val = validate_description(obj, val)
        val = types.util.checkDtype('description', 'char', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.TimeSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end