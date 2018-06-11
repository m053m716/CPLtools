function data_out = mmDN_FILT(data_in,fs,pars)
%% MMDN_FILT    De-noise and filter data
%
%   data_out = mmDN_FILT(data_in,fs,pars);
%
%   --------
%    INPUTS
%   --------
%   data_in     :   1 x N vector of data to de-noise and filter.
%
%     fs        :   Sampling frequency for data.
%
%    pars       :   Parameters structure containing the following fields:
%
%                   -> 'NOTCH' // k x 2 matrix of start and stop
%                                 frequencies for k notch filter
%                                 applications.
%
%                   -> 'CHEBY_ORD' // Order for chebyshev filter.
%
%                   -> 'RP' // Passband ripple.
%
%                   -> 'NOISE' // Indices of noisy samples to remove.
%
%                   -> 'HP' // High-pass cutoff frequency.
%
%                   -> 'LP' // Low-pass cutoff frequency.
%
%                   -> 'MAX_FS_LP' // Max. sampling frequency below which
%                                     it is unneccessary to do the LPF.
%
%   --------
%    OUTPUT
%   --------
%   data_out    :   1 x N vector of de-noised and filtered data.
%
% By: Max Murphy    v1.0    08/15/2017  Original version (R2017a)
%
%   See also: MMMEMFREQ

%% REMOVE NOISE AND FILTER
data_out = double(data_in); clear data_in;
data_out(pars.NOISE) = [];

% Notch filter, if specified
for ii = 1:size(pars.NOTCH,1)
    [b,a]=cheby1(pars.CHEBY_ORD,pars.RP,pars.NOTCH(ii,:)*(2/fs),'stop');
    data_out=filtfilt(b,a,data_out);
end

% High-pass filter, if specified
if pars.HP > 0
    [b,a]=cheby1(pars.CHEBY_ORD,pars.RP,pars.HP*(2/fs),'high');
    data_out=filtfilt(b,a,data_out);
end

% Low-pass filter, if specified
if (~isinf(pars.LP) && fs>pars.MAX_FS_LP)
    [b,a]=cheby1(pars.CHEBY_ORD,pars.RP,pars.LP*(2/fs));
    data_out=filtfilt(b,a,data_out);
end

end