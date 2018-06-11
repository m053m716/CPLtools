clearvars; clc; close all

[repoPath, ~] = fileparts(mfilename('fullpath'));
gitInfo = getGitInfo(repoPath);

if isempty(gitInfo)
    gitInfo = NaN;
end

dl = driveletter;
rec_directory = fullfile(dl,'Recorded_Data');
% rec_directory = uigetdir('D:\','Recorded_Data - Local (From)');

mv_directory = '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data'; %uigetdir('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data','Recorded_Data - Isilon (To)');
ext_directory = '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Move_Status'; %uigetdir('C:\','Check_Extraction');

hWait = waitbar(0,'Starting File Move...');
tName = tempname;
[~,tName] = fileparts(tName);
tName = tName(randsample(1:length(tName),5,false));
dt = date;
mv_filename = ['Moved_' dt '_' tName '.mat'];

files_moved = MoveRecordedData(rec_directory,mv_directory,ext_directory,mv_filename);

waitbar(0.5,hWait,'Files Moved. Starting Extraction...')

Cluster = 'CPLMJS';
myCluster = parcluster(Cluster);
num_workers = myCluster.NumWorkers;

% attach_files = strsplit(genpath('E:\GitRepos\MoveData_Isilon'),';')';
attach_files = dir(fullfile(repoPath,'**'));
attach_files = attach_files((~contains({attach_files(:).folder},'.git')))';
dir_files = ~cell2mat({attach_files(:).isdir})';
ATTACHEDFILES = fullfile({attach_files(dir_files).folder},{attach_files(dir_files).name})';

j = createCommunicatingJob(myCluster, 'AttachedFiles', ATTACHEDFILES, 'Type', 'pool');
j.NumWorkersRange = num_workers;

createTask(j, @Extract_Moved_Data, 0, {{[files_moved repmat({gitInfo},size(files_moved,1),1)]}});

submit(j);
% wait(j,'finished')
% delete(j);

waitbar(1,hWait,'Files Moved and Extracted.')
pause(5)
delete(hWait)