function runQCsummary(path)

p = loadParams;tables = struct();
files = dir(fullfile(path,'QC'));
files = {files(contains({files.name}, 'parameter')).name};

for c = 1:length(files)
   tables.(['T', num2str(c)]) = readtable(fullfile(path,'QC', files{c}));
   if any(tables.(['T', num2str(c)]).bridge_balance_abs > 100) 
       tables.(['T', num2str(c)]).bridge_balance_abs = tables.(['T', num2str(c)]).bridge_balance_abs/1e6;
   end
   if any(tables.(['T', num2str(c)]).CapaComp <1 & tables.(['T', num2str(c)]).CapaComp~=0)
       tables.(['T', num2str(c)]).CapaComp = tables.(['T', num2str(c)]).CapaComp*1e12;
   end
end

cellTabs = fieldnames(tables);

%%
figure
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
RigTags = unique(cellfun(@(x) x(8:9), files,'UniformOutput',false));
RigTags{length(RigTags)+1} = 'Total';
RigQC = struct();

for r=1:length(RigTags)
    RigQC.(char(RigTags(r))) = table();
    RigQC.([char(RigTags(r)),'_I']) = [];
    RigQC.([char(RigTags(r)),'_BB']) = [];
    RigQC.([char(RigTags(r)),'_CC']) = [];
end

for t = 1:length(cellTabs)   
 RigQC.Total = [RigQC.Total; tables.(['T', num2str(t)])];
 RigQC.Total_I = [RigQC.Total_I; max(tables.(['T', num2str(t)]).holdingI)];
 RigQC.Total_BB =[RigQC.Total_BB; max(tables.(['T', num2str(t)]).bridge_balance_abs)];
 RigQC.Total_CC = [RigQC.Total_CC; max(tables.(['T', num2str(t)]).CapaComp)];
 RigQC.(files{t}(8:9)) = [RigQC.(files{t}(8:9)); tables.(['T', num2str(t)])];   
 RigQC.([files{t}(8:9), '_I']) = [RigQC.([files{t}(8:9), '_I']); ...
                                max(tables.(['T', num2str(t)]).holdingI)];
 RigQC.([files{t}(8:9), '_BB']) = [RigQC.([files{t}(8:9), '_BB']); ...
                                max(tables.(['T', num2str(t)]).bridge_balance_abs)];
 RigQC.([files{t}(8:9), '_CC']) = [RigQC.([files{t}(8:9), '_CC']); ...
                                 max(tables.(['T', num2str(t)]).CapaComp)];
end

for r=1:length(RigTags)
    
figure('Position',[50 50 1600 900]); set(gcf,'color','w');
subplot(3,4,1)
histogram(RigQC.(char(RigTags(r))).ltRMSE_pre(~isnan(RigQC.(char(RigTags(r))).ltRMSE_pre)),[0:0.1:2],'FaceColor','k','Normalization','probability');
l1 = line([p.RMSElt,p.RMSElt],[0,0.4],'color','r','linewidth',1,'linestyle','--');
l2 = line([0.5,0.5],[0,0.4],'color','b','linewidth',1,'linestyle','--');
ylabel('probability')
xlabel('lt RMS pre-stim')
axis tight
box off
legend([l1, l2],{'CurrentRun', 'AIBS'}) 
  
subplot(3,4,2)
histogram(RigQC.(char(RigTags(r))).ltRMSE_post(~isnan(RigQC.(char(RigTags(r))).ltRMSE_post)),[0:0.1:2],'FaceColor','k','Normalization','probability');
l1 = line([p.RMSElt,p.RMSElt],[0,0.4],'color','r','linewidth',1,'linestyle','--');
l2 = line([0.5,0.5],[0,0.4],'color','b','linewidth',1,'linestyle','--');
ylabel('probability')
xlabel('lt RMS post-stim')
axis tight
box off
legend([l1, l2],{'CurrentRun', 'AIBS'}) 

subplot(3,4,3)
histogram(RigQC.(char(RigTags(r))).stRMSE_pre(~isnan(RigQC.(char(RigTags(r))).stRMSE_pre)),[0:0.025:0.4],'FaceColor','k','Normalization','probability');
l1 = line([p.RMSEst,p.RMSEst],[0,0.7],'color','r','linewidth',1,'linestyle','--');
l2 = line([0.07,0.07],[0,0.7],'color','b','linewidth',1,'linestyle','--');
ylabel('probability')
xlabel('st RMS pre-stim')
axis tight
box off
legend([l1, l2],{'CurrentRun', 'AIBS'}) 
    
subplot(3,4,4)
histogram(RigQC.(char(RigTags(r))).stRMSE_post(~isnan(RigQC.(char(RigTags(r))).stRMSE_post)),[0:0.025:0.4],'FaceColor','k','Normalization','probability');
l1 = line([p.RMSEst,p.RMSEst],[0,0.7],'color','r','linewidth',1,'linestyle','--');
l2 = line([0.07,0.07],[0,0.7],'color','b','linewidth',1,'linestyle','--');
ylabel('probability')
xlabel('st RMS post-stim')
axis tight
box off
legend([l1, l2],{'CurrentRun', 'AIBS'}) 
    
subplot(3,4,5)
histogram(RigQC.(char(RigTags(r))).diffVrest(~isnan(RigQC.(char(RigTags(r))).diffVrest)),[0:0.25:7],'FaceColor','k','Normalization','probability');
l1 = line([p.maxDiffBwBeginEnd,p.maxDiffBwBeginEnd],[0,0.4],'color','r','linewidth',1,'linestyle','--');
l2 = line([1,1],[0,0.4],'color','b','linewidth',1,'linestyle','--');
ylabel('probability')
xlabel('V rest pre vs post')
axis tight
box off
legend([l1, l2],{'CurrentRun', 'AIBS'}) 
    
subplot(3,4, 6)
histogram(RigQC.([char(RigTags(r)),'_I']),[0:5:120],'FaceColor','k','Normalization','probability');
l1 = line([p.holdingI,p.holdingI],[0,0.7],'color','r','linewidth',1,'linestyle','--');
l2 = line([100,100],[0,0.7],'color','b','linewidth',1,'linestyle','--');
ylabel('probability')
xlabel('max holding I (pA)')
axis tight
box off
legend([l1, l2],{'CurrentRun', 'AIBS'}) 

subplot(3,4,7)
histogram(RigQC.(char(RigTags(r))).Vrest(~isnan(RigQC.(char(RigTags(r))).Vrest)),[-90:2:-42],'FaceColor','k','Normalization','probability');
l1 = line([p.maximumRestingPot,p.maximumRestingPot],[0,0.4],'color','r','linewidth',1,'linestyle','--');
ylabel('probability')
xlabel('Vrest (mV)')
axis tight
box off
legend([l1],{'CurrentRun'}) 

subplot(3,4,8)
histogram(RigQC.(char(RigTags(r))).betweenSweep(~isnan(RigQC.(char(RigTags(r))).betweenSweep)),[-6:0.5:6],'FaceColor','k','Normalization','probability');
l1 = line([p.BwSweepMax,p.BwSweepMax],[0,0.4],'color','r','linewidth',1,'linestyle','--');
l1 = line([-p.BwSweepMax,-p.BwSweepMax],[0,0.4],'color','r','linewidth',1,'linestyle','--');
ylabel('probability')
xlabel('distance to target (mV)')
axis tight
box off
legend([l1],{'CurrentRun'}) 

subplot(3,4,9)
histogram(RigQC.([char(RigTags(r)),'_BB']),[0:1:25],'FaceColor','k','Normalization','probability');
l1 = line([p.bridge_balance,p.bridge_balance],[0,0.3], 'color','r','linewidth',1,'linestyle','--');
l2 = line([20,20],[0,0.3], 'color','b','linewidth',1,'linestyle','--');
ylabel('probability')
xlabel('max bridge ballance')
axis tight
box off
legend([l1, l2],{'CurrentRun', 'AIBS'}) 
    
subplot(3,4,10)
histogram(RigQC.([char(RigTags(r)),'_CC']),[0:0.4:10],'FaceColor','k','Normalization','probability');
    ylabel('probability')
    xlabel('max capacitance neutralization')
    axis tight
    box off   
    
exportgraphics(gcf,fullfile(path, 'QC', [char(RigTags(r)), 'histograms.png']))
end

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