function plotSanityChecks(QC, PS, ICsummary, n, ICEtab)

Qvec = QC.pass.QC_total_pass==1;
QC.testpulse = QC.testpulse(QC.params.TP==1 & Qvec);

if ~isempty(QC.testpulse)
    QC.testpulse(cellfun(@isempty, QC.testpulse)) = [];
    shift=mean(cellfun(@range, QC.testpulse))/3;
    count = 0;

    figure('visible','off'); hold on
    if length(QC.testpulse) >100
      step =5 ; 
    elseif length(QC.testpulse) >75
      step =4 ;
    elseif length(QC.testpulse) >50
      step =3 ;
    else
      step =2 ;
    end

    colorVec = jet(length(QC.testpulse)); 
    for i=1:step:length(QC.testpulse)
    plot(QC.testpulse{i}-mean(QC.testpulse{i}(1:250))+shift*count,'Color',colorVec(i,:))
    count = count+1;
    end

    title(['Test pulses from 1 to ', num2str(length(QC.testpulse))])
    subtitle(['R_i_n = ', num2str(round(ICsummary.RinHD(n))), ' M\Omega',...
        ' tau = ', num2str(ICsummary.tau(n)), ' ms' ])
    ylabel('Voltage trace (mV)')
    xlabel('samples')
    box off
    F=getframe(gcf);
    exportgraphics(gcf,fullfile(PS.outDest, 'TP', [PS.cellID,' TP profile','.pdf']))
end
%% Stimulus Onset LP
LPvec = contains(string(ICEtab.vectordata.Map('protocol_type').data.load), 'LP');                             
if any(all([Qvec, LPvec],2))

figure('visible','off'); hold on
for s=1:height(QC.pass)
    if LPvec(s)&& Qvec(s)
       plot(QC.VStimOn{s}-mean(QC.VStimOn{s}(1:15)))
    end
end
I = ICEtab.stimuli.vectordata.values{1}.data.load(...
                         find(all([Qvec, LPvec],2)));    
title(['Stimulus onset ', PS.cellID, ' I= ',...
    num2str(min(I)), ' to ', num2str(max(I))]);
ylabel('Voltage trace (mV)')
ylim([-10 15])
ylabel('Voltage (mV)')
xlabel('samples')
box off

if ~isempty(PS.rheoSwpSers) && checkVolts(PS.rheoSwpSers.data_unit) && ...
                 string(PS.rheoSwpSers.description) ~= "PLACEHOLDER"
  ylim([-0.01 0.015])
  ylabel('Voltage (V)')
end  
end

F=getframe(gcf);
imwrite(F.cdata,fullfile(PS.outDest, 'TP', [PS.cellID,' StimOnLP','.png']))
%% Stimulus Onset SP

SPvec = contains(string(ICEtab.vectordata.Map('protocol_type').data.load), 'SP');                             
                          
if any(all([Qvec, SPvec],2))
    I = ICEtab.stimuli.vectordata.values{1}.data.load(...
                             find(all([Qvec, SPvec],2)));
    figure('visible','off'); hold on
    for s=1:height(QC.pass)
        if SPvec(s)&& Qvec(s) && length(QC.VStimOn)>=s
           plot(QC.VStimOn{s}-mean(QC.VStimOn{s}(1:15)))
        end
    end
    
    title(['Stimulus onset ', PS.cellID, ' I= ',...
        num2str(min(I)), ' to ', num2str(max(I))]);
    ylabel('Voltage trace (mV)')
    ylim([-10 15])
    ylabel('Voltage (mV)')
    xlabel('samples')
    box off
    
    if ~isempty(PS.rheoSwpSers) && checkVolts(PS.rheoSwpSers.data_unit) && ...
                     string(PS.rheoSwpSers.description) ~= "PLACEHOLDER"
      ylim([-0.01 0.015])
      ylabel('Voltage (V)')
    end  
    
    F=getframe(gcf);
    imwrite(F.cdata,fullfile(PS.outDest, 'TP', [PS.cellID,' StimOnSP','.png']))
end
