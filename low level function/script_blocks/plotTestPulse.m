function plotTestPulse(TPcells, PS)

shift=mean(cellfun(@range, TPcells))/5;
count = 1;

figure; hold on
if length(TPcells) >100
  step =5 ; 
elseif length(TPcells) >75
  step =4 ;
elseif length(TPcells) >50
  step =3 ;
else
  step =2 ;
end
    
for i=1:step:length(TPcells)
plot(TPcells{i}+shift*count)
count = count+1;
end


title(['Test pulses from 1 to ', num2str(length(TPcells))])
ylabel('Voltage (mV)')
xlabel('samples')
box off

export_fig([PS.outDest, '/TP/', PS.cellID,' TP profile'],PS.pltForm,'-r100');
