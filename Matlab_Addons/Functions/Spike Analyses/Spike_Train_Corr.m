function [val, lag] = Spike_Train_Corr(train1, train2, varargin)
%% SPIKE_TRAIN_CORR Get the value and lag of maximum correlation between 2 trains
%
%   [val, lag] = SPIKE_TRAIN_CORR(train1, train2, varargin)
%   
%   --------
%    INPUTS
%   --------
%    train1     :       Spike train 1 (1xj double vector of time stamps).
%
%    train2     :       Spike train 2 (1xk double vector of time stamps).
%
%   varargin    :       Optional 'NAME', value input argument pairs
%
%                       'NAME'      (default)       [description]
%                       
%                       'FS'        (24414.0625)    [Sampling freq. (Hz)]
%
%                       'LAG'       (30)            [Maximum abs. value of
%                                                    lag to check (ms)]
%
%                       'LEN'       (1000)          [Window length (ms)]
%
%                       'TMIN'      (0)             [Start time of
%                                                    recording (sec)]
%
%                       'BIN'       (0.001)         [Bin size (sec)]
%
%                       'WIDTH'     (20)            [Smoother width (ms)]
%
%                       'TOL'       (eps)           [Minimum difference for
%                                                    finding the lag of 
%                                                    max correlation value]
%
%   --------
%    OUTPUT
%   --------
%     val       :       Value of maximum correlation within this window
%
%     lag       :       Lag at maximum correlation occurrence.
%
% See also  SSVKERNEL
%   By: Max Murphy v1.0 10/1/2016

%% Default parameters
% FS      =       24414.0625;
LAG     =       1000;
LEN     =       1000;
% WIDTH   =       20;
TMIN    =       0;
BIN     =       0.001;
TOL     =       eps;

%% Parse varargin
for ii = 1:2:length(varargin)
    eval([upper(varargin{ii}) '=varargin{ii+1};']);
end

%% Get instantaneous firing rate estimate using adaptive kernel smoothing
% w       =   floor(WIDTH/(BIN*1e3));
[~,~,optw] = sskernel(train1);
w       =   ceil(optw/(BIN*1e3));

tt      =   TMIN : BIN : max([train1, train2]);
% [y1,t]  =   ssvkernel(train1);
% y1      =   spline(t,y1,tt)* (length(train1));
x1 = histc(train1,tt);
y1 = fastsmooth(x1,w,3,1); 
mu1     =   mean(y1);

[~,~,optw] = sskernel(train2);
w       =   ceil(optw/(BIN*1e3));

% [y2,t]  =   ssvkernel(train2);
% y2      =   spline(t,y2,tt) * (length(train2));
x2 = histc(train2,tt);
y2 = fastsmooth(x2,w,3,1); 
mu2     =   mean(y2);
%% Loop through both IFR estimates and get sample matrices
N   = floor(LEN/(BIN*1e3));  % Number of points per "snapshot"
M   = floor(length(tt)/N);   % Number of "snapshots"
Y1  = nan(N,M);
Y2  = nan(N,M);
for iM = 1:M
    ind_start   =   (iM-1)*N+1;
    ind_stop    =   iM*N;
    ind_vec = ind_stop:-1:ind_start;
    Y1(:,iM) = y1(ind_vec).' - mu1; 
    Y2(:,iM) = y2(ind_vec).' - mu2; 
end

R = (1/M) * (Y1 * Y2.'); % Calculate average covariance matrix
C = R./(std(y1)*std(y2)); %Correlation matrix

%% Determine max correlation and lag of that correlation from mean XC
TAU = floor(LAG/(BIN*1e3));
tau = -TAU:TAU;
Cavg = zeros(1,length(tau));
ii = 0;
for k = tau
    ii = ii + 1;
    Cavg(ii) = mean(diag(C,k));
end
ind = find(abs(abs(Cavg)-max(abs(Cavg)))<=TOL,1,'first');
val = Cavg(ind);
lag = tau(ind);
figure, plot(-TAU:TAU,Cavg);
title('IFR Pairwise Average Cross Correlation');
xlabel('\tau (ms)'); 
ylabel('Normalized Cross Correlation Coefficient (\rho)');
end