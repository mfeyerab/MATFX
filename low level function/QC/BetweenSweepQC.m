function  [BwSweepPass, BwSweepParameter] = BetweenSweepQC(QC_parameter, ...
    BwSweepMode, params)

vec = QC_parameter.Vrest';
vec(QC_parameter.Vrest'>-40) = NaN;
[BwSweepPass, BwSweepParameter] = deal(NaN(height(QC_parameter),1));

if BwSweepMode == 1
  if length(vec) > 2                                                         % if one sweep don't analyze
    OrigV = round(mean(vec(find(~isnan(vec),3,'first'))),2);
  end
elseif  BwSweepMode == 2
  OrigV = round(nanmean(vec(1:length(vec))),2); 
else
    BwSweepPass(height(QC_parameter),1) = false;
end
if exist('OrigV')
   outlierVec = find(abs(QC_parameter.Vrest-OrigV) > params.BwSweepMax);     
    for v = 1:height(QC_parameter)
      if ~isnan(QC_parameter.Vrest(v))  
        BwSweepParameter(v,1) = OrigV - QC_parameter.Vrest(v);
        if any(ismember(outlierVec, v))
            BwSweepPass(v,1) = false;
        else
            BwSweepPass(v,1) = true;
        end
      end
    end

    if params.plot_all == 1
        ind = 1:height(QC_parameter) ;
        figure('Position',[50 50 300 250],'visible','off'); set(gcf,'color','w');          % generate figure
        hold on
        scatter(ind,QC_parameter.Vrest,'k')
        scatter(ind(outlierVec),QC_parameter.Vrest(outlierVec),'r')
        line([1,height(QC_parameter)],[OrigV(1),OrigV(1)], ...
                'color','b','linewidth',1,'linestyle','--');
        xlabel('sweepID')
        xticks(1:height(QC_parameter))
        xticklabels(cellfun(@(v)v(1),regexp(string(QC_parameter.SweepID( ...
            ~cellfun('isempty',QC_parameter.SweepID))),'\d*','Match')))
        xtickangle(90)
        ylabel('resting V (mV)')
        axis tight
        ylim([-80 -45])
        export_fig(fullfile(params.outDest, 'betweenSweeps', ...
            [params.cellID, ' rmp w outliers']),params.plot_format,'-r100');                            % save figure
        close
    end
end
end