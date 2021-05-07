function listing = getNWBfiles(varargin)


if nargin == 0
    name = '.';
elseif nargin == 1
    name = varargin{1};
else
    error('Too many input arguments.')
end

listing = dir(fullfile(name(),'**\*.*'));
listing = listing(~[listing.isdir]);
               
inds = [];
n    = 0;
k    = 1;

for k = 1:length(listing)
    if listing(k,1).name(end-2:end) ~= 'nwb' 
        inds(end + 1) = k;
    end
end

listing(inds) = [];