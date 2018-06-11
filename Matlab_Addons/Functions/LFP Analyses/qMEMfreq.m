function qMEMfreq(varargin)
%% QMEMFREQ Queues up mmMEMfreq to run on the Isilon clusters for LFP.
%
%   qMEMfreq('NAME',value,...);
%
%   example usage:
%   --------------
%   load('Your Organization Filename Here.mat','F');
%   mem = cell(numel(F),1); % <- For storing output filename
%   TIC = tic;  % <- Only if you want to time it
%   for iF = 1:numel(F)
%       qMEMfreq('DIR',F(iF).block,'TIC',TIC);
%       mem{iF} = fullfile(F(iF).block,[F(iF).base '_MEM']);
%       F(iF).LFP = true; % <- Keep track of what you've done
%   end
%   F = addStructField(F,mem); % <- add...is in "Handling Variables" folder
%   save('YourBlockOrganizationFile.mat','F'); % <- update progress
%   --------------
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%
%           -> 'DIR' \\ (Def: none) If specified, skips the UI selection of
%                       Recording BLOCK.
%
%           -> 'MEM_PATH' \\ (Def: []) Specify this as a string if you wish
%                            to run a specific version of mmMEMfreq from a
%                            specific location (i.e. during development).
%                            Typically leave this alone.
%
%           -> 'CLUSTER_LIST' \\ (Def: {'CPLMJS'; 'CPLMJS2'; 'CPLMJS3'})
%                                This sets the list of clusters to cycle
%                                through in order to complete the job. In
%                                case you don't want to use a busy cluster,
%                                this should be changed (i.e. leave CPLMJS
%                                out of the list if somebody is doing a
%                                surgery that day and will be extracting
%                                data later).
%
%           -> 'CLUSTER' \\ (Def: none) If specified, this overrides
%                           'CLUSTER_LIST' and defaults to using the
%                           specified cluster. Not recommended, since it
%                           will not ping the clusters to see if there are
%                           Idle workers to use and could cause a bunch of
%                           problems. Only use if you know what you're
%                           doing.
%
%           -> 'TIC' \\ (Def: none) If specified, can be used to hold a
%                       previous start time in order to get an idea of how
%                       long for example a loop has been running.
%
%           -> 'LEN' \\ (Default: 500 ms) Length (in milliseconds) of
%                       sliding window used to compute MEM frequency
%                       estimate.
%
%           -> 'STEP' \\ (Default: 0.8) Proportion of sliding window length
%                        That is overlapped with each consecutive step.
%
%           -> 'ORD' \\ (Default: 50) Model order to use for MEM estimate.
%
%           -> 'PK_START' \\ (Default: 2 Hz) First peak center to use.
%
%           -> 'PK_END' \\ (Default: 202 Hz) Last peak center to use.
%
%           -> 'BW' \\ (Default: 2 Hz) Width of each frequency value.
%
%           -> 'N_EVAL' \\ (Default: 10) Number of points averaged together
%                           to get the frequency estimate from each bin.
%                           E.g. with the default settings, you would be
%                           averaging frequency estimates from 0.2 Hz
%                           increments spacing to get the power estimate
%                           for each frequency bin. With the default
%                           settings, there are 100 frequency bins output.
%
%           -> 'DETREND' \\ (Default: 1) 0: none, 1: mean, 2: linear
%
%           -> 'NOISE' \\ (Default: []) Can be specified as a vector of
%                         indices for which the signal is noisy.
%
%           -> 'NOTCH' \\ (Def: []) Setting this to empty stops the
%                                notch filter. Alternatively, the desired
%                                frequency bands for the notch can be
%                                altered by changing rows of the NOTCH
%                                matrix.
%
%           -> 'HP' \\ (Def: 1 Hz) Specifies the high-pass cutoff to remove
%                       DC-biased signals from the data. Set to 0 to not
%                       perform this filter.
%
%   --------
%    OUTPUT
%   --------
%   Queues the mmMEMfreq to run on the Isilon. Once mmDS has been used on
%   the RawData from a recording block, this script can be used to extract
%   the LFP spectrogram for a recording session.
%
% By: Max Murphy    v1.0    08/16/2017  Original version (R2017a)

%% DEFAULTS
% Directory info
DEF_DIR = 'P:\Rat';
UNC_PATH='\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\';

% For finding clusters
CLUSTER_LIST = {'CPLMJS'; 'CPLMJS2'; 'CPLMJS3'}; % MJS cluster profiles
NWR          = [1,1];     % Number of workers to use
WAIT_TIME    = 60;        % Wait time for looping if using findGoodCluster
INIT_TIME    = 5;         % Wait time before initializing findGoodCluster

% Default attached files
MEM_PATH = [];
ATTACHED_FILES = {'mem.mexw64';...
                  'mmDN_FILT.m'};

%% PARSE VARARGIN
IN_ARGS = varargin;
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR,'Select block to be split');
    if DIR == 0
        error('No directory selected. Script canceled.');
    end
else
    if exist(DIR,'dir')==0 %#ok<*NODEF>
        error('Check DIR:\n\t%s is not a valid directory.',DIR);
    end
end

% Check MEM_PATH and get path for mmMEMfreq.m
if exist(MEM_PATH,'dir')==0
    MEM_PATH = which('mmMEMfreq.m');
    MEM_PATH = strsplit(MEM_PATH,filesep);
    MEM_PATH = strjoin(MEM_PATH(1:end-1),filesep);
end

% Hopefully this speeds up "finding" files to attach to Task
for iA = 1:numel(ATTACHED_FILES)
    ATTACHED_FILES{iA} = fullfile(MEM_PATH,ATTACHED_FILES{iA});
end

% Apply Universal Naming Convention (UNC) to directory
DIR = [UNC_PATH DIR((find(DIR == filesep,1,'first')+1):end)];
IN_ARGS = [IN_ARGS, {'DIR',DIR,'USE_CLUSTER',true}];

%% SUBMIT TO CLUSTER
Name = strsplit(DIR,filesep);
Name = Name{end};

if exist('TIC','var')==0
    tStartJob = tic;
else
    tStartJob = TIC;
end

fprintf(1,'\n\tCreating job...');
if exist('CLUSTER','var')==0 % Otherwise, use "default" profile
    fprintf(1,'Searching for Idle Workers...');
    CLUSTER = findGoodCluster('CLUSTER_LIST',CLUSTER_LIST,...
                              'NWR',NWR, ...
                              'WAIT_TIME',WAIT_TIME, ...
                              'INIT_TIME',INIT_TIME);
    fprintf(1,'Beating them into submission...');
end
myCluster = parcluster(CLUSTER);

myJob     = createCommunicatingJob(myCluster, ...
          'Type','pool', ...
          'Name', ['qMEMfreq ' Name], ...
          'NumWorkersRange', NWR, ...
          'FinishedFcn',@JobFinishedAlert, ...
          'Tag', ['Queued: MEM LFP estimation ' Name '...']);
                    
createTask(myJob,@mmMEMfreq,0,IN_ARGS);
fprintf(1,'complete. Submitting to %s...\n',CLUSTER);
submit(myJob);
fprintf(1,'\n\n\n----------------------------------------------\n\n');
wait(myJob, 'queued');
fprintf(1,'Queued job:  %s\n',Name);
fprintf(1,'\n');
wait(myJob, 'running');
pause(10);
fprintf(1,'\n');
fprintf(1,'->\tJob running.\n');
fprintf(1,'Using Server: %s\n->\t %d/%d workers assigned.\n', ...
        CLUSTER,...
        myCluster.NumBusyWorkers, myCluster.NumWorkers);

fprintf(1,'Job [%s] submitted to server. Total time elapsed:\n', Name);
ElapsedTime(tStartJob);

end