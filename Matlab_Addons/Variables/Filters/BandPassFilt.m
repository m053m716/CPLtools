function [Hd, bpFilt] = BandPassFilt(varargin)
%BANDPASSFILT Returns a discrete-time filter object.

% MATLAB Code
% Generated by MATLAB(R) 9.0 and the Signal Processing Toolbox 7.2.
% Generated on: 03-Jan-2017 15:44:52

% Elliptic Bandpass filter designed using FDESIGN.BANDPASS.

% All frequency values are in Hz.
FS = 24414.0625;  % Sampling Frequency
FSTOP1 = 250;     % First Stopband Frequency
FPASS1 = 300;     % First Passband Frequency
FPASS2 = 3000;    % Second Passband Frequency
FSTOP2 = 3050;    % Second Stopband Frequency
ASTOP1 = 70;      % First Stopband Attenuation (dB)
APASS  = 0.1;     % Passband Ripple (dB)
ASTOP2 = 70;      % Second Stopband Attenuation (dB)
MATCH  = 'both';  % Band to match exactly

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% Construct an FDESIGN object and call its ELLIP method.
h  = fdesign.bandpass(FSTOP1, FPASS1, FPASS2, FSTOP2, ASTOP1, APASS, ...
                      ASTOP2, FS);
Hd = design(h, 'ellip', 'MatchExactly', MATCH);

bpFilt = designfilt('bandpassiir', 'StopbandFrequency1', FSTOP1, 'PassbandFrequency1', FPASS1, ...
    'PassbandFrequency2', FPASS2, 'StopbandFrequency2', FSTOP2, 'StopbandAttenuation1', ASTOP1, 'PassbandRipple', APASS, 'StopbandAttenuation2', ASTOP2, 'SampleRate', FS, 'DesignMethod', 'ellip');

end