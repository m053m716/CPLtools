function art_samples = getRC_interTrial_Periods(ts,tFinal,varargin)
%% GETRC_INTERTRIAL_PERIODS   Get inter-trial sample indices
%
%  art_samples = GETRC_INTERTRIAL_PERIODS(ts,tFinal);
%  art_samples = GETRC_INTERTRIAL_PERIODS(ts,tFinal,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     ts       :     List of time-stamps where behavior of interest occurs.
%
%   tFinal     :     Duration of recording (sec)
%
%  --------
%   OUTPUT
%  --------
%  art_samples :     Sample indices
%
% By: Max Murphy  v1.0  12/27/2018  Original version (R2017a)

%% DEFAULTS
E_PRE = 2;
E_POST = 1; % Periods to keep around the behaviors of interest (sec)
FS = 24414.0625; % Sample rate

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% OUTPUT
t = 0:(1/FS):tFinal;
idx = zeros(size(t));

% Make values HIGH wherever they are around the time of interes for the
% duration of interest.
for iT = 1:numel(ts)
   idx((t >= (ts(iT)-E_PRE)) & (t <= (ts(iT)+E_POST))) = 1;
end

% Now, get the onset and offset of consecutive strings of LOW values, so
% that we get epochs of "artifact" times
d_idx = diff(idx);

if idx(1)==0
   d_idx = [-1, d_idx];
end

if idx(end)==0
   d_idx = [d_idx, 1];
end

iStart = find(d_idx==-1);
iStop = find(d_idx==1);

art_samples = [iStart;iStop];



end