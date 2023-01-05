function [HypRectDelay, DepRectDelay, HypRectInsta, DepRectInsta] = getRect(SubThres, IdPassSwps,PS)

DelayTempY = [];
InstaTempY = [];
TempX = [];

for i = 1: SubThres.Count
  if ismember(str2double(regexp(SubThres.keys{i},'\d*','Match')), IdPassSwps)
   DelayTempY(i,1) = SubThres.values{i}.vectordata.map('SteadyState').data - ...
       SubThres.values{i}.vectordata.map('baseVm').data;
   InstaTempY(i,1) = SubThres.values{i}.vectordata.map('maxSubDeflection').data;
   TempX(i,1) = SubThres.values{i}.vectordata.map('SwpAmp').data/(PS.tau/PS.Rin*1000); 
  end
end

DelayTempY = nonzeros(DelayTempY);
InstaTempY = nonzeros(InstaTempY);
TempX = nonzeros(TempX);

[TempX,order] = sort(TempX,'descend');
InstaTempY = InstaTempY(order);
DelayTempY = DelayTempY(order);
HypInstaTempY = InstaTempY(TempX<0);
HypDelayTempY = DelayTempY(TempX<0);
HypTempX = TempX(TempX<0);

if ~isempty(DelayTempY)

  DelayFit = polyfit(HypTempX(1:2),HypDelayTempY(1:2),1);

  HypRectDelay = round(...
      HypDelayTempY(end)/(DelayFit(1)*HypTempX(end)+DelayFit(2)), ...
         2);

  if sum(TempX>0)>1
     DepRectDelay = round(min(DelayTempY(TempX>0))/max(DelayTempY(TempX>0))/...
                (min(TempX(TempX>0))/max(TempX(TempX>0))),2); 
  else
      DepRectDelay = nan;
  end
else
  HypRectDelay = nan;
  DepRectDelay = nan;
end

if ~isempty(InstaTempY)
  InstFit = polyfit(HypTempX(1:2),HypInstaTempY(1:2),1);
  HypRectInsta = round(...
      HypInstaTempY(end)/(InstFit(1)*HypTempX(end)+InstFit(2)), ...
         2);
  if sum(TempX>0)>1
     DepRectInsta = round(min(InstaTempY(TempX>0))/max(InstaTempY(TempX>0))/...
                (min(TempX(TempX>0))/max(TempX(TempX>0))),2); 
  else
      DepRectInsta = nan;
  end
else
   HypRectInsta = nan;
   DepRectInsta = nan;
end

figure('visible','off'); 
hold on
if ~isempty(InstaTempY)
 fplot(@(x)InstFit(1)*x+InstFit(2),'c','LineWidth',1)
 scatter(TempX,InstaTempY,'m')
end
if ~isempty(DelayTempY)
 fplot(@(x)DelayFit(1)*x+DelayFit(2),'b','LineWidth',1)
 scatter(TempX,DelayTempY,'r')
end 
legend({'Delayed','','Instant',''},'Location','northwest')
xlabel('normalized input current (pA/pF)')
ylabel('change in membrane potential (mV)')
title('IU curve')
if max(TempX)<0
 ylim([min(InstaTempY)-6 0]);xlim([min(TempX)-0.05 0])
else
 ylim([min(InstaTempY)-6 max(InstaTempY)]);xlim([min(TempX) max(TempX)])
end   
box off
F=getframe(gcf);
imwrite(F.cdata,fullfile(PS.outDest, 'IU', [PS.cellID,'_HyperRectification',PS.pltForm]))