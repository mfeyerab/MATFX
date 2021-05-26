function [cellFile, ICsummary, RheoSweepSeries, sagSweepSeries, RheoSweepTablePos, SagSweepTablePos] = ...
    LPsummary(cellFile, ICsummary, cellNr, params)

%{
summary LP analysis
%}

%% 

SweepPathsAll = {cellFile.general_intracellular_ephys_sweep_table.series.data.path};

IdxPassedSweeps = find(...
    cellFile.general_intracellular_ephys_sweep_table.vectordata.map(...
                       'QC_total_pass').data);  

Sweepnames = cellfun(@(a) str2double(a), regexp(SweepPathsAll,'\d*','Match'));
                   
NamesPassedSweeps = unique(Sweepnames(IdxPassedSweeps));
IdxPassedSweeps = IdxPassedSweeps(IdxPassedSweeps < ...
    length(cellFile.processing.map('QC parameter').dynamictable.values{1}.vectordata.values{1}.data));

%% subthreshold summary parameters                              
                                     
ICsummary.resistance(cellNr,1) = inputResistance(...
         cellFile.processing.map('subthreshold parameters').dynamictable,NamesPassedSweeps);              % resistance based on steady state

ICsummary.Vrest(cellNr,1) =  nanmean(...
    cellFile.processing.map('QC parameter'...
    ).dynamictable.values{1}.vectordata.map('Vrest').data(IdxPassedSweeps));                            % resting membrane potential
        
tau_vec = [];

for s = 1:cellFile.processing.map('subthreshold parameters').dynamictable.Count
    number = regexp(...
       cellFile.processing.map('subthreshold parameters').dynamictable.keys{s},'\d*','Match');
    
    if ismember(str2num(cell2mat(number)), NamesPassedSweeps) && ...
         ~isnan(cellFile.processing.map('subthreshold parameters' ...
           ).dynamictable.values{s}.vectordata.values{11}.data) && ...
              cellFile.processing.map('subthreshold parameters' ...
                 ).dynamictable.values{s}.vectordata.values{11}.data
   
           tau_vec =  [tau_vec, ...
               cellFile.processing.map('subthreshold parameters').dynamictable.values{s}.vectordata.values{10}.data];
    end
end    

ICsummary.tau(cellNr,1) = mean(tau_vec);
        
%% Maximum firing rate and  median instantanous rate

if cellFile.processing.isKey('All_ISIs')
  ICsummary.maxFiringRate(cellNr,1) = max(diff(...
      cellFile.processing.map('All_ISIs'...
      ).dynamictable.values{1}.vectorindex.values{1}.data));
  ICsummary.medInstaRate(cellNr,1) = 1000/nanmedian(...
      cellFile.processing.map('All_ISIs'...
      ).dynamictable.values{1}.vectordata.values{1}.data);
else  
  ICsummary.maxFiringRate(cellNr,1) = 0;
  ICsummary.medInstaRate(cellNr,1) = 0;
end  

%% finding sag sweep
sagSweep = [];
runs = 1;
PrefeSagAmps = [-90, -70, -110];
sagPos = [];
SagSweepTablePos = [];

while isempty(sagSweep) && runs < 4
    for s = 1:cellFile.processing.map('subthreshold parameters').dynamictable.Count 
        
      number = regexp(cellFile.processing.map('subthreshold parameters' ...
             ).dynamictable.keys{s},'\d*','Match');
         
      if ismember(str2num(cell2mat(number)), NamesPassedSweeps) && ...
           round(cellFile.processing.map('subthreshold parameters'...
           ).dynamictable.values{s}.vectordata.values{2}.data) == PrefeSagAmps(runs)  
         sagSweep = cellFile.processing.map('subthreshold parameters').dynamictable.values{s};
         sagPos = s;
      end    
    end
    if ~isempty(sagPos)
      SagSweepTablePos = find(strcmp(SweepPathsAll,...
                ['/acquisition/',cellFile.processing.map(...
                  'subthreshold parameters').dynamictable.keys{sagPos}]));
    end
    runs= runs +1;
end

if ~isempty(sagSweep)
    ICsummary.sag(cellNr,1) = sagSweep.vectordata.values{8}.data;
    ICsummary.sag_ratio(cellNr,1) = sagSweep.vectordata.values{9}.data;
    ICsummary.sagAmp(cellNr,1) = sagSweep.vectordata.values{2}.data;
    sagSweepSeries = cellFile.resolve(SweepPathsAll(SagSweepTablePos));
else
    sagSweepSeries = [];
end

%% find rheobase sweeps and parameters of first spike
RheoSweep = [];            
RheoSweepTablePos = [];

for s = 1:cellFile.processing.map('AP wave').dynamictable.Count            %% loop through all Sweeps with spike data
    number = regexp(...
        cellFile.processing.map('AP wave').dynamictable.keys{s},'\d*','Match');
    if ismember(str2num(cell2mat(number)), NamesPassedSweeps)                  %% if sweep passed the QC
        
       if (isempty(RheoSweep) && length(cellFile.processing.map('AP wave' ...
            ).dynamictable.values{s}.vectordata.values{1}.data) ...
               <= params.maxRheoSpikes) || (~isempty(RheoSweep)  && ...                        %% if the sweep has less 
               length(cellFile.processing.map('AP wave').dynamictable.values{...
                 s}.vectordata.values{1}.data) < ...
                     length(RheoSweep.vectordata.values{1}.data))                      
   
          RheoSweep = cellFile.processing.map('AP wave').dynamictable.values{s};
          RheoPos = s;
       end
    end
end    
                          
if ~isempty(RheoSweep)
    
    RheoSweepTablePos = find(endsWith(...
        SweepPathsAll,cellFile.processing.map('AP wave').dynamictable.keys{RheoPos}));
    
    ICsummary.Rheo(cellNr,1) = ...
        unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{...
        4}.data(RheoSweepTablePos));
    
    ICsummary.latency(cellNr,1) = RheoSweep.vectordata.map('thresholdTime').data(1) - ...
        unique(cellFile.general_intracellular_ephys_sweep_table.vectordata.values{3}.data(RheoSweepTablePos))...
        *1000/cellFile.resolve(SweepPathsAll(RheoSweepTablePos( ...
        contains(SweepPathsAll(RheoSweepTablePos),'acquisition')))).starting_time_rate;
   
    ICsummary.widthTP_LP(cellNr,1) = RheoSweep.vectordata.map('fullWidthTP').data(1);
    ICsummary.peakLP(cellNr,1) = RheoSweep.vectordata.map('peak').data(1);
    ICsummary.thresholdLP(cellNr,1) = RheoSweep.vectordata.map('fast_trough').data(1);
    ICsummary.fastTroughLP(cellNr,1) = RheoSweep.vectordata.map('threshold').data(1);
    ICsummary.slowTroughLP(cellNr,1) = RheoSweep.vectordata.map('slow_trough').data(1);
    ICsummary.peakUpStrokeLP(cellNr,1) = RheoSweep.vectordata.map('peakUpStroke').data(1);
    ICsummary.peakDownStrokeLP(cellNr,1) = RheoSweep.vectordata.map('peakDownStroke').data(1);
    ICsummary.peakStrokeRatioLP(cellNr,1) = RheoSweep.vectordata.map('peakStrokeRatio').data(1);   
    ICsummary.heightTP(cellNr,1) = RheoSweep.vectordata.map('heightTP').data(1);
   
    RheoSweepSeries =  cellFile.resolve(SweepPathsAll(RheoSweepTablePos(...
            contains(SweepPathsAll(RheoSweepTablePos),'acquisition'))));

else
    RheoSweepSeries = [];
end




%% Hero sweep selection
%             k = [];                                                         % resetting k for indexing sweeps
%             flag = 0;                                                       % variable to fire the if condition in while loop only one time
%             if spCheck == 1             
%                 % global spiketrain parameters
%                 % obtain the median ISI of all suprathreshold sweeps
% 
%                 % pICsummaryking "Hero sweep" for more spike train parameters per cell
%                 [~,k] = min(abs(double(B)-(ICsummary.rheobaseLP(n,1)*1.5)));        % hero sweep is 1.5x Rheobase
%                 if k > 0                                                    % if there is a sweep 1.5x Rheobase
%                     while ~ismember(qc.sweepID(n,k),k) ||    ...            % Making sure the k sweep meets other necessary conditions
%                             ~isfield(a.LP.stats{k,1},'burst')  ||   ...     % It has spike train analysis fields like burst
%                             a.LP.sweepAmps(k) <= ICsummary.rheobaseLP(n,1) || ...  % It is not lower than the rheobase
%                                 a.LP.sweepAmps(k) > 3*ICsummary.rheobaseLP(n,1)        % It is not more than triple the rheobase 
%                         k = k - 1;  
%                         if k == 0 && flag == 0
%                             [~, k] = min(abs(double(B) - ...
%                                 (ICsummary.rheobaseLP(n,1)*3)));                   % hero sweep is 8x Rheobase sweep
%                             flag = 1;                                       % set if condition to fire
%                         end
%                         if k == 0 && flag == 1; break; end
%                     end  
%                 end
%                 if length(k) > 1
%                     ICsummary.rate_1sHero(n,1) = mean(a.LP.stats{k,1}.meanFR1000);
%                     ICsummary.burst_hero(n,1) = mean(train_burst(n,k(1:length(k))));
%                     ICsummary.delay_hero(n,1) =   mean(train_delay(n,k(1:length(k))));
%                     ICsummary.latency_hero(n,1) = mean(train_latency(n,k(1:length(k))));
%                     ICsummary.cv_ISI(n,1) =   mean(train_cv_ISI(n,k(1:length(k))));
%                     ICsummary.adaptation1(n,1) = mean(train_adaptation1(n,k(1:length(k))));
%                     ICsummary.adaptation2(n,1) = mean(train_adaptation2(n,k(1:length(k))));
%                     ICsummary.hero_amp(n,1) = unique(a.LP.sweepAmps(k));       
%                 elseif k == 1
%                     ICsummary.rate_1sHero(n,1) = a.LP.stats{k,1}.meanFR1000;
%                     ICsummary.burst_hero(n,1) =  a.LP.stats{k, 1}.burst;
%                     ICsummary.delay_hero(n,1) =   unique(a.LP.stats{k, 1}.delay);
%                     ICsummary.latency_hero(n,1) = unique(a.LP.stats{k, 1}.latency);
%                     ICsummary.cv_ISI(n,1) =   a.LP.stats{k, 1}.cvISI ;  
%                     ICsummary.adaptation1(n,1) = a.LP.stats{k, 1}.adaptIndex; 
%                     ICsummary.adaptation2(n,1) = a.LP.stats{k, 1}.adaptIndex2; 
%                     ICsummary.hero_amp(n,1) = a.LP.sweepAmps(k);
%                 end      
%             end