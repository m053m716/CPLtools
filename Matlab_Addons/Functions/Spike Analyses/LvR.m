function LvR_out = LvR(t)
%% Returns the LvR for a given set of spike timestamps, t.
%
%   1/11/2016 Max Murphy v1.0
%   Adapted from: 'Relating Neuronal Firing Patterns to Functional
%   Differentiation of Cerebral Cortex.' Shinomoto et al. (2009)
%
%   Input: 
%   t = 1 x n vector of spike timestamps (seconds)

%% Parameters
%Default
R = 0.0015;          %Refractoriness (s)

%% Fix dimension of t
t = reshape(t,1,numel(t));
 
I = diff(t);    %Interspike interval
n = length(I);  %Number of interspike intervals
norm = 3/(n-1); %Normalization constant

%% Calculate
%Accumulate all summands from index = 1:(n-1)
summand = 0;
for ii = 1:(n-1)
    summand = summand + ...
        (1 - 4*I(ii)*I(ii+1)/((I(ii)+I(ii+1))^2)) * ...
        (1 + 4*R/(I(ii) + I(ii+1)));    
end

%% Output
%Output the LvR value for a given segment of a spike train.
% LvR_out = norm * summand;
if n > 10
    LvR_out = norm * summand;
else
    LvR_out = nan;
end

if LvR_out == 0
    LvR_out = nan;
end

end