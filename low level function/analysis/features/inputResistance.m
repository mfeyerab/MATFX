function [resistance, offset]= inputResistance(SubStatTable, PS, NamesPassedSweeps)

tempX = [];

if nargin==2 %without QC
    [tempY,tempX] = deal(zeros(SubStatTable.Count,1));
    for i = 1: SubStatTable.Count
         if isa(SubStatTable.values{i}.vectordata.map('maxSubDeflection').data, 'double')
          tempY(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data;
          tempX(i,1) = SubStatTable.values{i}.vectordata.map('SwpAmp').data;         
         else
          tempY(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data.load;
          tempX(i,1) = SubStatTable.values{i}.vectordata.map('SwpAmp').data.load;
         end
    end
    check = 0;
elseif nargin==3 % with QC
    
   for i = 1: SubStatTable.Count
     if ismember(str2double(regexp(SubStatTable.keys{i},'\d*','Match')), NamesPassedSweeps)
        if isa(SubStatTable.values{i}.vectordata.map('maxSubDeflection').data, 'double')
          tempY(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data;
          tempX(i,1) = SubStatTable.values{i}.vectordata.map('SwpAmp').data;         
        else
          tempY(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data.load;
          tempX(i,1) = SubStatTable.values{i}.vectordata.map('SwpAmp').data.load;
        end
     end
   end  
   check = 1;
end

if ~isempty(tempX) && length(nonzeros(tempX)) > 1
    [inputX,~,c] = unique(nonzeros(tempX));
    inputY = accumarray(c,nonzeros(tempY),[],@mean);  
    inputX(isnan(inputX)) = [];
    inputY(isnan(inputY)) = [];        
    f = polyfit(inputX,inputY,1);
    resistance = round(f(1) * (10^3),2);
    offset = round(f(2),2);
    if PS.plot_all >= 1 && check == 1
        figure('visible','off'); 
        hold on
        plot(inputX,(f(1)*inputX+f(2))','k','LineWidth',1)
        scatter(inputX,inputY,'r')
        legend('off')
        xlabel('input current (pA)')
        ylabel('change in membrane potential (mV)')
        title('V/I curve')
        box off
        axis tight 
        exportgraphics(gcf,fullfile(PS.outDest, ...
            'resistance', [PS.cellID,' input resistance',PS.pltForm]))
        close
    end
elseif length(nonzeros(tempX)) == 1
  
    f = polyfit([0; tempX],[0; tempY],1);
    resistance = round(f(1) * (10^3));
    offset = 0;
    if PS.plot_all >= 1 && check == 1
        figure('visible','off'); 
        hold on
        plot([0; tempX],(f(1)*[0; tempX]+f(2))','k','LineWidth',1)
        scatter(tempX,tempY,'r')
        legend('off')
        xlabel('input current (pA)')
        ylabel('change in membrane potential (mV)')
        title('V/I curve')
        box off
        axis tight  
        exportgraphics(gcf,fullfile(PS.outDest, ...
            'resistance', [PS.cellID,' input resistance',PS.pltForm]))
        close
    end
else
    resistance = NaN;
    offset = NaN;
end
