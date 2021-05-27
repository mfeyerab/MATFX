function b = inputResistance(SubStatTable, NamesPassedSweeps)

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
     if ismember(str2num(SubStatTable.keys{i}(end-1:end)), NamesPassedSweeps)
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

if ~isempty(tempX) && length(tempX) > 1
    [inputX,~,c] = unique(tempX);
     inputY = accumarray(c,tempY,[],@mean);

    f = polyfit(inputX,inputY,1);
    b = f(1) * (10^3);

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
else
    b = NaN;   
    %[filename, pathname] = uiputfile( {'*.pdf'}, 'D:\Documents Michelle\Thesis documents\genpath\resistance plots');
    %export_fig([ cellID ' resistance_ss'],'-pdf','-r100', 'D:\Documents Michelle\Thesis documents\genpath\resistance plots')
end    
end