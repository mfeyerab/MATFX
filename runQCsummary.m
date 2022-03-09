function runQCsummary(path)

p = loadParams;tables = struct();
files = dir(fullfile(path,'QC'));
files = {files(contains({files.name}, 'parameter')).name};

for c = 1:length(files)
   tables.(['T', num2str(c)]) = readtable(fullfile(path,'QC', files{c}));
end

cellTabs = fieldnames(tables);

%%
subplot(1,4,1)
hold on
for n = 1:length(cellTabs)
    plot([1 2],[tables.(['T', num2str(n)]).ltRMSE_pre(find(...
        ~contains(tables.(['T', num2str(n)]).Protocol,"unknown"),1,'first')) ...
        tables.(['T', num2str(n)]).ltRMSE_post(find(~contains(...
        tables.(['T', num2str(n)]).Protocol,"unknown"),1,'first'))],'k','linewidth',0.25)
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('1st sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2.25])
xticklabels({'pre','post'})
subplot(1,4,2)
hold on
for n = 1:length(cellTabs)
    Idx = find(~contains(tables.(['T', num2str(n)]).Protocol,"unknown"));    
    plot([1 2],[tables.(['T', num2str(n)]).ltRMSE_pre(Idx(5)) ...
        tables.(['T', num2str(n)]).ltRMSE_post(Idx(5))],'k','linewidth',0.25)
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('5th sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2.25])
xticklabels({'pre','post'})
subplot(1,4,3)
hold on
for n = 1:length(cellTabs)
    Idx = find(~contains(tables.(['T', num2str(n)]).Protocol,"unknown"));    
    plot([1 2],[tables.(['T', num2str(n)]).ltRMSE_pre(Idx(10)) ...
        tables.(['T', num2str(n)]).ltRMSE_post(Idx(10))],'k','linewidth',0.25)
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('10th sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2.25])
xticklabels({'pre','post'})
subplot(1,4,4)
hold on
for n = 1:length(cellTabs)
    Idx = find(~contains(tables.(['T', num2str(n)]).Protocol,"unknown"));  
    if length(Idx)>=20
    plot([1 2],[tables.(['T', num2str(n)]).ltRMSE_pre(Idx(20)) ...
        tables.(['T', num2str(n)]).ltRMSE_post(Idx(20))],'k','linewidth',0.25)
    end
end
plot([1 2],[p.RMSElt p.RMSElt],'r-.','linewidth',1)
xlabel('20th sweep')
ylabel('RMS (long term)')
xticks(1:2)
ylim([0 2.25])
xticklabels({'pre','post'})

exportgraphics(gcf,fullfile(path, 'QC', 'QCpreVsPost.png'))

%%
T=table(); I=[];BB=[];CC=[];
for t = 1:length(cellTabs)
    T = [T; tables.(['T', num2str(t)])];   
    I = [I; max(tables.(['T', num2str(t)]).holdingI)];
    BB = [BB;max(tables.(['T', num2str(t)]).bridge_balance_abs)];
    CC = [CC;max(tables.(['T', num2str(t)]).CapaComp)];
end


figure('Position',[50 50 1600 900]); set(gcf,'color','w');
subplot(2,4,1)
histogram(T.ltRMSE_pre(~isnan(T.ltRMSE_pre)),[0:0.1:2],'FaceColor','k','Normalization','probability');
line([p.RMSElt,p.RMSElt],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('lt RMS pre-stim')
    axis tight
    box off
subplot(2,4,2)
histogram(T.ltRMSE_post(~isnan(T.ltRMSE_post)),[0:0.1:2],'FaceColor','k','Normalization','probability');
line([p.RMSElt,p.RMSElt],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('lt RMS post-stim')
    axis tight
    box off
subplot(2,4,3)
histogram(T.stRMSE_pre(~isnan(T.stRMSE_pre)),[0:0.025:0.5],'FaceColor','k','Normalization','probability');
line([p.RMSEst,p.RMSEst],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('st RMS pre-stim')
    axis tight
    box off
subplot(2,4,4)
histogram(T.stRMSE_post(~isnan(T.stRMSE_post)),[0:0.025:0.5],'FaceColor','k','Normalization','probability');
line([p.RMSEst,p.RMSEst],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('st RMS post-stim')
    axis tight
    box off
    
subplot(2,4,5)
histogram(T.diffVrest(~isnan(T.diffVrest)),[0:0.25:10],'FaceColor','k','Normalization','probability');
line([p.maxDiffBwBeginEnd,p.maxDiffBwBeginEnd],[0,0.4], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('V rest pre vs post')
    axis tight
    box off
    
subplot(2,4, 6)
histogram(I,[0:5:120],'FaceColor','k','Normalization','probability');
line([p.holdingI,p.holdingI],[0,0.6], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('max holding I')
    axis tight
    box off
    
subplot(2,4,7)
histogram(BB,[0:1:25],'FaceColor','k','Normalization','probability');
line([p.bridge_balance,p.bridge_balance],[0,0.3], ...
            'color','r','linewidth',1,'linestyle','--');
    ylabel('probability')
    xlabel('max bridge ballance')
    axis tight
    box off
    
 subplot(2,4,8)
histogram(CC,[0:0.4:10],'FaceColor','k','Normalization','probability');
    ylabel('probability')
    xlabel('max capacitance neutralization')
    axis tight
    box off   
    
exportgraphics(gcf,fullfile(path, 'QC', 'QChistograms.png'))
      
%% Scatter plots
% figure('Position',[50 50 900 200]); set(gcf,'color','w');
% subplot(1,4,1)
% scatter(qc_restVpre(1:281,1),qc_restVpost(1:281,1),10,'filled','k')
% xlabel('V_r_e_s_t pre')
% ylabel('V_r_e_s_t post')
% xlim([-100 -20])
% ylim([-100 -20])
% box off
% subplot(1,4,2)
% scatter(qc_restVpre(1:281,6),qc_restVpost(1:281,6),10,'filled','k')
% xlabel('V_r_e_s_t pre')
% ylabel('V_r_e_s_t post')
% xlim([-100 -20])
% ylim([-100 -20])
% box off
% subplot(1,4,3)
% scatter(qc_restVpre(1:281,12),qc_restVpost(1:281,12),10,'filled','k')
% xlabel('V_r_e_s_t pre')
% ylabel('V_r_e_s_t post')
% xlim([-100 -20])
% ylim([-100 -20])
% box off
% subplot(1,4,4)
% scatter(qc_restVpre(1:281,20),qc_restVpost(1:281,20),10,'filled','k')
% xlabel('V_r_e_s_t pre')
% ylabel('V_r_e_s_t post')
% xlim([-100 -20])
% ylim([-100 -20])
% box off

%%
files = dir(fullfile(path,'QC'));
files = {files(contains({files.name}, 'pass')).name};
logic_matrix= zeros(length(files),11);

for c = 1:length(files)
   tables.(['T', num2str(c)]) = readtable(fullfile(path,'QC', files{c}));
   NrSweeps = sum(~any(ismissing(tables.(['T', num2str(c)])(:,4:12)),2));
   logic_matrix(c,:) = 1-(sum(table2array(tables.(['T', num2str(c)])(:,4:14)),'omitnan')/NrSweeps);
end

figure('Position',[0 0 300 1000]); 
imagesc(logic_matrix);set(gcf,'color','w');
xlabel('QC criteria')
xticks(1:11)
xticklabels({'stRMSE pre' 'stRMSE post' 'ltRMSE pre' 'ltRMSE post' 'diffVrest' ...
    'Vrest abs' 'holdingI' 'betweenSweep' 'bridge_balance_abs' ...
    'bridge_balance_rela' 'bad spikes'})
xtickangle(45)
colorbar
colormap('gray');
box off
exportgraphics(gcf,fullfile(path, 'QC', 'QCheatmap.png'))
%%
end