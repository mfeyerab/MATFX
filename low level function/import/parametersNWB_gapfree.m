% parametersNWB_gapfree

if sum(h5readatt(fileName,[level.Resp,'/starting_time'],'unit') ...
        == 'seconds')==7                                                   % checks if the unit is as expected
    gapfree.acquireRes = 1000/h5readatt(...
        fileName,[level.Resp,'/starting_time'],'rate');                    % gets the sampling intervall    
end    
gapfree.sweep_label(GFREEcount,1) = string(info.Groups(1).Groups(s).Name);

if exist("h5read(fileName,[level.Resp,'/bias_current'])")
gapfree.holding_current(1,GFREEcount) = ...
    h5read(fileName,[level.Resp,'/bias_current'])*1e12;                    % gets the holding current, factor converts into pA
gapfree.bridge_balance(1,GFREEcount) = ...
    h5read(fileName,[level.Resp,'/bridge_balance'])/1e6;                   % gets the bridge balance, factor converts into MOhm
else
    gapfree.holding_current(1,GFREEcount) = nan;
    gapfree.bridge_balance(1,GFREEcount) = nan;
end
gapfree.V{1,GFREEcount} = h5read(fileName,[level.Resp,'/data'])'; 


GFREEcount = GFREEcount + 1;
