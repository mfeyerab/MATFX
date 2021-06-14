function [resistance, offset]= inputResistance(SubStatTable, NamesPassedSweeps)

tempX = [];

if nargin==1 
    [tempY,tempX] = deal(zeros(SubStatTable.Count,1));
    for i = 1: SubStatTable.Count
         if isa(SubStatTable.values{i}.vectordata.map('maxSubDeflection').data, 'double')
          tempY(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data;
          tempX(i,1) = SubStatTable.values{i}.vectordata.map('SweepAmp').data;         
         else
          tempY(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data.load;
          tempX(i,1) = SubStatTable.values{i}.vectordata.map('SweepAmp').data.load;
         end
    end
    
elseif nargin==2 
    
   for i = 1: SubStatTable.Count
     if ismember(str2double(regexp(SubStatTable.keys{i},'\d*','Match')), NamesPassedSweeps)
        if isa(SubStatTable.values{i}.vectordata.map('maxSubDeflection').data, 'double')
          tempY(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data;
          tempX(i,1) = SubStatTable.values{i}.vectordata.map('SweepAmp').data;         
        else
          tempY(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data.load;
          tempX(i,1) = SubStatTable.values{i}.vectordata.map('SweepAmp').data.load;
        end
     end
   end        
end

if ~isempty(tempX) && length(nonzeros(tempX)) > 1
    [inputX,~,c] = unique(nonzeros(tempX));
     inputY = accumarray(c,nonzeros(tempY),[],@mean);    
    f = polyfit(inputX,inputY,1);
    resistance = f(1) * (10^3);
    offset = f(2);
    
    figure 
    hold on
    plot(inputX,(f(1)*inputX+f(2))','k','LineWidth',1)
    scatter(inputX,inputY,'r')
    legend('off')
    xlabel('input current (pA)')
    ylabel('change in membrane potential (mV)')
    title('V/I curve')
    box off
    axis tight  
elseif length(nonzeros(tempX)) == 1
  
    f = polyfit([0; tempX],[0; tempY],1);
    resistance = f(1) * (10^3);
    offset = 0;
    
    figure 
    hold on
    plot([0; tempX],(f(1)*[0; tempX]+f(2))','k','LineWidth',1)
    scatter(tempX,tempY,'r')
    legend('off')
    xlabel('input current (pA)')
    ylabel('change in membrane potential (mV)')
    title('V/I curve')
    box off
    axis tight  
else
    resistance = NaN;
    offset = NaN;
end
