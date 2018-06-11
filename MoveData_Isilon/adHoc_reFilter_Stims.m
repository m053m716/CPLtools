function adHoc_reFilter_Stims(probe,ch,varargin)
%% ADHOC_REFILTER_STIMS  Do filtering and CAR after suppressing stims
%
%   ADHOC_REFILTER_STIMS('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%     probe     :   Stimulation probe number (A==1, B==2,...).
%
%     ch        :   Stimulation channel (Intan-side).
%
%   varargin    :   (Optional) 'NAME', value input argument pairs
%                   -> 'DIR', (def: none; selected from UI)
%
%   --------
%    OUTPUT
%   --------
%   Extracts RHD/RHS data from blocks that have already been moved to the
%   server. Defaults to a UI to allow selection of block, but this can be
%   specified using 'NAME', value pairs. Extracted data is saved in
%   P:\Extracted_Data_To_Move\Rat\Intan
%
%   By: Max Murphy  v1.0    08/16/2017 (Mostly ripped off from
%                                       adHocExtract_TDT)
%                   v1.1    02/28/2018  Trying to change the "blanking"
%                                       method to just interpolate the
%                                       signal between points before and
%                                       after the stimulus, since setting
%                                       to 0 may introduce arbitrary
%                                       high-frequency ringing in filtered
%                                       signal.
%
% See also: EXTRACT_MOVED_DATA, MOVERECORDEDDATA, ADHOCEXTRACT_TDT

%% DEFAULTS
DEF_DIR = 'P:\Rat';        % Default UI search directory

STIM_SUPPRESS = false;      % set true to do stimulus suppression (must change STIM_P_CH also)
STIM_P_CH = [nan nan];      % [probe, channel] for stimulation channel
STIM_BLANK = [0.5 2];       % [pre stim ms, post stim ms] for offline suppress
ANCHOR = 5;

% For finding clusters
CLUSTER_LIST = {'CPLMJS2'; ... % MJS profiles to use
                'CPLMJS3'};     
NWR          = [1 2];     % Number of workers to use
WAIT_TIME    = 60;        % Wait time for looping if using findGoodCluster
INIT_TIME    = 2;         % Wait time before initializing findGoodCluster

%% PARSE VARARGIN
clc;
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET CURRENT VERSION INFORMATION
[repoPath, ~] = fileparts(mfilename('fullpath'));
gitInfo = getGitInfo(repoPath);
attach_files = dir(fullfile(repoPath,'**'));
attach_files = attach_files((~contains({attach_files(:).folder},'.git')))';
dir_files = ~cell2mat({attach_files(:).isdir})';
ATTACHED_FILES = fullfile({attach_files(dir_files).folder},...
                          {attach_files(dir_files).name})';

%% GET BLOCK TO READ
if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR,'Select recording BLOCK');
    if DIR == 0
        error('No selection made. Script aborted.');
    end
end
Name = strsplit(DIR,filesep);
Name = Name{numel(Name)};

%% GET CLUSTER WITH AVAILABLE WORKERS

if exist('CLUSTER','var')==0 % Otherwise, use "default" profile
   fprintf(1,'Searching for Idle Workers...');
   CLUSTER = findGoodCluster('CLUSTER_LIST',CLUSTER_LIST,...
      'NWR',NWR, ...
      'WAIT_TIME',WAIT_TIME, ...
      'INIT_TIME',INIT_TIME);
   fprintf(1,'Beating them into submission...');
end



myCluster = parcluster(CLUSTER);
fprintf(1,'Creating Job...');
j = createCommunicatingJob(myCluster, 'AttachedFiles', ATTACHED_FILES,...
   'Type', 'pool', ...
   'Name', ['adhoc Intan extraction ' Name], ...
   'NumWorkersRange', NWR, ...
   'FinishedFcn', @JobFinishedAlert, ...
   'Type','pool', ...
   'Tag', ['Re-Filtering and suppressing stims for: ' Name '...']);

IN_ARGS = {probe,ch,'DIR',DIR,...
   'STIM_SUPPRESS',STIM_SUPPRESS,...
   'STIM_P_CH',STIM_P_CH,...
   'STIM_BLANK',STIM_BLANK,...
   'ANCHOR',ANCHOR,...
   'USE_CLUSTER',true};


createTask(j, @reFilter_Stims, 0,{IN_ARGS});

fprintf(1,'Submitting...');
submit(j);
pause(WAIT_TIME);
fprintf(1,'complete.\n');

end