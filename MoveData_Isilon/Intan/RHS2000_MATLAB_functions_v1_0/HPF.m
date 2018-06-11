function out = HPF(in, fSample, fCutoff)

% out = HPF(in, fSample, fCutoff)
%
% Implements a one-pole high-pass filter on vector 'in'.
% fSample = sample rate of data (in Hz or Samples/sec)
% fCutoff = high-pass filter cutoff frequency (in Hz)
%
% Example:  If neural data was sampled at 30 kSamples/sec
% and you wish to high-pass filter at 300 Hz:
%
% out = HPF(in, 30000, 300);

% Calculate IIR filter parameters
A = exp(-(2*pi*fCutoff)/fSample);
B = 1 - A;

% This algorithm implements a first-order LOW-pass filter, and then
% subtracts the output of this low-pass filter from the input to create
% a first-order high-pass filter.

outLPF = zeros(size(in));
outLPF(1) = in(1);  % if filtering a continuous data stream, change this
                    % to use the previous final value of outLPF

% Run filter
for i = 2:length(in)
    outLPF(i) = (B*in(i-1) + A*outLPF(i-1));
end

out = in - outLPF;
