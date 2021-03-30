         if sum(sum(spqcmatn))>0                                             % figure of spike-wise QC (sweeps X criteria)
            figure('Position',[50 50 300 300]); set(gcf,'color','w');
            imagesc(spqcmatn)
            box off
            colorbar
            colormap('gray')
            xticks(1:10)
            xticklabels({'interval','null dV/dt','dV/dt<5mV/ms', ...
                'threshold>-20mV','t2pN(B)<35(45)mV','t2pT>1.5ms','interval Re', ...
                'null dV/dt Re','trough>-30mV','<30% Rheobase height'})
            xtickangle(45)
            ylabel('current input (pA)')
            yticks(1:size(spqcmatn,1))
            yticklabels({a.LP.sweepAmps})
            export_fig(['D:\my\genpath\',cellID,' spike QC (sweeps by critiera)', a.(protocols{p}).name],'-pdf','-r100');
            close
        end 
        if exist('spqcmatnbinaryid','var')                                  % figure of spike-wise QC (sweeps X spikes)
            figure('Position',[50 50 300 250]); set(gcf,'color','w');
            imagesc(spqcmatnbinaryid)
            box off
            colormap('gray')
            xlabel('spike # (white==passes QC)')
            ylabel('current input (pA)')
            yticks(1:length(k_len_spID))
            yticklabels({k_len_spID})
            export_fig(['D:\my\genpath\',cellID,' spike QC (sweeps by spike binary)', a.(protocols{p}).name],'-pdf','-r100');
            close
            clear spqcmatnbinaryid spqcmatnbinary k_len_spID
        end