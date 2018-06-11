function qSplitSort(varargin)
%% QSPLITSORT   Queue AA_SPLITSORT to run on Isilon cluster.
%
%   QSPLITSORT('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%
%                   -> 'DIR' : (default - none; specified using GUI. If
%                               entered as 'NAME', value, input pair, skips
%                               GUI (good for looping)).
%
%   --------
%    OUTPUT
%   --------
%   AA_SPLITSORT is queued to run on the specified Isilon cluster, which
%   can handle the very large file sizes required during the loading
%   process.
%
% By: Max Murphy    v1.1    07/26/2017  Added option 'FIND_CLUSTER' which
%                                       allows specification of a single
%                                       cluster.
%                   v1.0    06/09/2017  Original version (R2017a)
%   See also: AA_SPLITSORT, SORTCLUSTERS, SPIKEDETECTCLUSTER

%% DEFAULTS
DEF_DIR = 'P:\Rat\PopulationDynamics';  % Likely directory
PT_ID = '_PhaseTime.mat';               % PhaseTime file ID
FS_DEF = 24414.0625;                    % Default sampling frequency

% For finding clusters
CLUSTER_LIST = {'CPLMJS'; 'CPLMJS2'; 'CPLMJS3'}; % MJS cluster profiles
NWR          = [2,4];     % Number of workers to use
WAIT_TIME    = 15;        % Wait time for looping if using findGoodCluster
INIT_TIME    = 2;         % Wait time before initializing findGoodCluster

% Isilon path to "Processed Data"
UNC_PATH = '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\';

%% PARSE INPUT
IN_ARGS = {FS_DEF};

for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
    IN_ARGS{1,iV+1} = varargin{iV};
    IN_ARGS{1,iV+2} = varargin{iV+1};
end

if exist('FS','var')~=0 % Allow modification of FS through varargin
    IN_ARGS{1} = FS;
end

%% GET INPUT DIRECTORY
if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR,'Select block to be split');
    if DIR == 0
        error('No directory selected. Script canceled.');
    end
else
    if exist(DIR,'dir')==0 %#ok<*NODEF>
        error('Check DIR; invalid directory.');
    end
end

% Get corresponding T_SPLIT and EPOCH_LABEL, or throw error
bk = strsplit(DIR,filesep);
bk = bk{end};

if exist(fullfile(DIR,[bk PT_ID]),'file')==0
    disp(['No ' PT_ID ' file in ' DIR]);
    error('Run ExtractStimTS.m then aa_getSectTimes.m first.');
else
    load(fullfile(DIR,[bk PT_ID]),'EPOCH_LABEL','T_SPLIT');    
end

% Get corresponding Isilon address
DIR = [UNC_PATH DIR((find(DIR == filesep,1,'first')+1):end)];

%% CREATE JOB AND SUBMIT TO ISILON
IN_ARGS = [IN_ARGS, {'DIR', DIR, ...
                     'USE_CLUSTER',true, ...
                     'EPOCH_LABEL', EPOCH_LABEL, ...
                     'T_SPLIT', T_SPLIT}];
Name = strsplit(DIR, filesep);
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
          'Name', ['qSplitSort ' Name], ...
          'NumWorkersRange', NWR, ...
          'FinishedFcn',@JobFinishedAlert, ...
          'Tag', ['Queued: split long recording into periods for ' Name]);
                    
createTask(myJob,@aa_SplitSort,0,IN_ARGS);
fprintf(1,'complete. Submitting to %s...\n',CLUSTER);
submit(myJob);
fprintf(1,'\n\n\n----------------------------------------------\n\n');
wait(myJob, 'queued');
fprintf(1,'Queued job:  %s\n',Name);
fprintf(1,'\n');
wait(myJob, 'running');
pause(60); % Needs about 1 minute to register all worker assignments.
fprintf(1,'\n');
fprintf(1,'->\tJob running.\n');
fprintf(1,'Using Server: %s\n->\t %d/%d workers assigned.\n', ...
        CLUSTER,...
        myCluster.NumBusyWorkers, myCluster.NumWorkers);

fprintf(1,'Job [%s] submitted to server. Total time elapsed:\n', Name);
ElapsedTime(tStartJob);


end