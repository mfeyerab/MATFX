function  [BwSweepPass, BwSweepParameter] = BetweenSweepQC(QC_parameter, BwSweepMode, params)

vec = (QC_parameter.Vrest)';
BwSweepPass = NaN(length(vec),1);
BwSweepParameter = NaN(length(vec),1);

if BwSweepMode == 1
  if length(vec) > 2                                                         % if one sweep don't analyze
    OrigV = round(mean(vec(find(~isnan(vec),3,'first'))),2);
        for v = 1:length(vec)
          if ~isnan(vec(v))   
             if vec(v) > OrigV + params.BwSweepMax || ...
                    vec(v) < OrigV - params.BwSweepMax            
                BwSweepPass(v,1) = false;                                                    
             else
                BwSweepPass(v,1) = true;   
             end 
             BwSweepParameter(v,1) = OrigV - vec(v);
          end 
        end
  end 
elseif  BwSweepMode == 2
        
       if length(vec) < 20
         stdOrigV = round(nanstd(vec(1:length(vec))),2);                                 % s.d. original voltages
         meanOrigV = round(nanmean(vec(1:length(vec))),2); 
       else      
         stdOrigV = round(nanstd(vec(1:20)),2);                                 % s.d. original voltages
         meanOrigV = round(nanmean(vec(1:20)),2);  
       end
        outlierVec = find(abs(vec-meanOrigV) > ...
                stdOrigV*1.75);
     
        for v = 1:length(vec)   
            if ~isnan(vec(v))  
                BwSweepParameter(v,1) = meanOrigV - vec(v);
                if v == outlierVec
                    BwSweepPass(v,1) = false;
                else
                    BwSweepPass(v,1) = true;
                end
            end
        end
   
%         figure('Position',[50 50 300 250]); set(gcf,'color','w');          % generate figure
%         hold on
%         scatter(ind,vec,'k')
%         scatter(ind(outlierVec),vec(outlierVec),'r')
%         line([1,sweepIDcount],[qc.OrigV(n,1),qc.OrigV(n,1)], ...
%                 'color','b','linewidth',1,'linestyle','--');
%         xlabel('sweepID')
%         xticks(1:sweepIDcount)
%         xticklabels({1:sweepIDcount})
%         xtickangle(90)
%         ylabel('resting V (mV)')
%         axis tight
%         ylim([-80 -45])
%         export_fig([save_path, ...
%             cellList(n).name(1:length(cellList(n).name)-4), ...
%             ' rmp w outliers'],plot_format,'-r100');                            % save figure
%         close       
end