%{
QCanalysis summary
%}

%distribution of initial membrane potential
ind = find(qc.OrigV~=0);
figure('Position',[50 50 300 250]); set(gcf,'color','w');
histogram(qc.OrigV(ind),40,'FaceColor','k');
xlabel('mean in V across sweep')
ylabel('probability')
axis tight
box off
export_fig(['qc mean resting V'],plot_format,'-r100');
close


p = loadParams;

figure('Position',[50 50 400 600]); set(gcf,'color','w');
subplot(3,4,1)
hold on
for n = 1:length(cellList)
    plot([1 2],[qc.LP.restVpre(n,10) qc.LP.restVpost(n,10)],'k','linewidth',0.25)
end
plot([1 2],[-50 -50],'r-.','linewidth',1)
xlabel('LP 10th sweep')
ylabel('voltage (mV)')
xticks(1:2)
xticklabels({'pre','post'})
subplot(3,4,2)
hold on
for n = 1:length(cellList)
    plot([1 2],[qc.LP.restVpre(n,30) qc.LP.restVpost(n,30)],'k','linewidth',0.25)
end
plot([1 2],[-50 -50],'r-.','linewidth',1)
xlabel('LP 30th sweep')
ylabel('voltage (mV)')
xticks(1:2)
xticklabels({'pre','post'})
subplot(3,4,3)
hold on
for n = 1:length(cellList)
    plot([1 2],[qc.SP.restVpre(n,10) qc.SP.restVpost(n,10)],'k','linewidth',0.25)
end
plot([1 2],[-50 -50],'r-.','linewidth',1)
xlabel('SP 10th sweep')
ylabel('voltage (mV)')
xticks(1:2)
xticklabels({'pre','post'})
subplot(3,4,4)
hold on
for n = 1:length(cellList)
    plot([1 2],[qc.SP.restVpre(n,40) qc.SP.restVpost(n,40)],'k','linewidth',0.25)
end
plot([1 2],[-50 -50],'r-.','linewidth',1)
xlabel('SP 40th sweep')
ylabel('voltage (mV)')
xticks(1:2)
ylim([0 2])
xticklabels({'pre','post'})
subplot(3,4,5)
hold on

for n = 1:length(cellList)
    plot([1 2],[qc.LP.rmse_pre_lt(n,1) qc.LP.rmse_post_lt(n,1)],'k','linewidth',0.25)
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('LP 1st sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2])
xticklabels({'pre','post'})
subplot(3,4,6)
hold on
for n = 1:length(cellList)
    plot([1 2],[qc.LP.rmse_pre_lt(n,12) qc.LP.rmse_post_lt(n,12)],'k','linewidth',0.25)
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('LP 12th sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2])
xticklabels({'pre','post'})
subplot(3,4,7)
hold on
for n = 1:length(cellList)
    plot([1 2],[qc.LP.rmse_pre_lt(n,25) qc.LP.rmse_post_lt(n,25)],'k','linewidth',0.25)
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('LP 25th sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2])
xticklabels({'pre','post'})
subplot(3,4,8)
hold on
for n = 1:length(cellList)
    plot([1 2],[qc.LP.rmse_pre_lt(n,40) qc.LP.rmse_post_lt(n,40)],'k','linewidth',0.25)
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('LP 40th sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2])
xticklabels({'pre','post'})
subplot(3,4,9)
hold on
for n = 1:length(cellList)
    plot([1 2],[qc.SP.rmse_pre_lt(n,10) qc.SP.rmse_post_lt(n,10)],'k','linewidth',0.25)
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('SP 10th sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2])
xticklabels({'pre','post'})
subplot(3,4,10)
hold on
for n = 1:length(cellList)
    plot([1 2],[qc.SP.rmse_pre_lt(n,20) qc.SP.rmse_post_lt(n,20)],'k','linewidth',0.25)
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('SP 20th sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2])
xticklabels({'pre','post'})
subplot(3,4,11)
hold on
for n = 1:length(cellList)
    plot([1 2],[qc.SP.rmse_pre_lt(n,40) qc.SP.rmse_post_lt(n,40)],'k','linewidth',0.25)
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('SP 40th sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2])
xticklabels({'pre','post'})
subplot(3,4,12)
hold on
for n = 1:length(cellList)
    plot([1 2],[qc.SP.rmse_pre_lt(n,60) qc.SP.rmse_post_lt(n,60)],'k','linewidth',0.25)
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('SP 60th sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2])
xticklabels({'pre','post'})
export_fig(fullfile(save_path, ['Pre_Post_Comparision_',date]),plot_format,'-r100');
close

%%
figure('Position',[50 50 900 900]); set(gcf,'color','w');
ind = qc.LP.rmse_pre_lt(:,1)==0;
subplot(5,4,1)
histogram(qc.LP.rmse_pre_lt(~ind,1),120,'FaceColor','k','Normalization','probability');
line([p.RMSElt,p.RMSElt],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('lt RMS pre-stim LP 1')
    xlim([0 4])
    box off
ind = qc.LP.rmse_pre_lt(:,6)==0;
subplot(5,4,2)
histogram(qc.LP.rmse_pre_lt(~ind,6),120,'FaceColor','k','Normalization','probability');
line([p.RMSElt,p.RMSElt],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('lt RMS pre-stim LP 6')
    xlim([0 4])
    box off
ind = qc.LP.rmse_pre_lt(:,12)==0;
subplot(5,4,3)
histogram(qc.LP.rmse_pre_lt(~ind,12),60,'FaceColor','k','Normalization','probability');
line([p.RMSElt,p.RMSElt],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('lt RMS pre-stim LP 12')
    xlim([0 4])
    box off
ind = qc.LP.rmse_pre_lt(:,20)==0;
subplot(5,4,4)
histogram(qc.LP.rmse_pre_lt(~ind,20),60,'FaceColor','k','Normalization','probability');
line([p.RMSElt,p.RMSElt],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('lt RMS pre-stim LP 20')
    xlim([0 4])
    box off
ind = qc.LP.rmse_post_lt(:,1)==0;
subplot(5,4,5)
histogram(qc.LP.rmse_post_lt(~ind,1),120,'FaceColor','k','Normalization','probability');
line([p.RMSElt,p.RMSElt],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('lt RMS post-stim LP 1')
    xlim([0 4])
    box off
ind = qc.LP.rmse_post_lt(:,6)==0;
subplot(5,4,6)
histogram(qc.LP.rmse_post_lt(~ind,6),120,'FaceColor','k','Normalization','probability');
line([p.RMSElt,p.RMSElt],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('lt RMS post-stim LP 6')
    xlim([0 4])
    box off
ind = qc.LP.rmse_post_lt(:,12)==0;
subplot(5,4,7)
histogram(qc.LP.rmse_post_lt(~ind,12),120,'FaceColor','k','Normalization','probability');
line([p.RMSElt,p.RMSElt],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('lt RMS post-stim LP 12')
    xlim([0 4])
    box off
ind = qc.LP.rmse_post_lt(:,20)==0;
subplot(5,4,8)
histogram(qc.LP.rmse_post_lt(~ind,20),20,'FaceColor','k','Normalization','probability');
line([p.RMSElt,p.RMSElt],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('lt RMS post-stim LP 20')
    xlim([0 4])
    box off
ind = qc.LP.rmse_pre_st(:,1)==0;
subplot(5,4,9)
histogram(qc.LP.rmse_pre_st(~ind,1),40,'FaceColor','k','Normalization','probability');
line([p.RMSEst,p.RMSEst],[0,0.3], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('short-term RMS LP 1')
    axis tight
    box off
ind = qc.LP.rmse_pre_st(:,6)==0;
subplot(5,4,10)
histogram(qc.LP.rmse_pre_st(~ind,6),40,'FaceColor','k','Normalization','probability');
line([p.RMSEst,p.RMSEst],[0,0.3], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('short-term RMS LP 6')
    axis tight
    box off
ind = qc.LP.rmse_pre_st(:,12)==0;
subplot(5,4,11)
histogram(qc.LP.rmse_pre_st(~ind,12),40,'FaceColor','k','Normalization','probability');
line([p.RMSEst,p.RMSEst],[0,0.3], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('short-term RMS LP 12')
    axis tight
    box off
ind = qc.LP.rmse_pre_st(:,20)==0;
subplot(5,4,12)
histogram(qc.LP.rmse_pre_st(~ind,20),40,'FaceColor','k','Normalization','probability');
line([p.RMSEst,p.RMSEst],[0,0.3], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('short-term RMS LP 20')
    axis tight
    box off
ind = qc.LP.restVpre(:,1)==0;
subplot(5,4,13)
histogram(qc.LP.restVpre(~ind,1),40,'FaceColor','k','Normalization','probability');
line([p.maximumRestingPot,p.maximumRestingPot],[0,0.05], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('V rest pre')
    axis tight
    box off
ind = qc.LP.restVpre(:,6)==0;
subplot(5,4,14)
histogram(qc.LP.restVpre(~ind,6),40,'FaceColor','k','Normalization','probability');
line([p.maximumRestingPot,p.maximumRestingPot],[0,0.05], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('V rest pre')
    axis tight
    box off
ind = qc.LP.restVpre(:,12)==0;
subplot(5,4,15)
histogram(qc.LP.restVpre(~ind,12),40,'FaceColor','k','Normalization','probability');
line([p.maximumRestingPot,p.maximumRestingPot],[0,0.05], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('V rest pre')
    axis tight
    box off
ind = qc.LP.restVpre(:,20)==0;
subplot(5,4,16)
histogram(qc.LP.restVpre(~ind,20),40,'FaceColor','k','Normalization','probability');
line([p.maximumRestingPot,p.maximumRestingPot],[0,0.05], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('V rest pre')
    axis tight
    box off
ind = qc.LP.restVdiffpreNpost(:,1)==0;
subplot(5,4,17)
histogram(qc.LP.restVdiffpreNpost(~ind,1),100,'FaceColor','k','Normalization','probability');
line([p.maxDiffBwBeginEnd,p.maxDiffBwBeginEnd],[0,0.2], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('delta V (abs(pre-post)) LP 1')
    xlim([0 15])
    box off
ind = qc.LP.restVdiffpreNpost(:,6)==0;
subplot(5,4,18)
histogram(qc.LP.restVdiffpreNpost(~ind,6),100,'FaceColor','k','Normalization','probability');
line([p.maxDiffBwBeginEnd,p.maxDiffBwBeginEnd],[0,0.2], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('delta V (abs(pre-post)) LP 6')
    xlim([0 15])
    box off
ind = qc.LP.restVdiffpreNpost(:,12)==0;
subplot(5,4,19)
histogram(qc.LP.restVdiffpreNpost(~ind,12),80,'FaceColor','k','Normalization','probability');
line([p.maxDiffBwBeginEnd,p.maxDiffBwBeginEnd],[0,0.2], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('delta V (abs(pre-post)) LP 12')
    xlim([0 15])
    box off
ind = qc.LP.restVdiffpreNpost(:,20)==0;
subplot(5,4,20)
histogram(qc.LP.restVdiffpreNpost(~ind,20),80,'FaceColor','k','Normalization','probability');
line([p.maxDiffBwBeginEnd,p.maxDiffBwBeginEnd],[0,0.2], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('delta V (abs(pre-post)) LP 20')
    xlim([0 15])
    box off
export_fig(fullfile(save_path, ['Distribution_qc_params_LP',date]),plot_format,'-r100');
close

%%
figure('Position',[0 0 300 1000]); set(gcf,'color','w');
imagesc(bsxfun(@rdivide, ...
    table2array(qc_logic_mat(1:length(cellList),2:15)),max(qc.sweepID,[],2)), [0 1])
xlabel('QC criteria')
xticks(1:15)
xticklabels({'st rmse pre','st rmse post','rmse pre','rmse post', ...
 'delta Vm pre2post','Vm abs','I hold','bridg balan abs', ...
 'bridg balan rela', 'between Sw', 'SpQC', 'CW: Ra abs', ...
 'CW: Ra fract', 'CW: basic feat'})
xtickangle(45)
yticks(1:4:length(cellList))
ylabel('cell')
colorbar
colormap('gray');
box off
export_fig(fullfile(save_path, ['QC_tags_relaFrequency_per_cell_',date]),plot_format,'-r100');
close

%% 

figure('Position',[50 50 750 200]); set(gcf,'color','w');
subplot(1,3,1)
hold on
for n = 1:length(cellList)
    scatter(qc.LP.rmse_pre_st(n,1),qc.LP.rmse_post_st(n,1),3,'k')
end
plot([0.2 0.2],[0 0.2],'r','linewidth',0.25)
plot([0 0.2],[0.2 0.2],'r','linewidth',0.25)
xlabel('short term RMS pre')
ylabel('short term RMS post')
xlim([0 0.4])
ylim([0 0.4])
subplot(1,3,2)
hold on
for n = 1:length(cellList)
    scatter(qc.LP.rmse_pre_lt(n,1),qc.LP.rmse_post_lt(n,1),3,'k')
end
plot([0.75 0.75],[0 0.75],'r','linewidth',0.25)
plot([0 0.75],[0.75 0.75],'r','linewidth',0.25)
xlabel('long term RMS pre')
ylabel('long term RMS post')
xlim([0 2])
ylim([0 2])
subplot(1,3,3)
hold on
for n = 1:length(cellList)
    scatter(qc.LP.rmse_pre_st(n,1),qc.LP.rmse_pre_lt(n,1),3,'k')
end
plot([0.2 0.2],[0 0.5],'r','linewidth',0.25)
plot([0 0.2],[0.5 0.5],'r','linewidth',0.25)
xlabel('short term RMS')
ylabel('long term RMS')
xlim([0 0.25])
ylim([0 6.5])
export_fig(fullfile(save_path, ['RMS_scatter_plot',date]),plot_format,'-r100');
close


figure('Position',[50 50 300 250]); set(gcf,'color','w');
plot(qc.V_vecDelta(1:length(cellList),1:150)')
xlabel('sweep #')
ylabel('diff(sweep(1),sweep(n))')
axis tight
box off
export_fig(fullfile(save_path, ['trajectory_Vm_over_sweeps_',date]),plot_format,'-r100');
close

% %%
% classes = unique(qc.class_mat(1:length(cellList),:));
% classes = classes(2:end);
% qc.LP.mat_classes = zeros(length(cellList),length(classes));
% for n = 1:size(qc.LP.class_mat(1:length(cellList),1))
%     for k = 1:length(classes)
%          qc.LP.mat_classes(n,k) = qc.LP.mat_classes(n,k)+length(find(qc.LP.class_mat(n,:)==classes(k)));
%     end
% %     figure('Position',[50 50 600 250]); set(gcf,'color','w');
% %     scatter(1:length(classes),qc.LP.mat_classes(n,:),'k','filled')
% %     xlabel('QC criteria combination')
% %     ylabel('removal count')
% %     xticks(1:length(classes))
% %     xticklabels({classes})
% %     xtickangle(45)
% %     axis tight
% %     ylim([0 25])
% %     export_fig(['D:\test\', ...
% %         cellList(n).name(1:length(cellList(n).name)-4), ...
% %         ' qc removal counts'],plot_format,'-r100');
% %     close
% end
% 
% figure('Position',[50 50 600 800]); set(gcf,'color','w');
% imagesc(qc.mat_classes)
% xlabel('QC criteria combination')
% ylabel('neuron')
% colormap('gray')
% xticks(1:length(classes))
% xticklabels({classes})
% xtickangle(45)
% colorbar
% box off
% 
% figure('Position',[50 50 600 250]); set(gcf,'color','w');
% bar(sum(qc.LP.mat_classes))
% xlabel('QC criteria combination')
% ylabel('count')
% xticks(1:length(classes))
% xticklabels({classes})
% xtickangle(45)
% axis tight
% box off
