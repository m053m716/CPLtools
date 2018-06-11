function [scales,F_obs] = getWaveScales(F_des,fs,wname)
%% GETWAVESCALES Gets wavelet scales corresponding to freqs in vector F_des
%
%   scales = GETWAVESCALES(F_des,fs)
%
%   scales = GETWAVESCALES(F_des,fs,'wname')
%
%   [scales,F_obs] = GETWAVESCALES(__)
%
%   --------
%    INPUTS
%   --------
%     F_des     :       Vector of frequencies for which the scales with
%                       closest center-frequency are desired.
%
%      fs       :       Sampling frequency (samples per second).
%
%    'wname'    :       (Optional; default: 'morl')
%                       Name of wavelet function.
%
%   --------
%    OUTPUT
%   --------
%    scales     :       Vector of scales for observing the desired
%                       frequencies.
%
%     F_obs     :       (Optional) Center frequencies corresponding to each
%                       element of scales.
%
% See also: WAVELETFAMILIES, CENTFRQ, SCAL2FRQ, WAVEFUN
%   By: Max Murphy  v1.0    03/23/2017  Original version (R2017a)

%% DEFAULTS
WNAME = 'morl';

%% PARSE INPUT
% Validation functions
validate_F_des = @(input) isnumeric(input) && ...
                            (numel(input) > 1);
                 
validate_fs = @(input) validateattributes(input, ...
                    {'numeric'}, {'scalar','positive'});
                 
% Input parser
p = inputParser;
addRequired(p,'F_des',validate_F_des);
addRequired(p,'fs',validate_fs);
addOptional(p,'wname',WNAME);

if exist('wname','var')~=0
    parse(p,F_des,fs,'wname',wname);
else
    parse(p,F_des,fs);
end

wname = p.Results.wname;

%% CHECK FOR VALID WAVELET FUNCTION
coeffs = wavefun(wname);
figure('Name', [wname ' coefficients'], ...
       'Units', 'Normalized', ...
       'Position', [0.2 0.2 0.6 0.6]);
if max(abs(imag(coeffs)))==0
    subplot(2,1,1);
    stem(1:numel(coeffs),real(coeffs));
    xlabel('Coefficient number'); ylabel('Real part');
    title([wname ' wavelet coefficients']);
else
    subplot(2,1,1);
    plot3(1:numel(coeffs),real(coeffs),imag(coeffs));
    xlabel('Coefficient number');
    ylabel('Real part'); zlabel('Imaginary Part');
    title([wname ' wavelet coefficients']);
end

%% LOOP THROUGH EACH FREQUENCY AND DETERMINE CORRESPONDING SCALE
nF = numel(F_des);
scales = nan(1,nF);
F_obs = nan(1,nF);

DELTA = 1/fs;

for iF = 1:nF
    scales(iF) = round(fs/F_des(iF));
    F_obs(iF) = scal2frq(scales(iF),wname,DELTA);
end

%% PLOT CORRESPONDING SCALES AND FREQUENCIES
subplot(2,1,2);
scatter(F_obs,log2(scales),24,[0.4 0.4 1.0],'filled');
xlabel('Frequency (Hz)'); ylabel('ln_2(Scale)'); 
title('Scales and Corresponding Frequencies');


end