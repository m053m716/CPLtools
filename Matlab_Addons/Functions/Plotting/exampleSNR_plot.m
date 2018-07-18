load('P:\Rat\ComplexBoxHealthyPilotStudy\Dex_Coating\R18-87\R18-87_2018_07_16_1\R18-87_2018_07_16_1_wav-neg50_CAR_Spikes\R18-87_2018_07_16_1_ptrain_P1_Ch_022.mat')
load('P:\Rat\ComplexBoxHealthyPilotStudy\Dex_Coating\R18-87\R18-87_2018_07_16_1\R18-87_2018_07_16_1_wav-neg50_SPC_CAR_Sorted\R18-87_2018_07_16_1_sort_P1_Ch_022.mat')
idx = class == 2;
x = spikes(idx,:);
x = x(1:15,:);
rms_vals = [10,30,60];

plotExampleSNR_Spikes(rms_vals,x);