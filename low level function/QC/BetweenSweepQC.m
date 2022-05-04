function  QC = BetweenSweepQC(QC,BwSwpMode,PS)

vec = QC.params.Vrest';
vec(QC.params.Vrest'>-40) = NaN;

if BwSwpMode == 1
  if length(vec) > 2                                                         % if one sweep don't analyze
    OrigV = round(trimmean(vec(find(~isnan(vec),8,'first')),33),2);
  end
elseif  BwSwpMode == 2
  OrigV = round(nanmean(vec(1:length(vec))),2); 
else
    QC.pass.betweenSweep(height(QC.params),1) = false;
end
if exist('OrigV')
   outlierVec = find(abs(QC.params.Vrest-OrigV) > PS.BwSweepMax);     
    for v = 1:height(QC.params)
      if ~isnan(QC.params.Vrest(v))  
        QC.params.betweenSweep(v,1) = OrigV - QC.params.Vrest(v);
        if any(ismember(outlierVec, v))
            QC.pass.betweenSweep(v,1) = false;
        else
            QC.pass.betweenSweep(v,1) = true;
        end
      end
    end

    if PS.plot_all >= 1
        ind = 1:height(QC.params) ;
        figure('Position',[50 50 300 250],'visible','off'); set(gcf,'color','w');          % generate figure
        hold on
        scatter(ind,QC.params.Vrest,'k')
        scatter(ind(outlierVec),QC.params.Vrest(outlierVec),'r')
        line([1,height(QC.params)],[OrigV(1),OrigV(1)], ...
                'color','b','linewidth',1,'linestyle','--');
        xlabel('sweepID')
        xticks(1:height(QC.params))
        xticklabels(cellfun(@(v)v(1),regexp(string(QC.params.SweepID( ...
            ~cellfun('isempty',QC.params.SweepID))),'\d*','Match')))
        xtickangle(90)
        ylabel('resting V (mV)')
        axis tight
        ylim([-80 -45])
        exportgraphics(gcf,fullfile(PS.outDest, 'betweenSweeps', ...
            [PS.cellID,' rmp w outliers',PS.pltForm]))                     % save figure
        close
    end
end
end