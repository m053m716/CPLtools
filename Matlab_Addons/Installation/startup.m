%% SCRIPT RUNS WHEN MATLAB STARTS UP
clc;

% Get startup directory
STARTUP_DIR = mfilename('fullpath');
STARTUP_DIR = strsplit(STARTUP_DIR,filesep);
STARTUP_DIR = strjoin(STARTUP_DIR(1:end-1),filesep);
dirfile = fullfile(STARTUP_DIR,'defaults.mat');

fprintf('\n\tRunning startup routine...\n');

% Load files
if exist(dirfile,'file')
    load(dirfile);
else
    warning(['"defaults.mat" not in start-up directory.' ... 
             ' Add-on functions not available on current path.']);
    save(dirfile,'STARTUP_DIR');
end

%% ADD DIRECTORY WITH "EXTRA" DEFAULT FUNCTIONS
if exist('ADDON_DIR','var')~=0
    if exist(ADDON_DIR,'dir')==0
        ADDON_DIR = uigetdir('C:','Select add-on directory');
        if ADDON_DIR==0
            warning('Add-on functions not available on current path.');
        else
            save(dirfile,'ADDON_DIR','-append');
            addpath(genpath(ADDON_DIR));
            fprintf('\n\t\t-> Custom add-ons specified successfully.\n\n');
        end
    else
        addpath(genpath(ADDON_DIR));
        fprintf('\n\t\t-> Custom add-ons specified successfully.\n\n');
    end
else
    warning('ADDON_DIR variable not found in "defaults.mat"');
    ADDON_DIR = uigetdir('C:','Select add-on directory');
    if ADDON_DIR==0
        warning('Add-on functions not available on current path.');
    else
        save(dirfile,'ADDON_DIR','-append');
        addpath(genpath(ADDON_DIR));
        fprintf('\n\t\t-> Custom add-ons specified successfully.\n\n');
    end
end

%% MOVE TO THE DEFAULT DIRECTORY
if exist('DEFAULT_START_DIR','var')~=0
    if exist(DEFAULT_START_DIR,'dir')==0
        DEFAULT_START_DIR = uigetdir('C:','Select default start directory');
        if DEFAULT_START_DIR ==0
            warning('Default start path not specified.');
        else
            save('defaults.mat','DEFAULT_START_DIR','-append');
            cd(DEFAULT_START_DIR);
        end
    else
        cd(DEFAULT_START_DIR);
    end
else
    warning('"DEFAULT_START_DIR" variable not found in "defaults.mat"');
    DEFAULT_START_DIR = uigetdir('C:','Select default start directory');
    if DEFAULT_START_DIR ==0
        warning('Default start path not specified.');
    else
        save('defaults.mat','DEFAULT_START_DIR','-append');
        cd(DEFAULT_START_DIR);
    end
end

%% CLEAR BASE WORKSPACE OF ANY VARIABLES
clear;
