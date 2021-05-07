%{
processBwSweepsQC
%}
                                                   
LP_vec = qc.LP.V_vec(n,:);                                                 % resting voltages for QC'd sweeps
SP_vec = qc.SP.V_vec(n,:);
vec = [LP_vec(LP_vec~=0), SP_vec(SP_vec~=0)];
ind = [1:length(vec)];
outlierVec = [];
if length(vec) > 2                                                         % if one sweep don't analyze
    diffMinMaxV(n,1) = round(abs(min(vec)-max(vec)),2);                    % diff b/w min & max
        qc.OrigV(n,1) = round(mean(vec(1:3)),2);
        for v = 1:length(vec)
         if vec(v) > qc.OrigV(n,1) + params.BwSweepMax || ...
                vec(v) < qc.OrigV(n,1) - params.BwSweepMax
            qc.sweepID(n,v) = 0;                                           
            qc.sweepBinary(n,v) = 0;                                        
            qc.class_mat{n,v} = [qc.class_mat{n,v}, 12];
            outlierVec = [outlierVec, v];
         end 
         qc.V_vecDelta(n,v) = qc.OrigV(n,1) - vec(v);
        end 
        figure('Position',[50 50 300 250]); set(gcf,'color','w');          % generate figure
        hold on
        scatter(ind,vec,'k')
        scatter(ind(outlierVec),vec(outlierVec),'r')
        line([1,sweepIDcount],[qc.OrigV(n,1),qc.OrigV(n,1)], ...
                'color','b','linewidth',1,'linestyle','--');
        xlabel('sweepID')
        xticks(1:sweepIDcount)
        xticklabels({1:sweepIDcount})
        xtickangle(90)
        ylabel('resting V (mV)')
        axis tight
        ylim([-80 -45])
        export_fig([save_path, ...
            cellList(n).name(1:length(cellList(n).name)-4), ...
            ' rmp w outliers'],plot_format,'-r100');                            % save figure
        close                                                              % close figure

       diffBwSwpQC = sum(sweepBinaryOrig)-sum(qc.sweepBinary(n,:));        % diff b/w number of passed sweeps
       qc_logic_mat{n,11} = diffBwSwpQC;                                   % add diff to QC count matrix
end 
    
clear diffBwSwpQC ind vec outlierVec sweepBinaryOrig
