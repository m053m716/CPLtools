function adHocExtract_TDT(varargin)
%% ADHOCEXTRACT_TDT  Extract TDT data from Recorded_Data on Isilon
%
%   ADHOCEXTRACT_TDT('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs
%                   -> 'DIR', (def: none; selected from UI)
%
%   --------
%    OUTPUT
%   --------
%   Extracts TDT data from blocks that have already been moved to the
%   server. Defaults to a UI to allow selection of block, but this can be
%   specified using 'NAME', value pairs. Extracted data is saved in
%   P:\Extracted_Data_To_Move\Rat\TDTRat
%
%   By: Max Murphy  v1.0    05/15/2017  Original version (R2017a)
%                   v1.1    07/07/2017  Daniel Rittle - Added modification
%                                       to facilitate processing of 
%                                       multiple files
%                   v1.2    07/08/2017  Max Murphy - Fixed some bugs with
%                                       multiple selection, should work as
%                                       intended now.
%                   v1.3    07/26/2017  Max Murphy - Limited number of
%                                       workers to [2 4] so that it doesn't
%                                       have to make as many copies on the
%                                       server.
%                   v1.4    07/29/2017  Max Murphy - Made sure that
%                                       extraction checks for NaN or Inf
%                                       values in RawData before filtering.
%
% See also: EXTRACT_MOVED_DATA, MOVERECORDEDDATA

%% DEFAULTS
DEFDIR = 'R:\Rat\TDTRat';   % Default UI search directory
ANIMALTYPE = 'Rat';         % Could also be Monkey
DATATYPE = 'TDT';           % Acquisition system (leave as TDT)

% For finding clusters
TIC = tic;
CLUSTER_LIST = {'CPLMJS'}; % MJS cluster profiles
NWR          = [1 1];     % Number of workers to use
WAIT_TIME    = 15;        % Wait time for looping if using findGoodCluster
INIT_TIME    = 2;         % Wait time before initializing findGoodCluster

LS = {'Yes'; 'No'};         % Choices to prompt for more selected days

%% PARSE VARARGIN
clc;
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if ~strcmp(DATATYPE,'TDT')
    error('Wrong extraction code.');
end

%% GET BLOCK TO READ
if exist('DIR','var')==0
    DIR = uigetdir(DEFDIR,'Select block');
    skip_ask_flag = false;
else
    if exist(DIR,'dir')==0
        error(['Invalid directory: ' DIR]);
    end
    skip_ask_flag = true;
end

%% FOR SELECTING MULTIPLE FOLDERS TO PROCESS
if ~skip_ask_flag
   [AnyMore,~] = listdlg('PromptString','Select Additional Directories?',...
            'SelectionMode','single',...
            'ListString',LS);
else
   AnyMore = 2;
end
   
if AnyMore == 1
    d = dir(DEFDIR);
    d = d(3:end);
    DIR2 = strsplit(DIR,'\');
    DIR2 = DIR2{end};
    counting = 1;
    for ii = 1:length(d)
        if d(ii,1).isdir == 1
            if strcmp(d(ii,1).name,DIR2) == 0
                d2(counting,1)=d(ii,1);
                counting = counting + 1;
            end
        end
    end
    d = d2;
    choosable_dir = {d.name};
    [chosenDir,~] = listdlg('PromptString','Which Directories?',...
            'SelectionMode','multiple',...
            'ListString',choosable_dir);
    DIRS = cell(1,length(chosenDir));
    for ii = 1:length(chosenDir)
        DIRS{1,ii} = strcat(DEFDIR,'\',d(chosenDir(ii),1).name);
    end
    DIRS = [DIR, DIRS];
else
    DIRS = {DIR};
end
%% GET GIT INFO AND FILES TO ATTACH
[repoPath, ~] = fileparts(mfilename('fullpath'));
addpath([repoPath filesep 'TDT']);
gitInfo = getGitInfo(repoPath);
attach_files = dir(fullfile(repoPath,'**'));
attach_files = attach_files((~contains({attach_files(:).folder},'.git')))';
dir_files = ~cell2mat({attach_files(:).isdir})';
ATTACHEDFILES = fullfile({attach_files(dir_files).folder}, ...
                         {attach_files(dir_files).name})';

%% SPECIFY FILE TO EXTRACT
curr_file_total = cell(1,numel(DIRS));
block_total = cell(1,numel(DIRS));
for ii = 1:numel(DIRS)
    temp = strsplit(DIRS{1,ii},filesep);
    block = temp{end};
    block_total{1,ii} = block;
    curr_file = {ANIMALTYPE,[DATATYPE ANIMALTYPE],block,gitInfo};
    curr_file_total{1,ii} = curr_file;
end

%% SET UP AND SUBMIT JOB TO CLUSTER
tStartJob = tic; % Get start time

if numel(DIRS) == 1
    Name = curr_file_total{1}{1,3};
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
    myJob = createCommunicatingJob(myCluster, ...
                           'AttachedFiles',ATTACHEDFILES, ...
                           'NumWorkersRange',NWR, ...
                           'Type', 'pool');
    createTask(myJob,@TDTExtraction_adhoc,0,curr_file_total);
    fprintf(1,'complete. Submitting to %s...\n',CLUSTER);
    submit(myJob);
    fprintf(1,'\n\n\n----------------------------------------------\n\n');
    wait(myJob, 'queued');
    fprintf(1,'Queued job:  %s\n',Name);
    fprintf(1,'\n');
    wait(myJob, 'running');
    fprintf(1,'\n');
        fprintf(1,'->\tJob running.\n');
    pause(60); % Needs about 1 minute to register all worker assignments.
    fprintf(1,'Using Server: %s\n->\t%d/%d workers assigned.\n',CLUSTER,...
            myCluster.NumBusyWorkers, myCluster.NumWorkers);
    fprintf(1,'Job [%s] submitted to server. Total time elapsed:\n', Name);
    ElapsedTime(tStartJob);
else
    for ii = 1:numel(DIRS)
        Name = curr_file_total{1,ii}{3};
        fprintf(1,'\n\tCreating job...');
        fprintf(1,'Searching for Idle Workers...');
        CLUSTER = findGoodCluster('CLUSTER_LIST',CLUSTER_LIST,...
                                  'NWR',NWR, ...
                                  'WAIT_TIME',WAIT_TIME, ...
                                  'INIT_TIME',INIT_TIME);
        fprintf(1,'Beating them into submission...');
        myCluster = parcluster(CLUSTER);
        myJob = createCommunicatingJob(myCluster, ...
         'AttachedFiles',ATTACHEDFILES, ...
         'Type','pool', ...
         'Name', Name, ...   
         'FinishedFcn', @JobFinishedAlert, ...
         'NumWorkersRange', NWR, ...
         'Type','pool', ...
         'Tag', ['Queued: single-channel extraction for ' ...
                 curr_file_total{1,ii}{3}]);
        createTask(myJob,@TDTExtraction_adhoc,0,curr_file_total{1,ii});
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
        fprintf(1,'Using Server: %s\n->\t%d/%d workers assigned.\n', ...
                CLUSTER,...
                myCluster.NumBusyWorkers, myCluster.NumWorkers);
        
        fprintf(1,'Job [%s] submitted to server. Total time elapsed:\n', Name);
        ElapsedTime(tStartJob);
    end
end
toc(TIC);

end