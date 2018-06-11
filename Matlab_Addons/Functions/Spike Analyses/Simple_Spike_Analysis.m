function [D,SPK] = Simple_Spike_Analysis(varargin)
%% SIMPLE_SPIKE_ANALYSIS   Good first step for after SORTCLUSTERS
%
%   [D,SPK] = SIMPLE_SPIKE_ANALYSIS('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%     'DIR'     :   [Default: specified in directory selection UI]
%                   Can be specified as a path to either the main folder
%                   for a given rat, or a sub-folder for a specific
%                   recording (block) to extract only that block's info.
%
%     Otherwise :
%
%     Any 'NAME', value pair to specify a variable listed in the DEFAULTS
%     section.
%
%       'RAT_END'   :   Stop index of Rat name in block filename 
%                       (default: 6; set to 5 for tDCS analysis!)
%
%     -> OTHER SPECIAL CASES <-
%    
%       SPECIFYING EITHER OF THE FOLLOWING REMOVES 'SNIPS' FIELD:
%   
%       'ISTART'    :   Start index (default: 1)
%
%       'ISTOP'     :   Stop index (default: number of samples in record)
%
%       'INSERT_TAG':   Must be specified together with SAVE_DIR. Specifies
%                       name to insert in front of SAVE_ID for output file.
%
%       'SAVE_DIR':     Must be specified together with INSERT_TAG.
%                       Specifies base directory where the output file will
%                       be saved.
%
%   --------
%    OUTPUT
%   --------
%       D       :      Matlab table with C rows, where C is the total
%                      number of clusters identified.
%                       - Rat
%                       - Block
%                       - Channel
%                       - Cluster
%                       - NumSpikes
%                       - Duration
%                       - Rate
%                       - Regularity
%
%
%       SPK     :       Matlab table with C rows, where C is the total
%                       number of clusters identified.
%                       - Peaks
%                       - Snips
%                       - fs
%
% By: Max Murphy    v1.1    04/28/2017  Added more ease-of-use features.
%                   v1.0    04/07/2017  Original version (R2017a)

%% DEFAULTS
DEF_DIR = 'P:\Rat';      % Default directory for UI selection
LIB_DIR = 'libs';        % Library directory for added functions
FS = 20000;              % Used if 'pars' struct is not found
SHOW_PROGRESS = true;    % Shows progress bar by default
USE_SPK_SUB_DIR = true;  % Use sub-directory for "good" spikes
USE_START_STOP = true;   % Use 'START' and 'STOP' times in save name
RAT_START = 1;           % Starting index of RAT in block name
RAT_END = 6;             % Ending index of RAT in block name
                         % (for tDCS, change to 5)

% Warning suppression
W_ID = 'MATLAB:load:variableNotFound';
    
% Names of directories where spikes are kept
SPK_DIR = '_ad-PT_SPC_Clusters';
CAR_SPK_DIR = '_ad-PT_SPC_CAR_Clusters';
SUB_DIR = 'Good';
SAVE_ID = '_SpikeSummary.mat';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

% Add any new paths
addpath(genpath(LIB_DIR));
warning('off',W_ID);

% This tries to help in case of weird mapping names
if exist(DEF_DIR,'dir')==0
    DEF_DIR = 'T:';
end

% Check for ISTART and ISTOP, if nonexistant then use whole recording
if exist('ISTART','var')==0
    startflag = true;
    ISTART = 1;
    START_STR = '0000';
else
    startflag = false;
    START_STR = num2str(round(ISTART/FS/60),'%04d');
end

if exist('ISTOP','var')==0
    stopflag = true;
    STOP_STR = 'stop';
else
    stopflag = false;
    STOP_STR = num2str(round(ISTOP/FS/60),'%04d');
end

%% GET DIRECTORY IF NOT SPECIFIED
if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR,'Select animal or recording');
    if DIR==0
        error('No directory specified.');
    end
end

%% GET NAME OF RAT 
listing = dir(DIR);
temp = {listing.name}.';
for ii = 1:numel(temp)
    temp{ii} = strsplit(temp{ii},'_');
    temp{ii} = temp{ii}{end};
end

% Checks presence of RawData folder to determine whether or not this is the
% "Main Block" for a given animal, or a "Sub Block," which would only
% contain a single recording.
if ismember('RawData',temp)
    temp = strsplit(DIR,filesep);
    bk = temp(end);
    DIR = strjoin(temp(1:end-1),filesep);
    temp = temp{end-1};
    rat = temp;
elseif strcmp(DIR(end-3:end),SUB_DIR)
    temp = strsplit(DIR,filesep);
    DIR  = strjoin(temp(1:end-2),filesep);
    temp = temp{end-1};
    rat  = temp(RAT_START:RAT_END);
    bk   = {temp};
elseif ismember(SUB_DIR,temp)
    temp = strsplit(DIR,filesep);
    DIR  = strjoin(temp(1:end-1),filesep);
    temp = temp{end};
    rat  = temp(RAT_START:RAT_END);
    bk   = {temp};
else
    temp = strsplit(DIR,filesep);
    temp = temp{end};
    rat  = temp;
    listing = dir([DIR filesep rat '*']);
    bk   = {listing.name}.';
end

%% GO THROUGH EACH BLOCK AND PERFORM BASIC DATA ORGANIZATION
% Initialize
Rat = [];           tempRat = [];
Block = [];         tempBlock = [];
Channel = [];       tempChannel = [];
Cluster = [];       tempCluster = [];
NumSpikes = [];     tempNumSpikes = [];
Duration = [];      tempDuration = [];
Rate = [];          tempRate = [];
Regularity = [];    tempRegularity = [];

Peaks = [];         tempPeaks = [];
Snips = [];         tempSnips = [];
fs = [];            tempfs = [];

for iB = 1:numel(bk)
     % Get all files from "Good" directory
     if USE_SPK_SUB_DIR
         bDIR = [DIR filesep bk{iB} filesep bk{iB} SPK_DIR ...
                     filesep SUB_DIR filesep];
         if exist(bDIR,'dir')==0
             bDIR = [DIR filesep bk{iB} filesep bk{iB} CAR_SPK_DIR ...
                     filesep];
         end
                 
         if exist(bDIR,'dir')==0
             bDIR = [DIR filesep bk{iB} filesep SUB_DIR filesep];
         end
     else
         bDIR = [DIR filesep bk{iB} filesep bk{iB} SPK_DIR ...
                     filesep];
         if exist(bDIR,'dir')==0
             bDIR = [DIR filesep bk{iB} filesep bk{iB} CAR_SPK_DIR ...
                     filesep];
         end
                 
         if exist(bDIR,'dir')==0
             bDIR = [DIR filesep bk{iB} filesep];
         end
     end
             
     listing = dir([bDIR rat '*']);
     if SHOW_PROGRESS
         h = waitbar(0,['Please wait, extracting spike info for ' ...
             strrep(bk{iB}, '_', '\_')]);
     end
     nL = numel(listing);
     for iL = 1:nL
         spk = load([bDIR listing(iL).name],'peak_train','spikes','pars');
         if stopflag
             ISTOP = numel(spk.peak_train);
         end
         if (startflag && stopflag)
             ptrain = spk.peak_train;
         else
             if ISTOP > numel(spk.peak_train)
                 continue
             else
                ptrain = spk.peak_train(ISTART:ISTOP);
             end
         end
         
         if isfield(spk,'pars')
            fs = [fs; spk.pars.FS];
            dur = (ISTOP - ISTART + 1)./spk.pars.FS;
            t = find(ptrain)./spk.pars.FS;
         else
             fs = [fs; FS];
             dur = (ISTOP - ISTART + 1)./FS;
             t = find(ptrain)./FS;
         end
         
         Peaks = [Peaks; {ptrain}];
         if (startflag && stopflag)
             Snips = [Snips; {spk.spikes}];
         else
             Snips = [Snips; nan];
         end
         
         ch = str2double(listing(iL).name((end-8):(end-6)));
         if isnan(ch)
             ch = str2double(listing(iL).name((end-7):(end-6)));
         end
         cl = str2double(listing(iL).name(end-4));
         
         n = numel(t);
         rt = n./dur;
         lvr = LvR(t);
         
         
         Rat = [Rat; {rat}];
         Block = [Block; bk{iB}];
         Channel = [Channel; ch];
         Cluster = [Cluster; cl];
         NumSpikes = [NumSpikes; n];
         Duration = [Duration; dur];
         Rate = [Rate; rt];
         Regularity = [Regularity; lvr];
         if SHOW_PROGRESS
            waitbar(iL/nL);
         end
     end 
     if SHOW_PROGRESS
        delete(h);
     end
     
    % Spike data
    SPK = table(Peaks,Snips,fs);
    SPK.Properties.Description = 'Sorted extracted spike data';
    SPK.Properties.VariableUnits = {'Sample,P2P Amplitude','uV','Hz'};
    SPK.Properties.VariableDescriptions = ...
      {['Sparse matrix with pairs that correspond to spike sample ' ...
       'indices and their peak-to-peak amplitudes'],                ...
       ['Snippets of the waveforms corresponding to'                ...
        'putative action potentials'],                              ...
       'Sampling frequency'};
   
    tempPeaks = [tempPeaks; Peaks]; Peaks = [];
    tempSnips = [tempSnips; Snips]; Snips = [];
    tempfs = [tempfs; fs];          fs = [];

    % General data
    D = table(Rat,Block,Channel,Cluster,NumSpikes,Duration,Rate,Regularity);
    D.Properties.Description = 'General spike data information';
    D.Properties.VariableUnits = {'','','','', ...
                                  'Spikes','Seconds',...
                                  'Spikes per Second','LvR'};
    D.Properties.VariableDescriptions = ...
          {'Name of animal',            ...
           'Recording block name',      ...
           'Probe channel number',      ...
           'Putative unit cluster',     ...
           'Number of observed spikes', ...
           'Recording duration',        ...
           'Average trial spike rate',  ...
           'Burstiness or Uniformity of spike rate (LvR)'};
       
    tempRat = [tempRat; Rat]; Rat = [];
    tempBlock = [tempBlock; Block]; Block = [];
    tempChannel = [tempChannel; Channel]; Channel = [];
    tempCluster = [tempCluster; Cluster]; Cluster = [];
    tempNumSpikes = [tempNumSpikes; NumSpikes]; NumSpikes = [];
    tempDuration = [tempDuration; Duration]; Duration = [];
    tempRate = [tempRate; Rate]; Rate = [];
    tempRegularity = [tempRegularity; Regularity]; Regularity = [];
    
    if USE_START_STOP
        if ((exist('SAVE_DIR','var')==0) || (exist('INSERT_TAG','var')==0))
            save(fullfile(DIR,bk{iB},[bk{iB} '_' START_STR '_' STOP_STR ...
                                    SAVE_ID]),'D','SPK','-v7.3');
        else
            save(fullfile(SAVE_DIR,[INSERT_TAG '_' START_STR '_' STOP_STR ...
                                    SAVE_ID]),'D','SPK','-v7.3');
        end
    else
        if ((exist('SAVE_DIR','var')==0) || (exist('INSERT_TAG','var')==0))
            save(fullfile(DIR,bk{iB},[bk{iB} SAVE_ID]),'D','SPK','-v7.3');
        else
            save(fullfile(SAVE_DIR,[INSERT_TAG SAVE_ID]),'D','SPK','-v7.3');
        end
    end
    
end
warning('on',W_ID);

%% MAKE AGGREGATE OUTPUT DATA TABLES
Peaks = tempPeaks;
Snips = tempSnips;
fs = tempfs;
Rat = tempRat;
Block = tempBlock;
Channel = tempChannel;
Cluster = tempCluster;
NumSpikes = tempNumSpikes;
Duration = tempDuration;
Rate = tempRate;
Regularity = tempRegularity;

% Spike data
SPK = table(Peaks,Snips,fs);
SPK.Properties.Description = 'Sorted extracted spike data';
SPK.Properties.VariableUnits = {'Sample,P2P Amplitude','uV','Hz'};
SPK.Properties.VariableDescriptions = ...
  {['Sparse matrix with pairs that correspond to spike sample ' ...
   'indices and their peak-to-peak amplitudes'],                ...
   ['Snippets of the waveforms corresponding to'                ...
    'putative action potentials'],                              ...
   'Sampling frequency'};

% General data
D = table(Rat,Block,Channel,Cluster,NumSpikes,Duration,Rate,Regularity);
D.Properties.Description = 'General spike data information';
D.Properties.VariableUnits = {'','','','', ...
                              'Spikes','Seconds',...
                              'Spikes per Second','LvR'};
D.Properties.VariableDescriptions = ...
      {'Name of animal',            ...
       'Recording block name',      ...
       'Probe channel number',      ...
       'Putative unit cluster',     ...
       'Number of observed spikes', ...
       'Recording duration',        ...
       'Average trial spike rate',  ...
       'Burstiness or Uniformity of spike rate (LvR)'};


end
