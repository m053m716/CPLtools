function aa_SplitSort(fs,varargin)
%% AA_SPLITSORT Breaks long recordings into component parts
%
%   AA_SPLITSORT(FS,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%      fs       :       Sampling frequency of recording
%
%   varargin    :       (Optional) 'NAME', value input argument pairs
%
%                       -> 'DIR' (default: N/A; prompts user for path using
%                                          a graphical interface)
%
%   --------
%    OUTPUT
%   --------
%   'Splitted' folder containing separated sessions for both spiking and
%   raw waveform data.
%
% By: Max Murphy    v1.1    07/26/2017  Changed "pars" save so that there
%                                       will ALWAYS be a "pars" variable.
%                                       This will save the associated
%                                       "T_SPLIT" times with every saved
%                                       channel or cluster, which makes it
%                                       much easier to relate split files
%                                       to data that is relative to the
%                                       entire recording duration.
%                   v1.0    06/09/2017  Original version (R2017a)
%   See also: SORTCLUSTERS, AA_PSTH, QSD, SPIKEDETECTCLUSTER, QSPLITSORT

%% DEFAULTS
TAG = '_Splitted';              % Identifier for splitted output
T_SPLIT = [   0, 600; ...       % Times (in seconds) for splitting block
           600, 4200; ...
          4200, 4800; ...
          4800, 8400; ...
          8400, 9000; ...
          9000, 12600; ...
         12600, 13200];
     
EPOCH_LABEL = {'_01_nbasal'; ... % Corresponding epoch folder labels
               '_02_Stim'; ...
               '_03_nbasal'; ...
               '_04_Stim'; ...
               '_05_nbasal'; ...
               '_06_Stim'; ...
               '_07_nbasal'};
           
DEF_DIR = 'P:\Rat\PopulationDynamics';  % Default UI search directory
RAW_PATH = '_RawData';                  % Path for Raw (unfiltered) data
CLUSTER_PATH = '_ad-PT_SPC_Clusters';   % Path for spike clusters

RAW_ID = 'Raw';                         % Identifier for raw wave files
CLUSTER_ID = 'ptrain';                  % Identifier for spike cluter files

SPLIT_RAW = true;           % Set false to skip raw data splitting
SPLIT_SPIKES = true;        % Set false to skip spike splitting
ENABLE_FS_CHECK = true;     % Set false to override check of saved fs

USE_CLUSTER = false;        % Goes to true when using QSPLITSORT

%% PARSE INPUT
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% CHECK INPUTS
nT = size(T_SPLIT,1);
if abs(nT-numel(EPOCH_LABEL))>eps
    error('TSPLIT and EPOCH_LABEL must have same number of rows.');
end

if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR,'Select block to be split');
    if DIR == 0
        error('No directory selected. Script canceled.');
    end
else
    if exist(DIR,'dir')==0 %#ok<NODEF>
        error('Check DIR; invalid directory.');
    end
end

name = strsplit(DIR,filesep);
name = name{end};

if exist(fullfile(DIR,[name RAW_PATH]),'dir')==0
    error('No RawData directory in selected block (check RAW_PATH).');
end

if exist(fullfile(DIR,[name CLUSTER_PATH]),'dir')==0
    error('No Cluster directory in selected block (check CLUSTER_PATH).');
end

if USE_CLUSTER
    myJob = getCurrentJob;
    set(myJob,'Tag',['Splitting spike clusters for ' name '...']);
end

%% GET SPLIT INDICES
T_SPLIT = floor(T_SPLIT*fs);

%% SPLIT CLUSTER FILES
if SPLIT_SPIKES
    S = dir(fullfile(DIR,[name CLUSTER_PATH],['*' CLUSTER_ID '*.mat']));
    parfor iS = 1:numel(S)
        spk = load(fullfile(DIR,[name CLUSTER_PATH],S(iS).name));
        t_ind = 1:numel(spk.peak_train);
        if isfield(spk,'pars')
            pars = spk.pars;
            exist_pars = true;
            if ENABLE_FS_CHECK
                if abs(spk.pars.FS - fs) > eps
                    error('Spike fs mismatch. Check input.');
                end
            end
        else
            exist_pars = false;
        end

        spikelist = 1:(size(spk.spikes,1));
        for iT = 1:nT
            peak_train = spk.peak_train(t_ind > T_SPLIT(iT,1) & ...
                                        t_ind <= T_SPLIT(iT,2));

            spikes = spk.spikes(spikelist(1:numel(find(peak_train))),:);
            spikelist(1:numel(find(peak_train))) = [];
            artifact = spk.artifact(spk.artifact > T_SPLIT(iT,1) & ...
                                    spk.artifact <= T_SPLIT(iT,2));

            pname = fullfile(DIR, ...
                             [name CLUSTER_PATH TAG], ...
                             [name EPOCH_LABEL{iT}]);

            if exist(pname,'dir')==0
                mkdir(pname);
            end
            fname = fullfile(pname,S(iS).name);
            pars.T_SPLIT = T_SPLIT(iT,:);
            parsave(fname,'artifact',artifact, ...
                          'pars', pars, 'peak_train', peak_train, ...
                          'spikes',spikes);
            
        end
    end
end

if USE_CLUSTER
    set(myJob,'Tag',['Splitting raw wave data for ' name '...']); %#ok<*UNRCH>
end

%% SPLIT RAW DATA FILES
if SPLIT_RAW
    R = dir(fullfile(DIR,[name RAW_PATH],['*' RAW_ID '*.mat']));
    parfor iR = 1:numel(R)
        raw = load(fullfile(DIR,[name RAW_PATH],R(iR).name));
        t_ind = 1:numel(raw.data);
        if isfield(raw,'gitInfo')
            gitInfo = raw.gitInfo;
        end
        
        if (isfield(raw,'fs') && ENABLE_FS_CHECK)
            if abs(raw.fs - fs) > eps
                error('Raw sampling rate (fs) mismatch. Check splitting.');
            end
        end
        
        for iT = 1:nT
            ind = t_ind(t_ind > T_SPLIT(iT,1) & t_ind <= T_SPLIT(iT,2));
            data = raw.data(ind);

            pname = fullfile(DIR, ...
                             [name RAW_PATH TAG], ...
                             [name EPOCH_LABEL{iT}]); %#ok<*PFBNS>

            if exist(pname,'dir')==0
                mkdir(pname);
            end
            fname = fullfile(pname,R(iR).name);
            gitInfo.T_SPLIT = T_SPLIT(iT,:);
            parsave(fname,'data',data, ...
                          'fs',fs,'gitInfo',gitInfo);

        end
    end
end

if USE_CLUSTER
    set(myJob,'Tag',['Complete: split spike and raw wave files for ' name]);
end

end