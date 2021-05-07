function b = resistance_hd(LP)

index_passed_sweeps = [];
restVPre_all_sweeps = [];
highest_deflection_all_sweeps = [];
current_passed_sweeps = [];


if LP.fullStruct == 1 
   for i = 1:length(LP.stats)
       if LP.sweepAmps(i)> -100 && LP.sweepAmps(i) < 0 && sum(LP.stats{i, 1}.qc.logicVec) == 0 
          index_passed_sweeps = [index_passed_sweeps,i]; 
          current_passed_sweeps = [current_passed_sweeps, LP.sweepAmps(i)];
          restVPre_all_sweeps = [restVPre_all_sweeps, LP.stats{i, 1}.qc.restVPre];
          highest_deflection_all_sweeps = [highest_deflection_all_sweeps, LP.stats{i, 1}.minV ];
       end
   end  
end

if length(index_passed_sweeps) > 1
voltage_change = highest_deflection_all_sweeps - restVPre_all_sweeps;
f = polyfit(current_passed_sweeps,voltage_change,1);
b = f(1) * (10^3);
% figure 
% hold on
% plot(current_passed_sweeps,(f(1)*current_passed_sweeps+f(2))','k','LineWidth',1)
% scatter(current_passed_sweeps,voltage_change,'r')
% legend('off')
% xlabel('input current (pA)')
% ylabel('change in membrane potential (mV)')
% title('V/I curve')
% box off
% axis tight
% %[filename, pathname] = uiputfile( {'*.pdf'}, 'D:\Documents Michelle\Thesis documents\genpath\resistance plots');
% export_fig([ cellID ' resistance_ss'],'-pdf','-r100', 'D:\Documents Michelle\Thesis documents\genpath\resistance plots')

else
    b = NaN;
end


close