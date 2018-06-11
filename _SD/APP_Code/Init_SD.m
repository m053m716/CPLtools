function pars = Init_SD(varargin)
%% INIT_SD Initialize SpikeDetectCluster parameters
%
%   pars = INIT_SD('NAME',value,...)
%
% By: Max Murphy (08/14/2017)

%% DEFAULTS
% General settings
VERSION  = 'v3.3.0';     % Version, to be passed with parameters
LIBDIR   = 'C:\MyRepos\_SD\APP_Code';% Location of associated sub-functions
DEF_DIR  = 'P:\';        % Default location to look for extracted data file
ED_ID = '\*P*Ch*.mat';    % Extracted data identifier (for input)

% Folder tags
RAW_ID      = '_RawData';           % Raw stream ID
FILT_ID     = '_Filtered';          % Filtered stream ID
CAR_ID      = '_FilteredCAR';       % Filtered + CAR ID
SPIKE_ID    = '_Spikes';            % Spike folder ID
SORT_ID     = '_Clusters';          % Sort folder ID
USE_CAR     = true;                 % By def. use common spatial reference

% File tags
RAW_DATA    = '_Raw_';              % Raw file ID
FILT_DATA   = '_Filt_';             % Filtered file ID
CAR_DATA    = '_FiltCAR_';          % CAR file ID
SPIKE_DATA  = '_ptrain_';           % Spikes file ID
CLUS_DATA   = '_clus_';             % Clusters file ID
DELETE_OLD_PATH = false;            % Remove old files
USE_EXISTING_SPIKES = false;        % Use existing spikes on directory

% % Isilon cluster settings
USE_CLUSTER = true;      % Must pre-detect clusters on machine and run 
                         % v2017a in order to use Isilon cluster.

% Probe configuration
CHANS =  {'Wave',1:32,'P1'; ...  % Match the format for each probe that was used
          'Wav2',1:32,'P2'; ...  % to the number of channels on that probe. Skip
          'Wav3',1:32,'P3'; ...  % channel numbers (as seen by recording system)
          'Wav4',1:32,'P4'};     % if they are 'bad' (too noisy/too quiet).

% Spike detection settings

    % Parameters                     
    ARTIFACT_THRESH = 350;  % Threshold for artifact
    STIM_TS  = [];          % Pre-specified stim times
    ARTIFACT = [];          % Pre-specified artifact times
    PRE_STIM_BLANKING  = 2; % Window to blank before specifieid stim times (ms)
    POST_STIM_BLANKING = 4; % Window to blank after specified stim times (ms)
    ARTIFACT_SPACE  = 4;    % Window to ignore around artifact (suggest: 4 ms MIN for stim rebound)
    MULTCOEFF       = 4;    % Multiplication coefficient for noise
    PKDURATION      = 1.6;  % Pulse lifetime period (suggest: 2 ms MAX)
    REFRTIME        = 2.0;  % Refractory period (suggest: 2 ms MAX).
    PKDETECT        = 'neg';% 'both' or 'pos' or 'neg' for peak type
    ALIGNFLAG       = 1;    % Alignment flag for detection
                            % [0 -> highest / 1 -> most negative]
    P2PAMP          = 90;   % Minimum peak-to-peak amplitude
    W_PRE           = 0.4;  % Pre-spike window  (ms)
    W_POST          = 0.8;  % Post-spike window (ms)
    ART_DIST        = 1/35; % Max. time between stimuli (sec)
    NWIN            = 120;  % Number of windows for automatic thresholding
    WINDUR          = 200*1e-3; % Minimum window length (msec)    
    INIT_THRESH     = 50;       % Pre-adaptive spike threshold (micro-volts)
    PRESCALED       = true;     % Whether data has been pre-scaled to micro-volts.
    FIXED_THRESH    = 50;       % If alignment is 'neg' or 'pos' this can be set to fix the detection threshold level
    
% Spike clustering settings
SC_VER = 'SPC';   % Version of spike clustering 
                         
    % Parameters
    NCLUS_MAX = 5;          % Max. # of SPC clusters (including 'OUT')
    N_INTERP_SAMPLES = 100; % Number of interpolated samples for spikes
    MAX_SPK  = 2000;     % Max. spikes before template matching for a cluster
    MIN_SPK  = 10;       % Minimum spikes before sorting
    TEMPLATE = 'center'; % Cluster matching algorithm: 'center', 'nn', 'ml', 'mahal
    TEMPSD   = 3.5;      % Cluster template max radius for template matching
    TSCALE   = 3.5;      % Scaling for timestamps of spikes as a feature
    PERMUT   = 'n';      % For selection of first 'MAX_SPK' before starting template match
    FEAT     = 'wav';    % 'wav' or 'pca' or 'ica' for spike features
    WAVELET  = 'bior1.3';% 'haar' 'bior1.3' 'db4' 'sym8' all examples
    NINPUT   = 7;        % Number of feature inputs for clustering
    NSCALES  = 3;        % Number of scales for wavelet decomposition
    MINTEMP  = 0.000;    % Minimum SPC temperature
    MAXTEMP  = 0.201;    % Maximum SPC temperature
    TSTEP    = 0.001;    % Temperature step
    STAB     = 0.95;     % Stability criterion for selecting an SPC temperature
    SWCYC    = 300;      % Number of montecarlo iterations
    ABS_KNN  = 15;       % Absolute number of KNN (min.)
    REL_KNN  = 0.0001;   % Relative number of KNN
    NMINCLUS = 7;        % Absolute # for minimum cluster size
    RMINCLUS = 0.005;    % Relative minimum cluster size to total # spikes
    RANDOMSEED = 147;    % Random seed for SPC seeding
    
%% PARSE VARARGIN
if numel(varargin)==1
    varargin = varargin{1};
    if numel(varargin) ==1
        varargin = varargin{1};
    end
end

for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if exist('SD_VER','var')==0
    % Version of spike detection
    switch PKDETECT
        case 'neg'
            SD_VER = [FEAT '-neg' num2str(FIXED_THRESH)];    
        case 'pos'
            SD_VER = [FEAT '-pos' num2str(FIXED_THRESH)];
        case 'both'
            SD_VER = [FEAT '-PT'];            
    end
end

%% INITIALIZE PARAMETERS STRUCTURE OUTPUT
pars = struct;
    
    % Path properties
    if exist('DIR','var')~=0
        pars.DIR = DIR;
    end
    if exist('SAVE_LOC','var')~=0
        pars.SAVE_LOC = SAVE_LOC;
    end
    pars.DEF_DIR = DEF_DIR;
    pars.DELETE_OLD_PATH = DELETE_OLD_PATH;
    pars.USE_EXISTING_SPIKES = USE_EXISTING_SPIKES;
    
    %Detection properties
    pars.ARTIFACT_THRESH = ARTIFACT_THRESH;
    pars.ARTIFACT = ARTIFACT;
    pars.STIM_TS = STIM_TS;
    pars.PRE_STIM_BLANKING = PRE_STIM_BLANKING;
    pars.POST_STIM_BLANKING = POST_STIM_BLANKING;
    pars.ARTIFACT_SPACE = ARTIFACT_SPACE;
    pars.MULTCOEFF = MULTCOEFF;
    pars.PKDURATION = PKDURATION;
    pars.REFRTIME = REFRTIME;
    pars.ALIGNFLAG = ALIGNFLAG;
    pars.P2PAMP = P2PAMP;
    pars.W_PRE = W_PRE;
    pars.W_POST = W_POST;
    pars.ART_DIST = ART_DIST;
    pars.NWIN = NWIN;
    pars.WINDUR = WINDUR;
    pars.INIT_THRESH = INIT_THRESH;
    pars.PRESCALED = PRESCALED;
    pars.PKDETECT = PKDETECT;
    pars.FIXED_THRESH = FIXED_THRESH;
    
    %Clustering properties
    pars.N_INTERP_SAMPLES = N_INTERP_SAMPLES;
    pars.MAX_SPK = MAX_SPK;
    pars.MIN_SPK = MIN_SPK;
    pars.TEMPLATE = TEMPLATE;
    pars.TEMPSD = TEMPSD;
    pars.PERMUT = PERMUT;
    pars.FEAT = FEAT;
    pars.NINPUT = NINPUT;
    pars.NSCALES = NSCALES;
    pars.MINTEMP = MINTEMP;
    pars.MAXTEMP = MAXTEMP;
    pars.TSTEP = TSTEP;
    pars.STAB = STAB;
    pars.SWCYC = SWCYC;
    pars.ABS_KNN = ABS_KNN;
    pars.REL_KNN = REL_KNN;
    pars.NMINCLUS = NMINCLUS;
    pars.RMINCLUS = RMINCLUS;
    pars.NCLUS_MAX = NCLUS_MAX;
    pars.RANDOMSEED = RANDOMSEED;
    pars.TSCALE = TSCALE;
    
    %General things about this run
    pars.CHANS = CHANS;
    pars.SD_VER = SD_VER;
    pars.SC_VER = SC_VER;
    pars.LIBDIR = LIBDIR;
    pars.ED_ID = ED_ID;
    pars.RAW_ID = RAW_ID;
    pars.RAW_DATA = RAW_DATA;
    pars.CLUS_DATA = CLUS_DATA;
    pars.USE_CAR = USE_CAR;
    if pars.USE_CAR
        pars.FILT_ID = CAR_ID;
        pars.FILT_DATA = CAR_DATA;
    else
        pars.FILT_ID = FILT_ID;
        pars.FILT_DATA = FILT_DATA;
    end
    pars.SPIKE_ID = SPIKE_ID;
    pars.SPIKE_DATA = SPIKE_DATA;
    pars.SORT_ID = SORT_ID;
    pars.WAVELET = WAVELET;
    pars.USE_CLUSTER = USE_CLUSTER;
    pars.VERSION = VERSION;
    
end