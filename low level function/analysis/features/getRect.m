function icSum = getRect(SubThres, IdPassSwps,PS,icSum, ClNr)

DelayTempY = []; DepInstaTempY =[]; DepDelayTempY =[]; InstaTempY = [];
TempXnorm = []; TempX = [];

[HypRectDelay, DepRectDelay, HypRectInsta, DepRectInsta, ...
    hump, humpRat, humpAmp] = deal(nan);

for i = 1: SubThres.Count
  if ismember(str2double(regexp(SubThres.keys{i},'\d*','Match')), IdPassSwps)
   DelayTempY(i,1) = SubThres.values{i}.vectordata.map('SteadyState').data - ...
       SubThres.values{i}.vectordata.map('baseVm').data;
   InstaTempY(i,1) = SubThres.values{i}.vectordata.map('maxSubDeflection').data;
   TempXnorm(i,1) = SubThres.values{i}.vectordata.map('SwpAmp').data/(PS.tau/PS.Rin*1000); 
   TempX(i,1) = SubThres.values{i}.vectordata.map('SwpAmp').data; 
  end
end

DelayTempY = DelayTempY(TempXnorm~=0 & ~isnan(TempXnorm));
InstaTempY = InstaTempY(TempXnorm~=0 & ~isnan(TempXnorm));
TempX = TempX(TempXnorm~=0 & ~isnan(TempXnorm));
TempXnorm = TempXnorm(TempXnorm~=0 & ~isnan(TempXnorm));

[inputXnorm,~,c] = unique(TempXnorm);
TempX = unique(TempX);
if ~isempty(InstaTempY)
 InstaTempY = accumarray(c,InstaTempY,[],@mean);
 DelayTempY = accumarray(c,DelayTempY,[],@mean);
end


[inputXnorm,order] = sort(inputXnorm,'descend');
TempX = TempX(order);
InstaTempY = InstaTempY(order);
DelayTempY= DelayTempY(order);

HypInstaTempY = InstaTempY(inputXnorm<0);
HypDelayTempY = DelayTempY(inputXnorm<0);
HypTempX = inputXnorm(inputXnorm<0);

if length(DelayTempY)>1 && length(HypTempX)>1

  DelayFit = polyfit(HypTempX(1:2),HypDelayTempY(1:2),1);
  HypRectDelay = round(...
      HypDelayTempY(end)/(DelayFit(1)*HypTempX(end)+DelayFit(2)), ...
         2);
  DepMax = max(inputXnorm)*0.75; 
  DepMin = max(inputXnorm)*0.5; 
  DepInstaTempY = InstaTempY(inputXnorm>DepMin & inputXnorm < DepMax);
  DepDelayTempY = DelayTempY(inputXnorm>DepMin & inputXnorm < DepMax);
  hump = mean(DepInstaTempY-DepDelayTempY);
  humpRat = mean(DepInstaTempY./DepDelayTempY);
  humpAmp = mean(TempX(ismember(InstaTempY,DepInstaTempY)));
end

if length(InstaTempY)>1 && length(HypTempX)>1
  HypInstFit = polyfit(HypTempX(1:2),HypInstaTempY(1:2),1);
  HypRectInsta = round(...
      HypInstaTempY(end)/(HypInstFit(1)*HypTempX(end)+HypInstFit(2)), ...
         2);
  if sum(inputXnorm>0)>1
     DepLim = max(inputXnorm)*0.75; 
     DepInstaTempY = InstaTempY(inputXnorm>0 & inputXnorm < DepLim);
     DepDelayTempY = DelayTempY(inputXnorm>0 & inputXnorm < DepLim);
     DepTempX = inputXnorm(inputXnorm>0 & inputXnorm < DepLim);
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
  end
 if PS.plot_all >= 1
  figure('visible','off'); 
  hold on
  scatter(inputXnorm,DelayTempY,'r')
  scatter(inputXnorm,InstaTempY,'m')

  if length(HypInstaTempY)>1
    fplot(@(x)HypInstFit(1)*x+HypInstFit(2),[min(HypTempX) 0],...
        'c','LineWidth',1)
  end
  if length(DepInstaTempY)>1
    fplot(@(x)DepInstFit(1)*x+DepInstFit(2),[0 max(DepTempX)],...
        'Color',[0 0.4470 0.7410],'LineWidth',1)
  end
  if length(HypDelayTempY)>1
   fplot(@(x)DelayFit(1)*x+DelayFit(2),[min(HypTempX) 0],'b','LineWidth',1)
  end 
  if length(DepDelayTempY)>1
    fplot(@(x)DepDelayFit(1)*x+DepDelayFit(2),[0 max(DepTempX)],...
        'Color',[0.3010 0.7450 0.9330],'LineWidth',1)
  end

  xlabel('normalized input current (pA/pF)')
  ylabel('change in membrane potential (mV)')
  title('IU curve')
  if max(inputXnorm)<0
    ylim([min(InstaTempY)+(0.2*min(InstaTempY)) 0]); ...
    xlim([min(inputXnorm)-0.05 0])
    legend({'Delayed','','Instant',''},'Location','northwest')
  elseif sum(inputXnorm>0)>1
    ylim([min(InstaTempY)+(0.2*min(InstaTempY)) max(InstaTempY)]); ...
    xlim([min(inputXnorm) DepLim])
    f = gcf;
    if size(f.Children.Children,1)==4
            legend({'Delayed','Delayed','Instant','Instant'},'Location','northwest')   
    else
    legend({ 'Delayed','Instant','Instant_f_i_t_H_y_p','Instant_f_i_t_D_e_p', ...
        'Delayed_f_i_t_H_y_p','Delayed_f_i_t_D_e_p'},...
        'Location','northwest')  
    end
  else
    ylim([min(InstaTempY)+(0.2*min(InstaTempY)) max(InstaTempY)]); ...
    xlim([min(inputXnorm) max(inputXnorm)])
    legend({'Delayed','Delayed','Instant','Instant'},'Location','northwest')   
  end
  box off
  F=getframe(gcf);
  imwrite(F.cdata,fullfile(PS.outDest, 'IU', [PS.cellID,'_rectification',PS.pltForm]))
 end
end

icSum.HypRectDelay(ClNr,1) = HypRectDelay;
icSum.DepRectDelay(ClNr,1) = DepRectDelay;
icSum.HypRectInsta(ClNr,1) = HypRectInsta;
icSum.DepRectInsta(ClNr,1) = DepRectInsta;
icSum.hump(ClNr,1) = hump;
icSum.humpRat(ClNr,1) = humpRat;
icSum.humpAmp(ClNr,1) = humpAmp;