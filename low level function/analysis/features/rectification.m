function output = rectification(SubStatTable, NamesPassedSweeps)

tempY = [];
tempX = [];

for i = 1: SubStatTable.Count
  if ismember(str2double(regexp(SubStatTable.keys{i},'\d*','Match')), NamesPassedSweeps)
   tempY(i,1) = SubStatTable.values{i}.vectordata.map('maxSubDeflection').data;
   tempX(i,1) = SubStatTable.values{i}.vectordata.map('SweepAmp').data;  
  end
end

tempY = nonzeros(tempY);
tempX = nonzeros(tempX);

if ~isempty(tempY)
    output = min(tempY)/max(tempY)/(min(tempX)/max(tempX));
else
    output = NaN;
end