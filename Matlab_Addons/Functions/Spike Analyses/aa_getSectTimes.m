function [T_SPLIT,EPOCH_LABEL] = aa_getSectTimes(varargin)
%% AA_GETSECTTIMES  Gets the section times for chronic stimulation study
%
%   T_SPLIT = AA_GETSECTTIMES('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs
%
%                       -> 'DIR' (default: N/A; prompts user for path using
%                                          a graphical interface. Should be
%                                          a string pointing to the BLOCK
%                                          path, if specified.)
%   --------
%    OUTPUT
%   --------
%   T_SPLIT     :   N x 2 matrix of start and stop times for splitting
%                   periods.
%
%   EPOCH_LABEL :   N x 1 cell array of section labels corresponding to
%                   T_SPLIT sections.
%
% By: Max Murphy    v1.0    06/10/2017  Original version (R2017a)
%   See also: AA_SPLITSORT, QSPLITSORT, AA_PSTH, EXTRACTSTIMTS

%% DEFAULTS
% PRESET START & STOP TIME
TSTART_PRESET = nan;        % Start time (seconds)
% Set this to 1200 for CONTROL experiments:
TRELSTART_PRESET = nan;     % Total duration of first section (seconds)
TSTOP_PRESET = nan;         % Final stop time (seconds)
% Set this to 1200 for CONTROL experiments:
TRELSTOP_PRESET = nan;      % Total duration of final section (seconds)

% Path identifiers
DEF_DIR     = 'P:\Rat\ITLProject';
SECT_PATH   = '_Digital';

% File identifiers
SECT_ID     = '_Sect';
STIMTS_ID   = '_StimTS';
CURR_ID     = '_Curr';
PHASE_ID    = '_PhaseTime';

% Default splitting times (seconds)
T_SPLIT_DEF = { ...
... for set of short, chronic recordings
              [0, 1200; ...         
            1200, 6000; ...      
            6000, 7200]; ...
... for set of long, chronic recordings
              [0, 1800; ...
            1800, 6600; ...
            6600, 8400; ...      
            8400, 10200; ...
           10200, 12000]; ...
... for splitting long, acute recordings
              [0, 600; ...       
             600, 4200; ...
            4200, 4800; ...
            4800, 8400; ...
            8400, 9000; ...
            9000, 12600; ...
           12600, 13200]}; 

% Default epoch labels (for split periods)
EPOCH_LABEL_DEF = {...
... for splitting short, chronic recordings
                  {'_01_nbasal'; ... 
                   '_02_Stim'; ...
                   '_03_nbasal'}; ...
... for splitting long, chronic recordings
                  {'_01_nbasal'; ... 
                   '_02_Stim'; ...
                   '_03_nbasal'; ...
                   '_04_nbasal'; ...
                   '_05_nbasal'}; ...
... for splitting long, acute recordings
                  {'_01_nbasal'; ... 
                   '_02_Stim'; ...
                   '_03_nbasal'; ...
                   '_04_Stim'; ...
                   '_05_nbasal'; ...
                   '_06_Stim'; ...
                   '_07_nbasal'}};


%% PARSE INPUT
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET DIRECTORY
if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR,'Select block for section time extraction');
    if DIR == 0
        error('No directory selected. Script canceled.');
    end
else
    if exist(DIR,'dir')==0 %#ok<NODEF>
        error('Check DIR; invalid directory.');
    end
end

name = strsplit(DIR,filesep);
name = name{end};
pname = fullfile(DIR, [name SECT_PATH]);

%% LOAD FILE AND EXTRACT TIMES (OR USE DEFAULTS IF NO PRECISE MEASURE)
% _StimTS.mat file does not exist
if exist(fullfile(DIR,[name STIMTS_ID '.mat']),'file')==0
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
    sect.phase(sect.phase<eps) = 1;
    stim_phases = unique(sect.phase);
    if abs(numel(stim_phases)-3) < eps
        T_SPLIT = T_SPLIT_DEF{1};
        EPOCH_LABEL = EPOCH_LABEL_DEF{1};
    elseif abs(numel(stim_phases)-5) < eps
        T_SPLIT = T_SPLIT_DEF{2};
        EPOCH_LABEL = EPOCH_LABEL_DEF{2};
    elseif abs(numel(stim_phases)-7) < eps
        T_SPLIT = T_SPLIT_DEF{3};
        EPOCH_LABEL = EPOCH_LABEL_DEF{3};
    else
        error('Number of sections mismatched with defaults.');
    end  
    
% _StimTS.mat file exists
else
    load(fullfile(DIR,[name STIMTS_ID '.mat']),'StimTS');
    % _StimTS.mat file exists and both phase fields are present
    if (isfield(StimTS,'phase') && isfield(StimTS,'phase_ts')) %#ok<*NODEF>
        StimTS.phase(StimTS.phase<eps) = 1;
        stim_phases = unique(StimTS.phase);
        if (StimTS.phase_ts(end)/60 > 195 && ... % Meet criteria for 
            StimTS.phase_ts(end)/60 < 205 && ... % "long" chronic recording
            abs(numel(stim_phases) - 5) > eps) % And WRONG # sections
            warning('%s may have had a section step skipped. CHECK.',name);
            T_SPLIT = T_SPLIT_DEF{2};
            EPOCH_LABEL = EPOCH_LABEL_DEF{2};
            for iT = 1:3 % Double-check the basal sessions bracketing stim
                t1 = find(abs(StimTS.phase-stim_phases(iT))<eps,1,'first');
                t2 = find(abs(StimTS.phase-stim_phases(iT))<eps,1,'last');
                if t1 > 1
                    t1 = t1 - 1;
                end
                T_SPLIT(iT,1) = StimTS.phase_ts(t1);
                T_SPLIT(iT,2) = StimTS.phase_ts(t2);
            end
        else
            T_SPLIT = nan(numel(stim_phases),2);
            for iT = 1:numel(stim_phases)
                t1 = find(abs(StimTS.phase-stim_phases(iT))<eps,1,'first');
                t2 = find(abs(StimTS.phase-stim_phases(iT))<eps,1,'last');
                if t1 > 1
                    t1 = t1 - 1;
                end
                T_SPLIT(iT,1) = StimTS.phase_ts(t1);
                T_SPLIT(iT,2) = StimTS.phase_ts(t2);
            end
            if abs(numel(stim_phases)-3) < eps
                EPOCH_LABEL = EPOCH_LABEL_DEF{1};
            elseif abs(numel(stim_phases)-5) < eps
                EPOCH_LABEL = EPOCH_LABEL_DEF{2};
            elseif abs(numel(stim_phases)-6) <eps 
                EPOCH_LABEL = EPOCH_LABEL_DEF{2};
            elseif abs(numel(stim_phases)-7) < eps
                EPOCH_LABEL = EPOCH_LABEL_DEF{3};
            else
                if exist('T_SPLIT_SPECIAL','var')==0
                    error('Number of sections mismatched with defaults.');
                else
                    T_SPLIT = T_SPLIT_SPECIAL;
                    EPOCH_LABEL = EPOCH_LABEL_SPECIAL;
                end
            end
        end
    % _StimTS.mat file exists, but no phase_ts field
    elseif isfield(StimTS,'phase') 
        if abs(numel(StimTS.phase)-numel(StimTS.peak_val)) < eps
            StimTS.phase(StimTS.phase<eps) = 1;
            stim_phases = unique(StimTS.phase);
            if abs(numel(stim_phases)-3) < eps
                T_SPLIT = T_SPLIT_DEF{1};
                EPOCH_LABEL = EPOCH_LABEL_DEF{1};
            elseif abs(numel(stim_phases)-5) < eps
                T_SPLIT = T_SPLIT_DEF{2};
                EPOCH_LABEL = EPOCH_LABEL_DEF{2};
            elseif abs(numel(stim_phases)-7) < eps
                T_SPLIT = T_SPLIT_DEF{3};
                EPOCH_LABEL = EPOCH_LABEL_DEF{3};
            else
                error('Number of sections mismatched with defaults.');
            end   
    % _StimTS.mat file exists, but no phase or phase_ts fields
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
            sect.phase(sect.phase<eps) = 1;
            stim_phases = unique(sect.phase);
            if abs(numel(stim_phases)-3) < eps
                T_SPLIT = T_SPLIT_DEF{1};
                EPOCH_LABEL = EPOCH_LABEL_DEF{1};
            elseif abs(numel(stim_phases)-5) < eps
                T_SPLIT = T_SPLIT_DEF{2};
                EPOCH_LABEL = EPOCH_LABEL_DEF{2};
            elseif abs(numel(stim_phases)-7) < eps
                T_SPLIT = T_SPLIT_DEF{3};
                EPOCH_LABEL = EPOCH_LABEL_DEF{3};
            else
                error('Number of sections mismatched with defaults.');
            end  
        end
        
    end
end

%% SAVE OUTPUT PHASE DURATIONS IN PHASE TIME MAT FILE
phaseTime = nan(size(T_SPLIT,1),1);
for iT = 1:size(T_SPLIT,1)
    % Get phase time (minutes)
    phaseTime(iT) = (T_SPLIT(iT,2) - T_SPLIT(iT,1))/60;
end

if ~isnan(TSTART_PRESET)
    T_SPLIT(1,1) = TSTART_PRESET;
    phaseTime(1) = (T_SPLIT(1,2) - T_SPLIT(1,1))/60;
    
end

if ~isnan(TRELSTART_PRESET)
    T_SPLIT(1,1) = T_SPLIT(1,2) - TRELSTART_PRESET;
    phaseTime(1) = (T_SPLIT(1,2) - T_SPLIT(1,1))/60;
    if phaseTime(1) <= 0
        error('Non-positive start phase duration.');
    end
end

if ~isnan(TSTOP_PRESET)
    T_SPLIT(end,2) = TSTOP_PRESET;
    phaseTime(end) = (T_SPLIT(end,2) - T_SPLIT(end,1))/60;
    if phaseTime(end) <= 0
        error('Non-positive end phase duration.');
    end
end

if ~isnan(TRELSTOP_PRESET)
    T_SPLIT(end,2) = T_SPLIT(end,1) + TRELSTOP_PRESET;
    phaseTime(end) = (T_SPLIT(end,2) - T_SPLIT(end,1))/60;
    if phaseTime(end) <= 0
        error('Non-positive end phase duration.');
    end
end

save(fullfile(DIR,[name PHASE_ID '.mat']),'phaseTime', ...
            'T_SPLIT','EPOCH_LABEL','-v7.3');

end