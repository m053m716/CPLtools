function MicroDExtraction(files_in)
%IMPORTFILE Import numeric data from a text file as a matrix.
%   TRIAL2 = IMPORTFILE(FILENAME) Reads data from text file FILENAME for
%   the default selection.
%

mdfiles = [];
if isempty(strfind(files_in{1,3},'.lvm'))
    hold_mdfiles = dir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data',files_in{1,1},files_in{1,2},files_in{1,3}));
    mdfiles = {hold_mdfiles(~cell2mat({hold_mdfiles.isdir})).name}';
end

folder1 = files_in{1,1};
folder2 = files_in{1,2};
folder3 = files_in{1,3};

fs = 35714;
probe = '_P1_';
ani = files_in{1,3}(1:(find(files_in{1,3} == '_',1,'first')-1));
trial = files_in{1,3}((find(files_in{1,3} == '_',1,'first')+1):end);

% Create folder structure in 'Extracted_Data_To_Move' folder
if ~exist(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani),'dir')
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani))
end

if ~exist(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,trial),'dir')
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,trial))
end

if ~exist(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,trial,[trial '_RawData']),'dir')
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,trial,[trial '_RawData']))
end

if ~exist(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,trial,[trial '_Digital']),'dir')
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,trial,[trial '_Digital']))
end

for x = 1:length(mdfiles)
    [data,spikes] = LVM2mat(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data',folder1,folder2,folder3,mdfiles{x})); %#ok<*ASGLU>
    if isempty(data)
       continue
    end
    chan = mdfiles{x}((find(mdfiles{x} == '_',1,'last')+1):(find(mdfiles{x} == '_',1,'last')+3));
    parsave(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',folder1,folder2,ani,trial,[trial '_RawData'],[trial '_Raw' probe 'Ch_' chan '.mat']),'data',data,'fs',fs);
    parsave(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',folder1,folder2,ani,trial,[trial '_Digital'],[trial '_SPKS' probe 'Ch_' chan '.mat']),'spikes',spikes);
end