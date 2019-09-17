function qDS(varargin)
%% QDS  Queue job for down-sampling (DS) of Raw Data for LFP analysis.
%
%   QDS;
%   QDS(pars);
%   QDS('NAME',value,...);
%
%   example:
%
%   TIC = tic;
%   load([DATA_STRUCTURE_NAME],'F'); % F contains DIR which lists blocks
%   for iF = 1:numel(F)
%       qDS('DIR',F(iF).block,'TIC',TIC,'CLUSTER_LIST',{'CPLMJS2';'CPLMJS3});
%   end
%   beep;
%
%   The above code will run on a loop, queueing all the blocks listed in
%   the F struct in the 'DIR' field, until completion. By specifying
%   CLUSTER_LIST as only CPLMJS2 and CPLMJS3, you avoid running on CPLMJS,
%   which may get interrupted if somebody runs the automated extraction
%   after surgery at the end of the day. Adding beep will make Matlab beep
%   at you since you will run this loop on a Matlab client in the
%   background and if you want to do more work on Matlab, right-click the
%   Matlab icon and click Matlab 2017a to start a new instance of Matlab
%   which you can actually run things on your local machine from.
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME',value input argument pairs.
%
%       -> 'DIR' // (Def: none) If specified, skips the UI selection of
%                   BLOCK directory.
%
%       -> 'TIC' // (Def: none) If specified, can be used to hold a
%                    previous start time in order to get an idea of how
%                    long for example a loop has been running.
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
%   --------
%    OUTPUT
%   --------
%   Queues MMDS to the Matlab Job Server (MJS; currently, CPLMJS / CPLMJS2
%   / CPLMJS3), which is capable of running the code faster and storing
%   longer recordings in its working memory.
%
% By: Max Murphy    v1.0    08/15/2017  Original version (R2017a)
%   
%   See also: MMDS, MMMEMFREQ

%% DEFAULTS
% Directory info
DEF_DIR = 'P:/Rat';

% For finding clusters
CLUSTER_LIST = {'CPLMJS'; 'CPLMJS2'; 'CPLMJS3'}; % MJS cluster profiles
NWR          = [1,2];     % Number of workers to use
WAIT_TIME    = 0.5;        % Wait time for looping if using findGoodCluster
INIT_TIME    = 0.1;         % Wait time before initializing findGoodCluster

%% PARSE VARARGIN
if nargin==1
    IN_ARGS = varargin{1};
    if ~isfield(IN_ARGS,'DIR')
        IN_ARGS.DIR = uigetdir(DEF_DIR,'Select block to be split');
        if IN_ARGS.DIR == 0
            error('No directory selected. Script canceled.');
        end
    else
        if exist(IN_ARGS.DIR,'dir')==0 %#ok<*NODEF>
            error('Check pars:\n\t%s is not a valid directory.',...
                IN_ARGS.DIR);
        end
    end
    DIR = IN_ARGS.DIR;
else
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
    IN_ARGS = [IN_ARGS, {'DIR',DIR}];
end
IN_ARGS = [IN_ARGS, {'USE_CLUSTER',true}];

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
          'Name', ['qDS ' Name], ...
          'NumWorkersRange', NWR, ...
          'FinishedFcn',@JobFinishedAlert, ...
          'Tag', ['Queued: DS ' Name '...']);
                    
createTask(myJob,@mmDS,0,IN_ARGS);
fprintf(1,'complete. Submitting to %s...\n',CLUSTER);
submit(myJob);
fprintf(1,'\n\n\n----------------------------------------------\n\n');
wait(myJob, 'queued');
fprintf(1,'Queued job:  %s\n',Name);
fprintf(1,'\n');
wait(myJob, 'running');
pause(0.25);
fprintf(1,'\n');
fprintf(1,'->\tJob running.\n');
fprintf(1,'Using Server: %s\n->\t %d/%d workers assigned.\n', ...
        CLUSTER,...
        myCluster.NumBusyWorkers, myCluster.NumWorkers);

fprintf(1,'Job [%s] submitted to server. Total time elapsed:\n', Name);
ElapsedTime(tStartJob);


end