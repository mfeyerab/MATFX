function icSum = getRect(SubThres, IdPassSwps,PS,icSum, ClNr)

DelayTempY = []; DepInstaTempY =[]; DepDelayTempY =[]; InstaTempY = [];
TempX = []; TempX = [];

[HypRectDelay, DepRectDelay, HypRectInsta, DepRectInsta, ...
    hump, humpRat, humpAmp] = deal(nan);

HD = SubThres.maxSubDeflection;
SS = SubThres.SteadyState - SubThres.baseVm;
SwpAmp = SubThres.SwpAmp;
SwpName = SubThres.SwpName;
Idx = ismember(str2double(regexp(SwpName, '\d+', 'match', 'once')), ...
                                     IdPassSwps);

InstaTempY = HD(Idx); DelayTempY = SS(Idx); TempX = SwpAmp(Idx);
DelayTempY = DelayTempY(TempX~=0 & ~isnan(TempX));
InstaTempY = InstaTempY(TempX~=0 & ~isnan(TempX));
TempX = TempX(TempX~=0 & ~isnan(TempX));
TempX = TempX(TempX~=0 & ~isnan(TempX));

[inputX,~,c] = unique(TempX);
TempX = unique(TempX);
if ~isempty(InstaTempY)
 InstaTempY = accumarray(c,InstaTempY,[],@mean);
 DelayTempY = accumarray(c,DelayTempY,[],@mean);
end

[inputX,order] = sort(inputX,'descend');
TempX = TempX(order);
InstaTempY = InstaTempY(order);
DelayTempY= DelayTempY(order);

HypInstTempY = InstaTempY(inputX<0);
HypDelayTempY = DelayTempY(inputX<0);
HypTempX = inputX(inputX<0);

if length(DelayTempY)>1 && length(HypTempX)>1

  HypRectDelay = round(HypDelayTempY(end)/(PS.RinHD/1000*HypTempX(end)),2);
  HypRectInsta = round(HypInstTempY(end)/(PS.RinHD/1000*HypTempX(end)),2);
  if sum(inputX>0)>1
     humpIdx = inputX > max(inputX)*0.6 & inputX < max(inputX)*0.75; 
     DepInstaTempY = InstaTempY(humpIdx); 
     DepDelayTempY = DelayTempY(humpIdx);
     hump = mean(DepInstaTempY-DepDelayTempY);
     humpRat = mean(DepInstaTempY./DepDelayTempY);
     humpAmp = mean(TempX(ismember(InstaTempY,DepInstaTempY)));
     DepLim = max(inputX)*0.9; 
     DepInstaTempY = InstaTempY(inputX>0 & inputX < DepLim);
     DepDelayTempY = DelayTempY(inputX>0 & inputX < DepLim);
     DepTempX = inputX(inputX>0 & inputX < DepLim);
     if length(DepTempX)>1
      DepRectInsta = round(DepInstaTempY(1)/(PS.RinHD/1000*DepTempX(1)),2);
      DepRectDelay = round(DepDelayTempY(1)/(PS.RinHD/1000*DepTempX(1)),2);
     end
  end
 if PS.plot_all >= 1
  figure('visible','off'); 
  hold on
  scatter(inputX,DelayTempY,'r')
  scatter(inputX,InstaTempY,'m')
  if sum(inputX>0)>1
      scatter(inputX(humpIdx),DelayTempY(humpIdx),'k')
      scatter(inputX(humpIdx),InstaTempY(humpIdx),'green')
  end
  if length(HypInstTempY)>1
    fplot(@(x)PS.RinHD/1000*x,[min(TempX) max(TempX)],'c','LineWidth',1)
  end
  if length(HypDelayTempY)>1
   fplot(@(x)PS.RinSS/1000*x,[min(TempX) max(TempX)],'b','LineWidth',1)
  end 

  xlabel('input current (pA)')
  ylabel('change in membrane potential (mV)')
  title('IU curve')
  if max(inputX)<0
    ylim([min(InstaTempY)+(0.2*min(InstaTempY)) 0]); ...
    xlim([min(inputX)-0.05 0])
    legend({'Delayed','','Instant',''},'Location','northwest')
  elseif sum(inputX>0)>1
    ylim([min(InstaTempY)+(0.2*min(InstaTempY)) max(InstaTempY)]); ...
    xlim([min(inputX) DepLim])
  end   
  box off
  F=getframe(gcf);
  imwrite(F.cdata,fullfile(PS.outDest, 'IU', [PS.cellID,'_rectification',PS.pltForm]))
 end
end

icSum.HypRectDelay(ClNr) = HypRectDelay;
icSum.DepRectDelay(ClNr) = DepRectDelay;
icSum.HypRectInsta(ClNr) = HypRectInsta;
icSum.DepRectInsta(ClNr) = DepRectInsta;
icSum.hump(ClNr) = hump;
icSum.humpRat(ClNr) = humpRat;
icSum.humpAmp(ClNr) = humpAmp;