function snips = CPL_getTrialWaveforms(varargin)
%% CPL_GETTRIALWAVEFORMS    Extract data table to have different kinds of trial waveforms
%
%  snips = CPL_GETTRIALWAVEFORMS('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin       :     (Optional) 'NAME',value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%   snips         :     Data table that has different kinds of filtered
%                       waveforms corresponding to each trial, as well as
%                       associated trial metadata.
%
% By: Max Murphy  v1.0  11/21/2018   Original version (R2017b)

%% DEFAULTS
DIR = nan;
DEF_DIR = 'P:\Rat\BilateralReach\Murphy\R18-68\R18-68_2018_07_24_1';

DIG_DIR = '_Digital';
SCORE_ID = '_Scoring.mat';
GEN_ID = '_GenInfo.mat';

RAW_DIR = '_RawData';
RAW_ID = '_Raw_';

E_PRE = -0.5;
E_POST = 0.25;

N_PRE = -2.5;
N_POST = -1.75;

ALIGN = 'Grasp';
SG_ORD = 3;
SG_FRAMELEN = 1001;

BUTTER_ORD = 4;
BUTTER_FC = 150;
BUTTER_FC_SLOW = 5;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET BLOCK DIRECTORY
if isnan(DIR)
   DIR = uigetdir(DEF_DIR,'Select recording BLOCK');
   if DIR==0
      error('No block selected, script canceled.');
   end
end

%% LOAD TIMES
block = strsplit(DIR,filesep);
block = block{numel(block)};

F = dir(fullfile(DIR,[block DIG_DIR],[block '*' SCORE_ID]));
if numel(F) > 1
   [~,idx] = uidropdownbox('Multiple TRIALS files detected',...
      'Select TRIALS file:',...
      {F.name}.');
   
   F = F(idx);
end

load(fullfile(F.folder,F.name),'behaviorData');
if ~ismember(ALIGN,behaviorData.Properties.VariableNames) %#ok<NODEF>
   error('%s is not a valid alignment marker (check behaviorData).',ALIGN);
end
behaviorData.Trial = []; 

%% GET RAW, SGOLAY FILTERED
load(fullfile(DIR,[block GEN_ID]),'info');
fs = info.frequency_pars.amplifier_sample_rate;

[b,a] = butter(BUTTER_ORD,BUTTER_FC/(fs/2));
[b_s,a_s] = butter(BUTTER_ORD,BUTTER_FC_SLOW/(fs/2));

raw = dir(fullfile(DIR,[block RAW_DIR],[block '*' RAW_ID '*.mat']));

nTrials = size(behaviorData,1);
Raw = cell(nTrials,1);
LFP = cell(size(Raw));
Slow = cell(size(Raw));
SG = cell(size(Raw));

%% GET INDEXING VECTOR AND MATRIX
tvec = (round(E_PRE*fs)/fs):(1/fs):(round(E_POST*fs)/fs); % round to make sure even multiples of sampling rate
ivec = repmat(round(tvec * fs),nTrials,1) + round(behaviorData.(ALIGN)*fs);

tNvec = (round(N_PRE*fs)/fs):(1/fs):(round(N_POST*fs)/fs); % round to make sure even multiples of sampling rate
iNvec = repmat(round(tNvec * fs),nTrials,1) + round(behaviorData.(ALIGN)*fs);

%% EXTRACT RAW DATA AND DO FILTERING
nChannels = numel(raw);
Channel = cell(nChannels,1);
Probe = cell(nChannels,1);

tic;
h = waitbar(0,'Please wait, loading and filtering waveforms...');
for iCh = 1:nChannels
   load(fullfile(raw(iCh).folder,raw(iCh).name),'data');
   ivec(any(ivec < 1 | ivec > numel(data),2),:) = []; % remove invalid indexing rows
   t = 0:(1/fs):((numel(data)-1)/fs);
   
   % Make different signals with filters
   Raw{iCh} = double(data(ivec));
   normData = double(data(iNvec));
   
   % Normalized LFP (gamma and below)
   l = filtfilt(b,a,normData.').';
   LFP{iCh} = (filtfilt(b,a,Raw{iCh}.').' - mean(mean(l)))./mean(std(l));   
   
   % Normalized slow oscillations (5 Hz and below)
   l = filtfilt(b_s,a_s,normData.').';
   Slow{iCh} = (filtfilt(b_s,a_s,Raw{iCh}.').' - mean(mean(l)))./mean(std(l));
   
   % Savitzky-Golay filter for non-normalized "oscillations"
   l = sgolayfilt(normData,SG_ORD,SG_FRAMELEN,[],2);
   SG{iCh} = (sgolayfilt(Raw{iCh},SG_ORD,SG_FRAMELEN,[],2) - mean(mean(l)))./mean(std(l));
   
   % Also get channel metadata
   str_info = strsplit(raw(iCh).name(1:(end-4)),'_');
   Channel{iCh} = str_info{numel(str_info)};
   Probe{iCh} = str_info{numel(str_info)-2};
   waitbar(iCh/nChannels);
end
delete(h);

toc;

%% ASSIGN OUTPUT
Grasp = repmat({behaviorData.Grasp},nChannels,1);
Reach = repmat({behaviorData.Reach},nChannels,1);
Outcome = repmat({behaviorData.Outcome},nChannels,1);
Forelimb = repmat({behaviorData.Forelimb},nChannels,1);

snips = table(Probe,Channel,Raw,LFP,Slow,SG,Grasp,Reach,Outcome,Forelimb);


end