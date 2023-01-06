function [HypRectDelay, DepRectDelay, HypRectInsta, DepRectInsta] = getRect(SubThres, IdPassSwps,PS)

DelayTempY = [];
DepInstaTempY =[];
DepDelayTempY =[];
InstaTempY = [];
TempX = [];
[HypRectDelay, DepRectDelay, HypRectInsta, DepRectInsta] = deal(nan);

for i = 1: SubThres.Count
  if ismember(str2double(regexp(SubThres.keys{i},'\d*','Match')), IdPassSwps)
   DelayTempY(i,1) = SubThres.values{i}.vectordata.map('SteadyState').data - ...
       SubThres.values{i}.vectordata.map('baseVm').data;
   InstaTempY(i,1) = SubThres.values{i}.vectordata.map('maxSubDeflection').data;
   TempX(i,1) = SubThres.values{i}.vectordata.map('SwpAmp').data/(PS.tau/PS.Rin*1000); 
  end
end

DelayTempY = DelayTempY(TempX~=0);
InstaTempY = InstaTempY(TempX~=0);
TempX = TempX(TempX~=0);

[inputX,~,c] = unique(TempX);
InstaTempY = accumarray(c,InstaTempY,[],@mean);
DelayTempY = accumarray(c,DelayTempY,[],@mean);

[inputX,order] = sort(inputX,'descend');
InstaTempY = InstaTempY(order);
DelayTempY= DelayTempY(order);

HypInstaTempY = InstaTempY(inputX<0);
HypDelayTempY = DelayTempY(inputX<0);
HypTempX = inputX(inputX<0);

if length(DelayTempY)>1 && length(HypTempX)>1

  DelayFit = polyfit(HypTempX(1:2),HypDelayTempY(1:2),1);
  HypRectDelay = round(...
      HypDelayTempY(end)/(DelayFit(1)*HypTempX(end)+DelayFit(2)), ...
         2);
end

if length(InstaTempY)>1 && length(HypTempX)>1
  HypInstFit = polyfit(HypTempX(1:2),HypInstaTempY(1:2),1);
  HypRectInsta = round(...
      HypInstaTempY(end)/(HypInstFit(1)*HypTempX(end)+HypInstFit(2)), ...
         2);
  if sum(inputX>0)>1
     DepLim = max(inputX)*0.66; 
     DepInstaTempY = InstaTempY(inputX>0 & inputX < DepLim);
     DepDelayTempY = DelayTempY(inputX>0 & inputX < DepLim);
     DepTempX = inputX(inputX>0 & inputX < DepLim);
     if length(DepTempX)>1
         DepInstFit = polyfit(DepTempX(end-1:end),...
                                      DepInstaTempY(end-1:end),1);
         DepRectInsta = round(...
          DepInstaTempY(1)/(DepInstFit(1)*DepTempX(1)+DepInstFit(2)), ...
             2);
    
         DepDelayFit = polyfit(DepTempX(end-1:end),...
                                     DepDelayTempY(end-1:end),1);
         DepRectDelay = round(...
         DepDelayTempY(1)/(DepDelayFit(1)*DepTempX(1)+DepDelayFit(2)), ...
             2);
     end
  else
      DepRectInsta = nan;
  end
  figure('visible','off'); 
  hold on
  if ~isempty(HypInstaTempY)
    fplot(@(x)HypInstFit(1)*x+HypInstFit(2),'c','LineWidth',1)
    scatter(inputX,InstaTempY,'m')
  end
  if ~isempty(DepInstaTempY)
    fplot(@(x)DepInstFit(1)*x+DepInstFit(2),'c','LineWidth',1)
  end
      
  if ~isempty(HypDelayTempY)
   fplot(@(x)DelayFit(1)*x+DelayFit(2),'b','LineWidth',1)
   scatter(inputX,DelayTempY,'r')
  end 
  if ~isempty(DepDelayTempY)
    fplot(@(x)DepDelayFit(1)*x+DepDelayFit(2),'b','LineWidth',1)
  end

  legend({'Delayed','','Instant',''},'Location','northwest')
  xlabel('normalized input current (pA/pF)')
  ylabel('change in membrane potential (mV)')
  title('IU curve')
  if max(inputX)<0
    ylim([min(InstaTempY)+(0.2*min(InstaTempY)) 0]); ...
     xlim([min(inputX)-0.05 0])
  elseif sum(inputX>0)>1
    ylim([min(InstaTempY)+(0.2*min(InstaTempY)) max(InstaTempY)]); ...
     xlim([min(inputX) DepLim])
  else
     ylim([min(InstaTempY)+(0.2*min(InstaTempY)) max(InstaTempY)]); ...
     xlim([min(inputX) max(inputX)])
  end
  box off
  F=getframe(gcf);
  imwrite(F.cdata,fullfile(PS.outDest, 'IU', [PS.cellID,'_HyperRectification',PS.pltForm]))
end