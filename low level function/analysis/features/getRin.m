function [RinHD, RinSS, offset]= getRin(SubStatTable, PS, NamesPassedSweeps)

tempX = [];

for i = 1: SubStatTable.Count
 if ismember(str2double(regexp(SubStatTable.keys{i},'\d*','Match')), NamesPassedSweeps)
    if isa(SubStatTable.values{i}.vectordata.map('maxSubDeflection').data, 'double')
      tempYHD(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data;
      tempYSS(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data ...
                   +SubStatTable.values{i}.vectordata.map('sag').data;
      tempX(i,1) = SubStatTable.values{i}.vectordata.map('SwpAmp').data;         
    else
      tempYHD(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data.load;
      tempYSS(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data.load ...
                   +SubStatTable.values{i}.vectordata.map('sag').data.load;
      tempX(i,1) = SubStatTable.values{i}.vectordata.map('SwpAmp').data.load;
    end
 end
end  

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

%     inputX(isnan(inputX)) = [];
%     inputY(isnan(inputY)) = [];        
    fHD = polyfit(inputX,inputYHD,1);
    RinHD = round(fHD(1) * (10^3),2);
    fSS = polyfit(inputX,inputYSS,1);
    RinSS = round(fSS(1) * (10^3),2);
    offset = round(fHD(2),2);
    if PS.plot_all >= 1 
        figure('visible','off'); 
        hold on
        fplot(@(x)fHD(1)*x+fHD(2),'b','LineWidth',1)
        fplot(@(x)fSS(1)*x+fSS(2),'c','LineWidth',1)
        scatter(inputX,inputYHD,'r')
        scatter(inputX,inputYSS,'m')
        legend({'Rin_H_D','Rin_S_S'},'Location','northwest')
        xlabel('input current (pA)')
        ylabel('change in membrane potential (mV)')
        title('IU curve')
        box off
        axis tight 
        F=getframe(gcf);
        imwrite(F.cdata,fullfile(PS.outDest, 'IU', ...
                                   [PS.cellID,'_Rin',PS.pltForm]))
    end
elseif length(tempX) == 1
  
    fHD = polyfit([0; tempX],[0; tempYHD],1);
    RinHD = round(fHD(1) * (10^3),1);
    fSS = polyfit([0; tempX],[0; tempYSS],1);
    RinSS = round(fSS(1) * (10^3),1);

    offset = 0;
    if PS.plot_all >= 1
        figure('visible','off'); 
        hold on
        fplot(@(x)fHD(1)*x,'b', 'Linewidth',1)
        fplot(@(x)fSS(1)*x,'c', 'Linewidth',1)
        scatter(tempX,tempYHD,'r')
        scatter(tempX,tempYSS,'m')
        legend({'Rin_H_D','Rin_S_S'},'Location','northwest')
        if max(tempX)<0
          xlim([tempX-10 15])
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
