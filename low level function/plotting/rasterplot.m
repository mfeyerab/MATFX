function rasterplot(SpiTi)
nTotalSpikes = sum(cellfun(@length,SpiTi));
xPoints = NaN(nTotalSpikes*3,1);
yPoints = xPoints;
currentInd = 1;

for trials=1:size(SpiTi,1)
     nSpikes = length(SpiTi{trials});
     nanSeparator = NaN(1,nSpikes);
     trialXPoints = [ SpiTi{trials}'; SpiTi{trials}' ; nanSeparator ];
     trialXPoints = trialXPoints(:);
     trialYPoints = [ (trials-0.5)*ones(1,nSpikes);...
                      (trials+0.5)*ones(1,nSpikes); nanSeparator ];
     trialYPoints = trialYPoints(:);
     xPoints(currentInd:currentInd+nSpikes*3-1) = trialXPoints;
     yPoints(currentInd:currentInd+nSpikes*3-1) = trialYPoints;
     currentInd = currentInd + nSpikes*3;
end
plot(xPoints, yPoints, 'k'); hold on
title('raster plot');             box off;
 