function adHocExtract_Intan(varargin)
%% ADHOCEXTRACT_Intan  Extract Intan data from Recorded_Data on Isilon
%
%   ADHOCEXTRACT_Intan('NAME',value,...)
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
%   Extracts RHD/RHS data from blocks that have already been moved to the
%   server. Defaults to a UI to allow selection of block, but this can be
%   specified using 'NAME', value pairs. Extracted data is saved in
%   P:\Extracted_Data_To_Move\Rat\Intan
%
%   By: Max Murphy  v1.0    08/16/2017 (Mostly ripped off from
%                                       adHocExtract_TDT)
%
% See also: EXTRACT_MOVED_DATA, MOVERECORDEDDATA, ADHOCEXTRACT_TDT

%% DEFAULTS
DEF_DIR = 'R:\Rat\Intan';   % Default UI search directory
SAVELOC = 'P:\Extracted_Data_To_Move\Rat\Intan';
ANIMALTYPE = 'Rat';         % Could also be Monkey
DATATYPE = 'Intan';         % Acquisition system (leave as TDT)
STIM_SUPPRESS = false;      % set true to do stimulus suppression (must change STIM_P_CH also)
STIM_P_CH = [nan nan];      % [probe, channel] for stimulation channel
STIM_BLANK = [0.2 1.75];    % [pre stim ms, post stim ms] for offline suppress
STATE_FILTER = true;

% For finding clusters
CLUSTER_LIST = {'CPLMJS'; ...
                'CPLMJS2'; ... % MJS profiles to use
                'CPLMJS3'};     
NWR          = [1 2];     % Number of workers to use
WAIT_TIME    = 60;        % Wait time for looping if using findGoodCluster
INIT_TIME    = 2;         % Wait time before initializing findGoodCluster

UNC_PATH = {'\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data\'; ...
            '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\'};

%% PARSE VARARGIN
clc;
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

addpath(DATATYPE);

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
F = dir(fullfile(DIR,[Name '*.rh*']));

if numel(F) > 1
   ind = listdlg('PromptString','Select files to extract:',...
               'SelectionMode','multiple',...
               'ListString',{F.name}.');
   temp = F;
   F = cell(numel(ind),1);
   iCount = 1;
   for iF = ind
      F{iCount} = temp(iF).name;
      iCount = iCount + 1;
   end
   clear temp
else
   F = {F.name};
end


ftype = cell(numel(F),1);
for iF = 1:numel(F)
    ftype{iF} = F{iF}(end-2:end);
end

DIR = [UNC_PATH{1} DIR((find(DIR == filesep,1,'first')+1):end)];  
SAVELOC = [UNC_PATH{2} SAVELOC((find(SAVELOC == filesep,1,'first')+1):end)];

%% GET CLUSTER WITH AVAILABLE WORKERS
for iF = 1:numel(F)
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
                 'Tag', ['Extracting INTAN files for: ' Name '...']);
    
    IN_ARGS = {'NAME',fullfile(DIR,F{iF}),...
               'SAVELOC',SAVELOC,...
               'GITINFO',gitInfo,...
               'STIM_SUPPRESS',STIM_SUPPRESS,...
               'STIM_P_CH',STIM_P_CH,...
               'STIM_BLANK',STIM_BLANK,...
			   'STATE_FILTER',STATE_FILTER};
                   
    switch(ftype{iF})
        case 'rhs'   
            createTask(j, @INTAN2single_RHS2000, 0,{IN_ARGS});
        case 'rhd'
            createTask(j, @INTAN2single_ch_wCAR, 0,{IN_ARGS});
        otherwise
            error('Invalid file-type: %s',ftype{iF});
    end
    
    fprintf(1,'Submitting...');
    submit(j);
    pause(WAIT_TIME);
    fprintf(1,'complete.\n');
end

end