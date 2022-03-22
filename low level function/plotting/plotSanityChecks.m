function plotSanityChecks(QC, PS, ICsummary, n)

QC.testpulse(cellfun(@isempty, QC.testpulse)) = [];
shift=mean(cellfun(@range, QC.testpulse))/3;
count = 0;

figure; hold on
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

exportgraphics(gcf,fullfile(PS.outDest, 'TP', [PS.cellID,' TP profile','.png']))

%%
figure; hold on
for s=1:height(QC.pass)
    if contains(QC.pass.Protocol(s), 'LP')
       plot(QC.VStimOn{s}-mean(QC.VStimOn{s}(1:15)))
    end
end

title(['Stimulus onset ', PS.cellID])
ylabel('Voltage trace (mV)')

ylim([-10 15])
ylabel('Voltage (mV)')
xlabel('samples')
box off

if ~isempty(PS.rheoSwpSers.data) && checkVolts(PS.rheoSwpSers.data_unit) && ...
                 string(PS.rheoSwpSers.description) ~= "PLACEHOLDER"
  ylim([-0.01 0.015])
  ylabel('Voltage (V)')
end  


exportgraphics(gcf,fullfile(PS.outDest, 'TP', [PS.cellID,' StimOn','.png']))
