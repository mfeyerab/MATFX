function [RinHD, RinSS]= getRin(SubStats, PS, NamesPassedSweeps)

SwpAmp = SubStats.SwpAmp;
HD = SubStats.maxSubDeflection;
HypSS = SubStats.maxSubDeflection(SwpAmp<0) ...
     + SubStats.sag(SwpAmp<0);
DepSS= SubStats.maxSubDeflection(SwpAmp>=0) ...
     - SubStats.sag(SwpAmp>=0);
SS(SwpAmp<0) = HypSS; SS(SwpAmp>=0) = DepSS;
SwpName = SubStats.SwpName;
Idx1 = ismember(str2double(regexp(SwpName, '\d+', 'match', 'once')), ...
                        NamesPassedSweeps) & SwpAmp<11 & SwpAmp~=0;
[tempX, X] = deal(SwpAmp(Idx1));
X = unique(X);

if size(SwpAmp,1)<size(SwpAmp,2)
   X= X';
  tempX = tempX';
end
if ~isempty(tempX)
 [tempX,~,c] = unique(tempX);
 [tempYHD, YHD] = deal(accumarray(c,HD(Idx1),[],@mean));  
 [tempYSS, YSS] = deal(accumarray(c,SS(Idx1),[],@mean));     
 Idx = X>11 | abs(X)<9 | abs(X)>55 |  YHD<PS.maxDefl | YHD>abs(PS.maxDefl)/2;
 tempYHD(Idx) = []; tempYSS(Idx) = []; tempX(Idx) = []; 
 tempXSS=tempX(~isnan(tempYSS)); tempYSS=tempYSS(~isnan(tempYSS));
else
  RinSS = NaN;
  RinHD = NaN;
end
if ~isempty(tempX) && length(unique(tempX)) > 2
  [~,orderHD] = sort(abs(tempX),'ascend');
  if ~isempty(tempYSS)
   [~,orderSS] = sort(abs(tempXSS),'ascend');
   SSfit = fit(tempXSS(orderSS(1:3)),tempYSS(orderSS(1:3)),'poly1');
   RinSS = round(SSfit.p1 * (10^3),1);
  else
     RinSS = NaN;   
  end
  HDfit = fit(tempX(orderHD(1:3)),tempYHD(orderHD(1:3)),'poly1');
  RinHD = round(HDfit.p1 * (10^3),1);
  if PS.plot_all >= 1 
        figure('visible','off'); 
        hold on
        plot(HDfit,'b',tempX(orderHD(1:3)), tempYHD(orderHD(1:3)),'k.')
        if ~isempty(tempYSS)
         plot(SSfit,'c',tempX(orderHD(1:3)),tempYSS(orderHD(1:3)),'green.') 
        end
        fplot(@(x)HDfit.p1*x+HDfit.p2,...
            [min(X) min(tempX(orderHD(1:3)))],'b--','LineWidth',1)
        fplot(@(x)SSfit.p1*x+SSfit.p2,...
            [min(X) min(tempX(orderHD(1:3)))],'c--','LineWidth',1)

  end
elseif ~isempty(tempX)
    tempX = [tempX;0]; tempYSS =[tempYSS;0]; tempYHD = [tempYHD;0];
    SSfit = fit(tempX,tempYSS,'poly1');
    HDfit = fit(tempX,tempYHD,'poly1');
    RinSS = round(SSfit.p1 * (10^3),1);
    RinHD = round(HDfit.p1 * (10^3),1);
    if PS.plot_all >= 1
        figure('visible','off'); 
        hold on
        plot(HDfit,'b',tempX, tempYHD,'k.')
        plot(SSfit,'c',tempX,tempYSS,'green.') 
        if any(X<0)
            fplot(@(x)HDfit.p1*x+HDfit.p2,...
                [min(X) min(tempX)],'b--','LineWidth',1)
            fplot(@(x)SSfit.p1*x+SSfit.p2,...
                [min(X) min(tempX)],'c--','LineWidth',1)
            scatter(X,YHD,'k')
            scatter(X,YSS,'green')
        else
            fplot(@(x)HDfit.p1*x+HDfit.p2,...
                [-5 15],'b--','LineWidth',1)
            fplot(@(x)SSfit.p1*x+SSfit.p2,...
                [-5 15],'c--','LineWidth',1)
            scatter(X,YHD,'k')
            scatter(X,YSS,'green')
        end
    end
elseif isempty(tempX) && sum(Idx1==1)>0
    [tempX, X] = deal(SwpAmp(Idx1));
     X = unique(X);
     if size(SwpAmp,1)<size(SwpAmp,2)
       X= X';
       tempX = tempX';
     end
    [tempX,~,c] = unique(tempX);
    [tempYHD, YHD] = deal(accumarray(c,HD(Idx1),[],@mean));  
    [tempYSS, YSS] = deal(accumarray(c,SS(Idx1),[],@nanmean)); 
    [~,MinStimIdx] = min(abs(tempX));
    tempX = [tempX(MinStimIdx);0]; tempYSS =[tempYSS(MinStimIdx);0];
    tempYHD = [tempYHD(MinStimIdx);0]; [~,MinStimIdx] = min(tempX);
    if ~isnan(tempYSS(MinStimIdx))
     SSfit = fit(tempX,tempYSS,'poly1');
     RinSS = round(SSfit.p1 * (10^3),1);
    else
     RinSS = NaN;
    end
    HDfit = fit(tempX,tempYHD,'poly1');
    RinHD = round(HDfit.p1 * (10^3),1);
    if PS.plot_all >= 1
        figure('visible','off'); 
        hold on
        plot(HDfit,'b',tempX, tempYHD,'k.')
        if exist('SSfit','var')
        plot(SSfit,'c',tempX,tempYSS,'green.') 
        end
        if any(X<0)
          fplot(@(x)HDfit.p1*x+HDfit.p2,...
            [min(X) min(tempX)],'b--','LineWidth',1)
          if exist('SSfit','var')
          fplot(@(x)SSfit.p1*x+SSfit.p2,...
            [min(X) min(tempX)],'c--','LineWidth',1)
          end
           scatter(X,YHD,'k')
           scatter(X,YSS,'green')
        else
           fplot(@(x)HDfit.p1*x+HDfit.p2,...
                [-5 15],'b--','LineWidth',1)
           fplot(@(x)SSfit.p1*x+SSfit.p2,...
                [-5 15],'c--','LineWidth',1)
           scatter(X,YHD,'k')
           scatter(X,YSS,'green')
        end
     end
else 
  RinSS = NaN;
  RinHD = NaN;
end
if ~isempty(tempX) && PS.plot_all >= 1 
 scatter(X,YHD,'k')
 scatter(X,YSS,'green')
 l = legend('Location','northwest');
 if exist('SSfit','var')
   l.String = {'HD','fitHD','SS','fitSS'};
 end
 xlabel('input current (pA)')
 ylabel('change in membrane potential (mV)')
 title('IU curve (fit of Rin)')
 xlim([min(X)-10 15])
 ylim([min(YHD)-2 max(ceil(tempYHD))+1]) 
 box off
 F=getframe(gcf);
 % imwrite(F.cdata,fullfile(PS.outDest, 'IU',[PS.cellID,'_Rin',PS.pltForm]))
end
