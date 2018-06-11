function StimTS = ExtractStimTS(varargin)
%% EXTRACTSTIMTS    Extracts stimulation timestamps from full TDT data file
%
%   StimTS = EXTRACTSTIMTS('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin        :       (Optional) 'NAME', value input argument pairs.
%
%   --------
%    OUTPUT
%   --------
%    StimTS         :       Struct containing the name of the animal, the
%                           stimulation time stamps, the phase, and the
%                           value of the current for each stim time.
%
%   By: Max Murphy  v1.2    06/10/2017  Update to work with new extraction
%                                       methods, as well as new TDT circuit
%                                       that uses 'Tick' to update sect as
%                                       opposed to 'SHIT' epocs.
%                   v1.1    02/09/2017  Update path to accurately reflect
%                                       current server addresses.
%                   v1.0    01/16/2017  Original Version

%% DEFAULTS
% Search path info
DIR ='P:\Rat\ITLProject';
SECT_PATH = '_Digital';

% Input file IDs
SECT_ID = '_Sect';
CURR_ID = '_Curr';
STIM_ID = '_STIM';

% Output
STIMTS_ID = '_StimTS';

%% PARSE VARARGIN
for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% SELECT RECORDING
% If pre-specified in optional arguments, skip this step.
if exist('NAME', 'var') == 0
    [NAME,DIR,fi] = uigetfile( ...
             {'*pNeuSnipInfo.mat', 'Pre-extracted pNeu File (*.mat)'; ...
              '*EpocSnipInfo.mat', 'Pre-extracted epoch File (*.mat)'; ...
              '*.mat', '(Large,old) Full-file extractions (*.mat)'}, ...
              'Select valid file for StimTS extraction', DIR);
    
    if NAME == 0 % Must select a directory
        error('Must select a valid directory.');
    end
    
else    % If file is pre-specified, must be valid
    if exist(NAME,'file')~=0 % If full path is specified in NAME, get DIR
        [DIR,NAME,ext] = fileparts(NAME);
        NAME = [NAME ext];
        DIR = [DIR filesep];
        fi = 2;
    elseif exist(fullfile(DIR,NAME),'file') == 0 %#ok<*NODEF>  
        DIR = strsplit(NAME,filesep);
        DIR = strjoin(DIR(1:end-1),filesep);
        [NAME,DIR,fi] = uigetfile( ...
            {'*pNeuSnipInfo.mat', 'Pre-extracted pNeu File (*.mat)'; ...
             '*EpocSnipInfo.mat', 'Pre-extracted epoch File (*.mat)'; ...
             '*.mat', '(Large,old) Full-file extractions (*.mat)'}, ...
             'Select valid file for StimTS extraction', DIR);
    end
end

% If not specified, set save location to be same as data file
if exist('SDIR','var')==0
    SDIR = DIR;
end

name = strsplit(DIR,filesep);
name = name{end-1};
pname = fullfile(DIR, [name SECT_PATH]);

%% LOAD
tic;
disp('-------------------------------------');
disp(['Loading ' name ' stimulation info...']);
StimFieldPresent = true;
switch fi
    case 1
        block = struct;
        block.epocs = struct;
        block.epocs.Sect = struct;
        block.epocs.STIM = struct;
        block.epocs.Curr = struct;
        
        % Load Sect info
        F = dir(fullfile(pname, [name '*' SECT_ID '*.mat']));
        if isempty(F)
            error(['No files found in ' ...
                pname ' with ID "' SECT_ID '".']);
        end
        if numel(F) > 1
            error(['Multiple files found in ' ...
                pname ' with ID "' SECT_ID '".']);
        end
        block.epocs.Sect = load(fullfile(pname,F.name));
        
        % Load STIM info
        F = dir(fullfile(pname, [name '*' STIM_ID '*.mat']));
        if isempty(F)
            error(['No files found in ' ...
                pname ' with ID "' STIM_ID '".']);
        end
        if numel(F) > 1
            error(['Multiple files found in ' ...
                pname ' with ID "' STIM_ID '".']);
        end
        block.epocs.STIM = load(fullfile(pname,F.name));
        
        % Load Curr info
        F = dir(fullfile(pname, [name '*' CURR_ID '*.mat']));
        if isempty(F)
            error(['No files found in ' ...
                pname ' with ID "' CURR_ID '".']);
        end
        if numel(F) > 1
            error(['Multiple files found in ' ...
                pname ' with ID "' CURR_ID '".']);
        end
        block.epocs.Curr = load(fullfile(pname,F.name));
        
    case 2
        load([DIR NAME]);
        if ~isfield(block.epocs,'STIM')
            StimFieldPresent = false;
        end
            
    case 3
        load([DIR NAME]);
    otherwise
        load([DIR NAME]);
end
disp('...complete.');
toc;

%% GET RELEVANT PARAMETERS
StimTS = struct;
    if StimFieldPresent
        StimTS.peak_train   = block.epocs.STIM.onset;
        StimTS.peak_val     = block.epocs.Curr.data;
    else
        StimTS.peak_train   = block.epocs.Tick.data;
        StimTS.peak_val     = zeros(size(StimTS.peak_train));
    end
    StimTS.name         = name;
    if isfield(block.epocs, 'Sect')
        StimTS.phase        = block.epocs.Sect.data;
        StimTS.phase_ts     = block.epocs.Sect.onset;
    else
        if (exist(pname,'dir')==0 || ~StimFieldPresent)
            warning('No "Sect" info detected.');
            StimTS.phase        = nan;
        else
            F = dir(fullfile(pname, [name '*' SECT_ID '*.mat']));
            if isempty(F)
                error(['No files found in ' ...
                    pname ' with ID "' SECT_ID '".']);
            end

            if numel(F) > 1
                error(['Multiple files found in ' ...
                    pname ' with ID "' SECT_ID '".']);
            end

            sect = load(fullfile(pname,F.name));
            StimTS.phase = sect.data;
            StimTS.phase_ts = sect.onset;
        end
    end

clear block

%% SAVE
if exist(SDIR,'dir')==0
    mkdir(SDIR);
end

save([SDIR name STIMTS_ID '.mat'], 'StimTS', '-v7.3');

end