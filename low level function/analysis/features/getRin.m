function [RinHD, RinSS, offset]= getRin(SubStatTable, PS, NamesPassedSweeps)

HD = SubStatTable.vectordata.map('maxSubDeflection').data;
SS = SubStatTable.vectordata.map('maxSubDeflection').data ...
     + SubStatTable.vectordata.map('sag').data;
SwpAmp = SubStatTable.vectordata.map('SwpAmp').data;
SwpName = SubStatTable.vectordata.map('SwpName').data;
Idx = ismember(str2double(regexp(SwpName, '\d+', 'match', 'once')), ...
                                     NamesPassedSweeps);
tempYHD = HD(Idx); tempYSS = SS(Idx); tempX = SwpAmp(Idx);

if ~isempty(tempX)
 tempYHD(tempX==0 | tempX>10)=[];
 tempYSS(tempX==0 | tempX>10)=[];
 tempX(tempX==0 | tempX>10)=[];
else
  RinSS = NaN;
  RinHD = NaN;
  offset = NaN; 
end

if ~isempty(tempX) && length(tempX) > 1
    [inputX,~,c] = unique(tempX);
    inputYHD = accumarray(c,tempYHD,[],@mean);  
    inputYSS = accumarray(c,tempYSS,[],@mean);  
    [~,order] = sort(abs(inputX),'ascend');
    HDfit = polyfit([inputX(order==1), inputX(order==2)], ...
        [inputYHD(order==1), inputYHD(order==2)],1);
    nHD=3; stop=1;
    while stop && nHD<length(order)
       if (inputX(order==nHD)*HDfit(1)+HDfit(2)-inputYHD(order==nHD))^2 > 0.9
          HDfit = polyfit([inputX(order<=nHD), inputX(order<=nHD)], ...
                   [inputYHD(order<=nHD), inputYHD(order<=nHD)],1);
           nHD=nHD+1;
       else
           stop=0;
       end
    end
    SSfit = polyfit([inputX(order==1), inputX(order==2)], ...
        [inputYSS(order==1), inputYSS(order==2)],1);
    nSS=3; stop=1;
    while stop && nSS<length(order)
       if (inputX(order==nSS)*SSfit(1)+SSfit(2)-inputYSS(order==nSS))^2 > 0.9
          SSfit = polyfit([inputX(order<=nSS), inputX(order<=nSS)], ...
                   [inputYSS(order<=nSS), inputYSS(order<=nSS)],1);
           nSS=nSS+1;
       else
           stop=0;
       end
    end
    offset = round(HDfit(2),2);
    RinSS = round(SSfit(1) * (10^3),1);
    RinHD = round(HDfit(1) * (10^3),1);
    if PS.plot_all >= 1 
        figure('visible','off'); 
        hold on
        fplot(@(x)HDfit(1)*x+HDfit(2),'b','LineWidth',1)
        fplot(@(x)SSfit(1)*x+SSfit(2),'c','LineWidth',1)
        scatter(inputX(order<=nHD),inputYHD(order<=nHD),'k')
        if nHD<length(order)
         scatter(inputX(order>nHD),inputYHD(order>nHD),'r')
        end
        scatter(inputX(order<=nSS),inputYSS(order<=nSS),'green')
        if nSS<length(order)
         scatter(inputX(order>nSS),inputYSS(order>nSS),'m')
        end    
        legend({'Rin_H_D','Rin_S_S'},'Location','northwest')
        xlabel('input current (pA)')
        ylabel('change in membrane potential (mV)')
        title('IU curve (fit of Rin)')
        box off
        axis tight 
        F=getframe(gcf);
        imwrite(F.cdata,fullfile(PS.outDest, 'IU', ...
                                   [PS.cellID,'_Rin',PS.pltForm]))
    end
elseif exist('inputX','var') && length(inputX) == 1
  
    fHD = polyfit([0; inputX],[0; tempYHD],1);
    RinHD = round(HDfit(1) * (10^3),1);
    fSS = polyfit([0; inputX],[0; tempYSS],1);
    RinSS = round(SSfit(1) * (10^3),1);

    offset = 0;
    if PS.plot_all >= 1
        figure('visible','off'); 
        hold on
        fplot(@(x)fHD(1)*x,'b', 'Linewidth',1)
        fplot(@(x)fSS(1)*x,'c', 'Linewidth',1)
        scatter(inputX,tempYHD,'r')
        scatter(inputX,tempYSS,'m')
        legend({'Rin_H_D','Rin_S_S'},'Location','northwest')
        if max(inputX)<0
          xlim([inputX-10 15])
          ylim([floor(tempYSS/10)*10, 4])
        else
          xlim([-10 15])  
          ylim([-5 ceil(max(tempYSS)/10)*10])
        end
        xlabel('input current (pA)')
        ylabel('change in membrane potential (mV)')
        title('IU curve')
        F=getframe(gcf);
        imwrite(F.cdata,fullfile(PS.outDest, 'IU', ...
                                   [PS.cellID,'_Rin',PS.pltForm]))
    end
else   
    RinSS = NaN;
    RinHD = NaN;
    offset = NaN;
end
