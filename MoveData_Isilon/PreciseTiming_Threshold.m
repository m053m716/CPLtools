%% Version  1    on    11.4.15 
%% Kelly RM     kellrodriguez@ku.edu
%% OFFline threshold detection (Non adaptive version)
%%modified by Alberto Averna 11/02/16----> Median 
function [thresh] = PreciseTiming_Threshold(data_in,fs,multCoeff)

%% Center data at mean
    data_temp=data_in(data_in~=0);
    data_Mc=data_in-mean(data_temp);
    data_Mc(data_in==0)=0;
    
%%    
nSamples = length(data_Mc);
nWin = 120;
winDur = 100*1e-3; % [msec]
winDur_samples = floor(winDur.*fs);
if nSamples < (nWin + winDur_samples)
    thresh = [];
    return
end

startSample = 1:(round(nSamples/nWin)):nSamples;
endSample = startSample+winDur_samples-1;
th = 100;

if isempty(endSample)
    thresh = [];
    return
end

for ii = 1:nWin
% Here we exclude windows containing 0'S due to artifact rejection
% Since not all artifact may have been removed
% These artifacts would increase threshold greatly
    
    endSample(ii)   =   min(endSample(ii),nSamples)     ;
    curr_W          =   data_Mc(startSample(ii):endSample(ii)) ;

    if any(curr_W   ==  0)
         continue;
    end
     
    thThis(ii) = std(curr_W);
    
%     if th > thThis(ii)
%         thN(ii) = thThis(ii);
%     end
end
thMedian=median(thThis);
thresh = thMedian.*multCoeff;

