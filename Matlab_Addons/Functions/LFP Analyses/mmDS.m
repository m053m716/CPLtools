function mmDS(varargin)
%% MMDS  Down-sample raw data and save to its own sub-folder in block.
%
%   MMDS;
%   MMDS(pars);
%   MMDS('NAME',value,...);
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%
%           -> 'DIR' \\ (Def: none) BLOCK directory for this recording. If
%                       not specified, a UI prompts user for the recording
%                       block path, which is the folder for a single
%                       recording that contains the _RawData folder.
%
%           -> 'NOTCH' \\ (Def: [57,  63;  ...
%                                117, 123; ...
%                                177, 183; ...
%                                237, 243]) Setting this to empty stops the
%                                notch filter. Alternatively, the desired
%                                frequency bands for the notch can be
%                                altered by changing rows of the NOTCH
%                                matrix.
%
%           -> 'IN_PATH' \\ (Def: 'RawData') Ending appended to block name
%                           using DELIM that indicates where the raw data
%                           files are.
%
%           -> 'IN_ID' \\ (Def: 'Raw') Default file identifier for
%                         input raw data files. Input files have must have
%                         this somewhere in the name, and must contain the
%                         following two variables:
%
%                         - data [1 x NSamples raw waveform]
%                         - fs   [Sampling frequency (Hz)]
%
%           -> 'OUT_ID' \\ (Def: 'DS') File ID that replaces 'IN_ID' for
%                          the saved output. Also doubles as the appended
%                          ending for the output folder.
%
%           -> 'DELIM' \\ (Def: '_') Delimiter for splitting file name
%                         info.
%
%   --------
%    OUTPUT
%   --------
%   Saves downsampled and notch-filtered data in [Block]_DS folder as
%   single channel data.
%
% By: Max Murphy    v1.0    08/10/2017  Original version (R2017a)

%% DEFAULTS
% Main options
pars = struct;
pars.DEC_FS = 1000;    % Desired sample rate (Hz; may not end up exact)
% pars.NOTCH = [57,  63;  ...
%               117, 123; ... % If empty, no notch applied; otherwise, use
%               177, 183; ... % bands specified by rows of this matrix.
%               237, 243];
pars.NOTCH = [57, 63];

% Directory info
pars.DEF_DIR = 'P:\Rat\tDCS';    % Default UI selection direcotry
pars.IN_PATH = 'RawData';        % Appended folder name for raw data
pars.IN_ID = 'Raw';              % Tag for files to input
pars.OUT_ID = 'DS';              % Tag/appended folder name for DS data
pars.DELIM = '_';                % Delimiter for file name inputs

% Cluster info
pars.USE_CLUSTER=false;        % Option to run on Isilon cluster
pars.UNC_PATH='\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\';

%% PARSE VARARGIN
if nargin == 1
    if isa(varargin{1},'struct')
        pars = varargin{1};
    else
        varargin = varargin{1};
        for iV = 1:2:numel(varargin)
            pars.(upper(varargin{iV})) = varargin{iV+1};
        end
    end
else
    for iV = 1:2:numel(varargin)
        pars.(varargin{iV}) = varargin{iV+1};
    end
end

%% GET DIRECTORY
if isfield(pars,'DIR')==0
    pars.DIR = uigetdir(pars.DEF_DIR,'Select recording BLOCK');
    if pars.DIR == 0 
        error('No selection. Script canceled.');
    end
end

%% GET INPUT FILES
base = strsplit(pars.DIR,filesep);
base = base{end};
finfo = strsplit(base,'DELIM');

% Get I/O directories
indir = fullfile(pars.DIR,[base pars.DELIM pars.IN_PATH]);
outdir = fullfile(pars.DIR,[base pars.DELIM pars.OUT_ID]);

if pars.USE_CLUSTER
    % Get job and set tag
    myJob = getCurrentJob;
    set(myJob,'Tag',['Processing: DS ' finfo{1} '...']);
    
    % Get proper path using universal naming convention (UNC)
    rep_ind = (find(pars.DIR == filesep,1,'first')+1);
    outdir = [pars.UNC_PATH outdir(rep_ind:end)];
    indir = [pars.UNC_PATH indir(rep_ind:end)];
    if exist(outdir,'DIR')==0
        mkdir(outdir);
    end
    
    F=dir(fullfile(indir,['*' pars.DELIM pars.IN_ID pars.DELIM '*.mat']));
    parfor iF = 1:numel(F)
        % Load data & get decimation factor (integer)
        indata = load(fullfile(indir,F(iF).name),'data','fs');
        r = floor(indata.fs/pars.DEC_FS); %#ok<PFBNS>
        
        % Do decimation
        outdata = struct;
        outdata.fs = indata.fs/r;
        outdata.data = decimate(double(indata.data),r);
        
        % Do notch filter
        for ii = 1:size(pars.NOTCH,1)
            [b,a]=cheby1(4,0.05,pars.NOTCH(ii,:)*(2/outdata.fs),'stop');
            outdata.data = filtfilt(b,a,outdata.data);
        end
        
        % Get output file name with appropriate ID and save
        outname = strrep(F(iF).name,pars.IN_ID,pars.OUT_ID);
        parsavedata(fullfile(outdir,outname),...
                    'data',outdata.data,...
                    'fs',outdata.fs);
    end
    set(myJob,'Tag',['Complete: DS for ' finfo{1} '.']);
else
    F=dir(fullfile(indir,['*' pars.DELIM pars.IN_ID pars.DELIM '*.mat']));
    if exist(outdir,'DIR')==0
        mkdir(outdir);
    end
    
    fprintf(1,'\n->\tDown-sampling (DS): %s raw data',finfo{1});
    for iF = 1:numel(F)
        fprintf(1,'. ');
        % Load data & get decimation factor (integer)
        indata = load(fullfile(indir,F(iF).name),'data','fs');
        r = floor(indata.fs/pars.DEC_FS);
        
        % Do decimation
        outdata = struct;
        outdata.fs = indata.fs/r;
        outdata.data = decimate(double(indata.data),r);
        
        % Do notch filter
        for ii = 1:size(pars.NOTCH,1)
            [b,a]=cheby1(4,0.05,pars.NOTCH(ii,:)*(2/outdata.fs),'stop');
            outdata.data = filtfilt(b,a,outdata.data);
        end
        
        % Get output file name with appropriate ID and save
        outname = strrep(F(iF).name,pars.IN_ID,pars.OUT_ID);
        save(fullfile(outdir,outname),'-STRUCT','outdata','-v7.3');
    end
    fprintf(1,'complete.\n');
end

end