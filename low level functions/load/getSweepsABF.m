%{
getSweepsABF
%}

listToCorrect = {'M05_SM_A1_C02','M05_SM_A1_C03','M05_SM_A1_C06',...
    'M05_SM_A1_C07','M05_SM_A1_C09','M05_SM_A1_C13','M05_SM_A1_C15',...
    'M06_SM_A1_C01','M06_SM_A1_C06','M06_SM_A1_C07','M06_SM_A1_C08',...
    'M06_SM_A1_C09','M06_SM_A1_C12','M06_SM_A1_C14'};                   % stim times off; 

[d,~,h] = abfload([fileList(k).folder,'/',fileList(k).name], ...
    'sweeps','a','channels','a');                                       % loads data
d = squeeze(d);
LP.fullStruct = 1; SP.fullStruct = 1; RAMP1.fullStruct = 1; NOISE1.fullStruct = 0; HALFMILLISEC.fullStruct = 1; NANOAMP.fullStruct = 1;
LP.name = 'long pulse'; SP.name = 'short pulse'; RAMP1.name = 'ramp'; NOISE1.name = 'noise'; HALFMILLISEC.name = 'ultrashort pulse'; NANOAMP.name = 'nanoamp pulse';

if sum(h.protocolName(end-22:end-4) == ...
        'Monkey_1000 ms step')==19 ...
    || length(h.protocolName)>27 && sum(h.protocolName(end-26:end-4) == ...
    'Monkey_1000 ms steplong')==23

%% meagan diff protocol names for long pulse
    ABF_LP
elseif sum(h.protocolName(end-19:end-4) == 'Monkey_3 ms step')==16 ...
    || sum(h.protocolName(end-20:end-4) == 'Monkey_3 ms step2')==17 ...
    || sum(h.protocolName(end-28:end-4) == 'Monkey_3 ms step_addsweep')==25
    
    ABF_SP
elseif sum(h.protocolName(end-28:end-4) == 'Monkey_25 pA per sec ramp')==25  
    ABF_RAMP1

elseif contains(string(h.protocolName),'noise')    
   noise_files = [noise_files, string(fileList(k).name)]; 
   
elseif contains(string(h.protocolName),'0.5ms')    
  ABF_HALFMILLISEC    

elseif contains(string(h.protocolName),'1nA')    
  ABF_NANOAMP
end
if LPcount == 1
    LP.fullStruct = 0;
end
if SPcount == 1
    SP.fullStruct = 0;
end
if RAMP1count == 1
   RAMP1.fullStruct = 0;  
end
if HALFMILLISECcount == 1
   HALFMILLISEC.fullStruct = 0;  
end    
if NANOAMPcount == 1
   NANOAMP.fullStruct = 0;  
end
