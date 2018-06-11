function [s,n] = SlidingPower(x,varargin)
%% SLIDINGPOWER Get power in a sliding window using RMS of signal
%
%   [s,n] = SLIDINGPOWER(x,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%      x        :       Signal from which to extract RMS in sliding window.
%
%   varargin    :       (Optional) 'NAME', value input argument pairs
%
%                       -> 'WLEN' : (Default: 1000) Number of samples in
%                                   sliding window
%                       -> 'OV'   : (Default: 0.5) Fraction [0 to 1] of
%                                   overlap for each consecutive window.
%
%   --------
%    OUTPUT
%   --------
%      s        :       Signal RMS in sliding window
%
%      n        :       Index of original signal around which window was
%                       averaged (i.e. the "middle" of the window).
%
%   By: Max Murphy    v1.0    07/03/2017  Original version (R2017a)
% See also: SIMPLE_LFP_ANALYSIS, BANDPOWER

%% DEFAULTS
WLEN = 1000;
OV   = 0.5;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET SLIDING POWER VALUES
w = 1:WLEN;
n = [];
s = [];
while max(w) <= numel(x)
    s = [s, rms(x(w))];
    n = [n, round(mean(w))];
    w = w + round((1-OV) * WLEN);
end

end