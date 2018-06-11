function L = Simple_LFP_Analysis(varargin)
%% SIMPLE_LFP_ANALYSIS Get the simple spectral content of LFP with time
%
%   L = SIMPLE_LFP_ANALYSIS('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
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
%                              used to estimate spectral power content.
%
%                           -> OV (def: 0.5) - overlap for windows used to
%                              compute the spectral power content (0 to 1).
%   --------
%    OUTPUT
%   --------
%      L                :   Table containing information for the following
%                           bands (rows):
%                           -> DELTA
%                           -> THETA
%                           -> ALPHA
%                           -> BETA
%                           -> GAMMA
% 
% By:   Max Murphy  v1.0    06/14/2017  Original version (R2017a)
%   See also: SIMPLE_SPIKE_ANALYSIS, BANDPOWER

%% DEFAULTS
% Acquisition info
DEC_FS = 300;                   % Decimated sampling frequency
                                % (NOTE: changing this requires new filter
                                % coefficients to be estimated and saved,
                                % so it is NOT recommended)
DATA_START = 1;                 % Start index for spike data
DATA_END   = inf;               % End index for spike data

% Directory info
DEF_DIR  = 'P:\Rat';
RAW_DIR  = '_RawData';
RAW_ID   = '_Raw_';
SAVE_ID  = '_LFP.mat';

% Frequency bands
BAND_INFO = {'DELTA', [0.5  1     4   4.5]; ...
             'THETA', [3.5  4     8   8.5]; ...
             'ALPHA', [7.5  8    13  13.5]; ...
             'BETA',  [12.5 13   30  30.5]; ...
             'GAMMA', [29.5 30  100 100.5]};

% RMS windowing parameters
WLEN = 10;          % Length (seconds)
OV   = 0.5;         % Overlap (percentage)

% Filter parameters
APASS = 0.0001;
ASTOP = 70;
MATCH = 'both';

% Timing parameters
TSTART = tic; 

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% CHECK FOR DIRECTORY
if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR,'Select recording block');
    if DIR == 0
        error('No path selected.');
    end
end



%% EXTRACT LABELING PARAMETERS
nBands = size(BAND_INFO,1);
Block = strsplit(DIR,filesep);
Block = Block{end};
RawFolder = fullfile(DIR,[Block RAW_DIR]);
if exist(RawFolder,'dir')==0
    warning('No raw data path located. Script aborted.');
    L = [];
    return
end

% Get list of channels to look at
C = dir(fullfile(RawFolder,['*' RAW_ID '*.mat']));
nChannels = numel(C);

% Get sampling frequency
load(fullfile(RawFolder,C(1).name),'fs');
fs_dec = fs/round(fs/DEC_FS);

%% DESIGN FILTERS
bpFilt = cell(nBands,1);
for iN = 1:nBands
    [~,bpFilt{iN}] = BandPassFilt( ...
        'FS',fs_dec,...                  % Sampling Frequency
        'FSTOP1',BAND_INFO{iN,2}(1), ... % First Stopband Frequency
        'FPASS1',BAND_INFO{iN,2}(2), ... % First Passband Frequency
        'FPASS2',BAND_INFO{iN,2}(3), ... % Second Passband Frequency
        'FSTOP2',BAND_INFO{iN,2}(4), ... % Second Stopband Frequency
        'ASTOP1',ASTOP, ...              % First Stopband Attenuation (dB)
        'APASS', APASS,  ...             % Passband Ripple (dB)
        'ASTOP2',ASTOP, ...              % Second Stopband Attenuation (dB)
        'MATCH', MATCH);                 % Band to match exactly
end

%% INITIALIZE VARIABLES
File = cell(nBands,1);
S = cell(nBands,1);

Band = BAND_INFO(:,1);
BandPars = BAND_INFO(:,2);

if ~isinf(DATA_END)
    STOP_STR = num2str(round(DATA_END/fs/60),'%04d');
else
    STOP_STR = 'stop';
end

START_STR = num2str(round(DATA_START/fs/60),'%04d');

%% CYCLE THROUGH EACH BAND FOR EACH CHANNEL

fprintf(1,'\tComputing LFP power bands for %s',Block);

for iCh = 1:nChannels
    fprintf(1,'.');
    raw = load(fullfile(RawFolder,C(iCh).name));
    if ~isinf(DATA_END)
        raw.data = raw.data(1:DATA_END);
    end
    
    if DATA_START > 1
        raw.data = raw.data(DATA_START:end);
    end
    if isempty(raw.data)
        warning('%s does not have full recording.',Block);
        L = [];
        return;
    end
    raw.data = decimate(double(raw.data),round(fs/DEC_FS));
    if iqr(raw.data) > 1e-2 % Check if it was scaled up or not
        raw.data = raw.data * 1e-6;
    end
    for iN = 1:nBands
        File{iN}{iCh,1} = C(iCh).name;
        data = filtfilt(bpFilt{iN},raw.data);
        [S{iN}{iCh,1},n] = SlidingPower(data,'WLEN',round(fs_dec*WLEN), ...
                                           'OV', OV); 
    end        
end
t = n./fs_dec;
fprintf(1,'complete.\n');
ElapsedTime(TSTART);

%% ASSIGN OUTPUT
FS = repmat(fs,nBands,1);
FS_DEC = repmat(fs_dec,nBands,1);

L = table(Band,File,S,FS,FS_DEC,BandPars);
save(fullfile(DIR,[Block '_' START_STR '_' STOP_STR ...
                   SAVE_ID]),'L','t','-v7.3');

end