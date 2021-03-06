function b = inputResistanceSS(SubStatTable, NamesPassedSweeps, params)

tempX = [];
    
for i = 1: SubStatTable.Count
 if ismember(str2double(regexp(SubStatTable.keys{i},'\d*','Match')), NamesPassedSweeps)
     if isa(SubStatTable.values{i}.vectordata.map('SteadyState').data, 'double')
      tempY(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data ...
                       +SubStatTable.values{i}.vectordata.map('sag').data;
      tempX(i,1) = SubStatTable.values{i}.vectordata.map('SweepAmp').data;         
     else
      tempY(i,1) = SubStatTable.values{i}.vectordata.map('SteadyState').data.load + ...
         SubStatTable.values{i}.vectordata.map('sag').data.load ;
      tempX(i,1) = SubStatTable.values{i}.vectordata.map('SweepAmp').data.load;
     end
 end
end

if ~isempty(tempX) && length(nonzeros(tempX)) > 1
    [inputX,~,c] = unique(nonzeros(tempX));
     inputY = accumarray(c,nonzeros(tempY),[],@mean);    
    f = polyfit(inputX,inputY,1);
    b = round(f(1) * (10^3),2);

    if params.plot_all == 1
    figure('visible','off') 
    hold on
    plot(inputX,(f(1)*inputX+f(2))','k','LineWidth',1)
    scatter(inputX,inputY,'r')
    legend('off')
    xlabel('input current (pA)')
    ylabel('change in membrane potential (mV)')
    title('V/I curve')
    box off
    axis tight
    export_fig([params.outDest, '\resistance\', ...
        params.cellID, ' resistance_ss'],params.plot_format,'-r100');
    end
else
    b = NaN;   
end  

end