ind = find(diffMinMaxV~=0);
figure('Position',[50 50 300 250]); set(gcf,'color','w');
histogram(diffMinMaxV(ind),40,'FaceColor','k');
line([minNmaxThres,minNmaxThres],[0,30], ...
            'color','r','linewidth',1,'linestyle','--');
xlabel('diff b/w min and max V')
ylabel('probability')
axis tight
box off
% export_fig(['qc mean diff min max resting V'],'-pdf','-r100');
% close

ind = find(meanOrigV~=0);
figure('Position',[50 50 300 250]); set(gcf,'color','w');
histogram(meanOrigV(ind),40,'FaceColor','k');
xlabel('mean in V across sweep')
ylabel('probability')
axis tight
box off
% export_fig(['qc mean resting V'],'-pdf','-r100');
% close

ind = find(stdOrigV~=0);
figure('Position',[50 50 300 250]); set(gcf,'color','w');
hold on
histogram(stdOrigV(ind),40,'FaceColor','k');
line([origStdThresMax,origStdThresMax],[0,20], ...
            'color','r','linewidth',1,'linestyle','--');
line([origStdThresMin,origStdThresMin],[0,20], ...
            'color','g','linewidth',1,'linestyle','--');
xlabel('std in V across sweep')
ylabel('probability')
axis tight
box off
% export_fig(['qc std resting V'],'-pdf','-r100');
close