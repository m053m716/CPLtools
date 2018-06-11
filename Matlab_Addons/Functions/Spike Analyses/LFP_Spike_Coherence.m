function [D,SPK] = LFP_Spike_Coherence(D,SPK,varargin)
%% LFP_SPIKE_COHERENCE  Get the phase coherence of spike trains to LFP
%
%   [D,SPK] = LFP_SPIKE_COHERENCE(D,SPK,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%      D        :       Table of spike outputs from SIMPLE_SPIKE_ANALYSIS
%
%     SPK       :       Table of spike data (peak_trains & Fs) from
%                       SIMPLE_SPIKE_ANALYSIS.
%
%   varargin (optional)  :   'NAME', value input argument pairs.
%
%                           - ANY parameter listed in DEFAULTS. Useful
%                             examples:
%
%                           -> DATA_START (def: 1) - sample index of
%                              start of spike train relative to start of
%                              recording.
%
%                           -> DATA_STOP (def: inf) - sample index of end
%                              of spike train relative to start of
%                              recording. Setting to inf takes all
%                              remaining samples after DATA_START.
%
%                           -> WLEN (def: 30) - time (seconds) of windows
%                              used to compute the coherence analysis.
%
%                           -> OV (def: 0.5) - overlap for windows used to
%                              compute the coherence analysis (0 to 1).
%   --------
%    OUTPUT
%   --------
%      D        :       Updated table of spike outputs, with new fields:
%                       -> THETAp, THETAm
%                       -> ALPHAp, ALPHAm
%                       -> BETAp,  BETAam
%                       -> GAMMAp, GAMMAm
%
%     SPK       :       Updated table of spike data, with same fields as D.
%
%   Each corresponds to a frequency band, with p referring to the phase
%   relationship between LFP and spikes, and m referring to the magnitude
%   relationship between LFP and spikes. D contains 
%
% See also: SIMPLE_SPIKE_ANALYSIS
% 
%   By: Max Murphy  v1.1    05/02/2017  Modified calculations and default
%                                       parameters. Changed
%                                       recording_directory to varargin and
%                                       allowed parsing of optional input
%                                       arguments.
%                   v1.0    05/01/2017  Original verison (R2017a)

%% DEFAULTS
% Acquisition info
DEC_FS = 200;                   % Decimated sampling frequency
                                % (NOTE: changing this requires new filter
                                % coefficients to be estimated and saved,
                                % so it is NOT recommended)
DATA_START = 1;                 % Start index for spike data
DATA_END   = inf;               % End index for spike data

% Directory info
DEF_DIR  = 'P:\Rat';
RAW_DIR = '_RawData';
RAW_ID  = 'Raw';

% % Rate smoothing
% BIN = 0.001;

% Frequency bands
BAND_INFO = {'THETA', [4   8]; ...
             'ALPHA', [8  13]; ...
             'BETA',  [13 25]; ...
             'GAMMA', [25 40]};

% Transform parameters
WLEN = 30;          % Length (seconds)
OV   = 0.5;         % Overlap (percentage)

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% LOAD FILTER PARAMETERS
N = size(D,1);
LPF = load('DEC_50HZ_LPF_BUTTER.mat');
HPF = load('DEC_3HZ_HPF_BUTTER.mat');

coefs = struct;
for iB = 1:size(BAND_INFO,1)
    coefs.(BAND_INFO{iB,1}) = load(['DEC_' BAND_INFO{iB,1} '.mat']);
    eval(['D.' BAND_INFO{iB,1} 'm = nan(N,1);']);
    eval(['D.' BAND_INFO{iB,1} 'p = nan(N,1);']);
    
    eval(['SPK.' BAND_INFO{iB,1} 'm = cell(N,1);']);
    eval(['SPK.' BAND_INFO{iB,1} 'p = cell(N,1);']);
end

%% CHECK FOR DIRECTORY
if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR,'Select recording tank');
    if DIR == 0
        error('No path selected.');
    end
end

if exist(DIR,'dir')==0
    error('Bad directory path, check directory location.');
end

%% GO THROUGH EACH RECORD IN D TO GET INFO
h = waitbar(0,'Please wait, computing coherence...');
tStart = tic;
clc;
for iN = 1:N
    pname = fullfile(DIR,...
                     D.Rat{iN}, ...
                     D.Block(iN,:), ...
                     [D.Block(iN,:) RAW_DIR]);
                 
    listing = dir([pname filesep '*' RAW_ID ...
                   '*' num2str(D.Channel(iN),'%03d') '.mat']);
     
    % Make checks for correct files
    if isempty(listing)
        warning([D.Block(iN,:) ': Channel ' num2str(D.Channel(iN)), ...
                  ' not found. Skipping...']);
        continue;
    end
               
    if numel(listing) > 1
        fname = uidropdownbox('Select file', ...
                          ['Multiple channel ' num2str(D.Channel(iN)) ...
                           ' files; pick one:'], ...
                           {listing.name});
        load_name = [pname filesep fname];
    else
        fname = listing.name;
        load_name = [pname filesep fname]; 
    end
    
    fprintf(1,'\n\n%s: Channel %d, Cluster %d\n',D.Block(iN,:), ...
                                                 D.Channel(iN), ...
                                                 D.Cluster(iN));
    fprintf(1,'-----------------------------------------------------\n\n');
    
    % Load file
    fprintf(1,'\tloading...');
    load(load_name,'data');
    fprintf(1,'complete\n');
    
    % Get smoothed rate function for coherence estimates
    ts = find(SPK.Peaks{iN})./SPK.fs(iN);
    tt = 0 : (1/DEC_FS) : numel(SPK.Peaks{iN})/SPK.fs(iN);
    x  = histc(ts,tt).';
    
%     % Uncomment to add smoothing kernel to get rate estimate    
%     [~,~,optw] = sskernel(ts);
%     w =   ceil(optw/(BIN*1e3));
%     x = fastsmooth(x,w,3,1); 
    
    % Decimate and do general lowpass/highpass filter first (decimate 
    % function has built-in 8th-order Chebyshev LPF that is applied by
    % default).
    fprintf(1,'\tdecimate (%d Hz)...',DEC_FS);
    if isinf(DATA_END) && DATA_START == 1 % Spike and LFP data alignment
        data = decimate(double(data),SPK.fs(iN)/DEC_FS);
    else
        if isinf(DATA_END)
            data = decimate(double(data(DATA_START:end)), ...
                            SPK.fs(iN)/DEC_FS);
        else
            data = decimate(double(data(DATA_START:DATA_END)), ...
                            SPK.fs(iN)/DEC_FS);
        end
    end
    fprintf(1,'complete.\n');
    fprintf(1,'\tLFP Band filter (3 to 50 Hz)...');
    data = filtfilt(LPF.SOS,LPF.G,data);
    data = filtfilt(HPF.SOS,HPF.G,data);
    fprintf(1,'complete\n');
    fprintf(1,'\t------------------\n\n');
    
    % Make sure vectors are the same length
    if numel(x) > numel(data)
        x = x(1:numel(data));
    elseif numel(data) > numel(x)
        data = data(1:numel(x));
    end
    
    % Cycle through each band and filter, do coherence analysis
    
    for iB = 1:size(BAND_INFO,1)
        fprintf(1,'\t\t%s: %d to %d Hz\n',BAND_INFO{iB,1},BAND_INFO{iB,2});
        % Get bandpass data for rhythm
        bp = filtfilt(coefs.(BAND_INFO{iB,1}).SOS, ...
                      coefs.(BAND_INFO{iB,1}).G, ...
                      data);
                  
        % Get phase of rhythm using hilbert transform
        p = angle(hilbert(bp));
        
         SPK.([BAND_INFO{iB,1} 'm']){iN}    =mscohere(x,bp, ...
                                                 WLEN*DEC_FS, ...
                                                 round(OV*DEC_FS));
        [SPK.([BAND_INFO{iB,1} 'p']){iN},fc]=mscohere(x,p, ...
                                                 WLEN*DEC_FS, ...
                                                 round(OV*DEC_FS));
        
        D.([BAND_INFO{iB,1} 'm'])(iN)=trapz(fc/pi, ...
            SPK.([BAND_INFO{iB,1} 'm']){iN});
        D.([BAND_INFO{iB,1} 'p'])(iN)=trapz(fc/pi, ...
            SPK.([BAND_INFO{iB,1} 'p']){iN});
        
    end
    waitbar(iN/N);
end
delete(h);
clc; beep;
fprintf(1,'LFP-Spike coherence estimates complete.\n');
ElapsedTime(tStart);


end