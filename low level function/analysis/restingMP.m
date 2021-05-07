function b = restingMP(LP)

index_passed_sweeps = [];
rmp_all_sweeps = [];

if LP.fullStruct == 1 
   for i = 1:length(LP.stats)
       if sum(LP.stats{i, 1}.qc.logicVec) == 0 
          index_passed_sweeps = [index_passed_sweeps,i]; 
          rmp_all_sweeps = [rmp_all_sweeps, mean(LP.rmp(:,i))];
       end
   end  

   if isempty(rmp_all_sweeps) == 0 
      b = mean(rmp_all_sweeps);
   else
       b = NaN;
   end   
   
else
    b = NaN;
end


close