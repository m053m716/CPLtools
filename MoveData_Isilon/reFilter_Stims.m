function reFilter_Stims(probe,ch,varargin)
%% REFILTER_STIMS    Redo filtering and reference with stims "blanked"
%
%   REFILTER_STIMS(probe,ch,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%     probe     :   Stimulation probe number (A==1, B==2,...).
%
%     ch        :   Stimulation channel (Intan-side).
%
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%                   - ANY parameter in DEFAULTS
%                   - DIR: (none default; if specified, skips user
%                           selection interface for picking filtered data
%                           folder).
%                   - USE_CHANS: (none default; if specified, only takes
%                                 those channels in the re-referencing)
%   --------
%    OUTPUT
%   --------
%   The re-referenced, filtered data in a _FilteredCAR folder in the same
%   directory as the rest of the files associated with that recording
%   block.
%
% By: Max Murphy    v1.0   02/22/2018  Original version (R2017a)
%                   v1.1   02/28/2018  Changed "blanking" from just
%                                      substituting zero to interpolating a
%                                      smoothed version between a point
%                                      before the stim and after the stim.

%% DEFAULTS

% Unlikely to change
DEF_DIR = 'P:\Rat\';            % Default search dir
FILT_FOLDER = '_Filtered';      % Folder name for unit-filtered files
FILT_ID = '_Filt_';
CAR_FOLDER  = '_FilteredCAR';   % Folder name for CAR files
CAR_ID = '_FiltCAR_';

STIM_BLANK = [0.5 2];        % Milliseconds to blank around stim
ANCHOR = 5; % "Anchors" in samples back from blanking (for interpolation)

RAW_FOLDER = '_RawData';
RAW_ID    = '_Raw_';             % ID Tag for raw recording files
DIG_FOLDER  = '_Digital';
STIM_FOLDER = 'STIM_DATA';
STIM_IN_ID = '_STIM_';
STIM_OUT_ID = '_StimTS.mat';
FS      = 30000;                % Default sampling frequency (if not found)
USE_CLUSTER = false;            % If true, need to change DIR start.
UNC_PATH = '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\';

% Filter command
FSTOP1 = 200;     % First Stopband Frequency
FPASS1 = 500;     % First Passband Frequency
FPASS2 = 3000;    % Second Passband Frequency
FSTOP2 = 5000;    % Second Stopband Frequency
ASTOP1 = 80;      % First Stopband Attenuation (dB)
APASS  = 0.0001;  % Passband Ripple (dB)
ASTOP2 = 80;      % Second Stopband Attenuation (dB)
MATCH  = 'both';  % Band to match exactly
           
%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) ' = varargin{iV+1};']);
end

%% GET DIRECTORY INFO
if ~USE_CLUSTER
    if exist('DIR','var')==0
        DIR = uigetdir(DEF_DIR, ...
            'Select recording block to re-reference');
        if DIR == 0
            error('Must select a directory.');
        end

    end

    if exist(DIR,'dir')==0
        error('Invalid directory name. Check path.');
    end
else
    DIR = [UNC_PATH DIR((find(DIR == filesep,1,'first')+1):end)]; %#ok<NODEF>
    myJob = getCurrentJob;
end

temp = dir([DIR filesep '*' RAW_FOLDER]);
if isempty(temp)
    temp = strsplit(DIR, filesep);
    Block = strjoin(temp(1:end-1),filesep);
    Car_Folder = strrep(temp{end},RAW_FOLDER,CAR_FOLDER);
    Filt_Folder = strrep(temp{end},RAW_FOLDER,FILT_FOLDER);
else
    Block = DIR;
    DIR = [Block filesep temp(1).name];
    Car_Folder = strrep(temp(1).name,RAW_FOLDER,CAR_FOLDER);
    Filt_Folder = strrep(temp(1).name,RAW_FOLDER,FILT_FOLDER);
end
clear temp

%% GET FILTERED FILE NAMES & CHANNELS
F = dir(fullfile(DIR,['*' RAW_ID '*.mat']));
nCh = numel(F);

Name = cell(nCh,1);
Ch   = nan(1,nCh);
for iF = 1:nCh
    Name{iF,1} = F(iF).name(1:end-4);
    Ch(1,iF) = str2double(Name{iF}(end-2:end));
    if isnan(Ch(1,iF))
        Ch(1,iF) = str2double(Name{iF}(end-1:end));
    end
end
name = strsplit(Name{1},'_');
idate = regexp(Name{1},'\d\d\d\d[_]\d\d[_]\d\d','ONCE');
if isempty(idate)
   if numel(name) > 5
       name = strjoin(name(1:2),'_');
   else
       name = name{1};
   end
else
   name = [name{1} '_' Name{1}(idate:(idate+11))];
end

%% GET NUMBER OF PROBES AND PROBE ASSIGNMENTS
pval = nan(nCh,1);
for iN = 1:nCh
    pval(iN) = str2double(Name{iN}(regexp(Name{iN},'[P]\d')+1));
end
pnum = numel(unique(pval));

%% GET CHANNELS TO USE
if exist('USE_CHANS','var')~=0
    usech = false(size(Ch));
    for iCh = 1:numel(Ch)
        if ismember(Ch(iCh),USE_CHANS)
            usech(iCh) = true;
        end
    end
    Ch = Ch(usech);
end

if USE_CLUSTER
    set(myJob,'Tag',['Loading raw channels for ' name ' and removing stims...']); %#ok<*UNRCH>
end

%% GET STIM TIMES
stimfile = fullfile(Block,...
                    [name DIG_FOLDER],...
                    STIM_FOLDER,...
     [name STIM_IN_ID 'P' num2str(probe) '_Ch_' num2str(ch,'%03g') '.mat']);
  
stim_in = load(stimfile,'data');
ind = find(stim_in.data>0);
idiff = [inf, diff(ind)];
stim_idx = ind(idiff>1);

StimTS = struct;
StimTS.peak_train = reshape(stim_idx,numel(stim_idx),1);
StimTS.peak_val = reshape(stim_in.data(stim_idx),numel(stim_idx),1);
StimTS.name = name;
StimTS.phase = str2double(name(end)) .* ones(size(StimTS.peak_train));

save(fullfile(Block, ...
              [name STIM_OUT_ID]), 'StimTS');

%% LOAD RAW CHANNELS AND DO BLANKING
clc;
Data = cell(pnum,1);
pCh = cell(pnum,1);
for iP = 1:pnum
   iCount = 0;
   pCh{iP} = Ch(abs(pval-iP)<eps);
   pCh{iP} = reshape(pCh{iP},1,numel(pCh{iP}));
   for iCh = pCh{iP}
      iCount = iCount + 1;
      fprintf(1,'\n\t Loading %s...', Name{abs(Ch-iCh)<eps});
      x = load(fullfile(DIR,...
         [Name{abs(Ch-iCh)<eps & abs(pval.'-iP)<eps} '.mat']));
      if iCount == 1
         Data{iP} = nan(numel(pCh{iP}),numel(x.data));
         if isfield(x,'fs')
            FS = x.fs;
         end
         epre = round(FS*STIM_BLANK(1)*1e-3);
         epost = round(FS*STIM_BLANK(2)*1e-3);
         evec = -epre : epost;
         stim = nan(numel(evec),numel(stim_idx));
         
         k = 1;
         for iBlankInd = evec
            stim(k,:) = max(min(stim_idx + iBlankInd,numel(x.data)),1);
            k = k + 1;
         end
      end
      iend = size(stim,1);
      for iStim = 1:size(stim,2)
%          x.data(stim(:,iStim)) = 0;
         % Try interpolation instead of setting to 0, since
         % there may be a DC bias in raw data after the stim, which would
         % lead to unnatural high-frequency artifact in the transition
         % sample from 0 to whatever the non-"blanked" signal is.
         
         stimvec = [stim(1,iStim) - ANCHOR, ...
                    stim(1,iStim),...
                    stim(iend,iStim),...
                    stim(iend,iStim) + ANCHOR];
         if (min(stimvec) < 1 ) || (max(stimvec) > numel(x.data))
            continue
         else
            x.data(stim(:,iStim)) = interp1(stimvec,x.data(stimvec),...
                                            stim(:,iStim),'spline');
         end
      end
      x.data(isnan(x.data)) = 0;
      Data{iP}(iCount,:) = x.data;
      fprintf(1,'complete.\n');
   end
end
clear x


%% DO FILTERING
if USE_CLUSTER
   set(myJob,'Tag',['Filtering stim-suppressed raw data for ' name '...']);
end

[~, bp_Filt] = BandPassFilt('FS', FS, 'FSTOP1', FSTOP1, 'FPASS1', FPASS1, ...
   'FPASS2', FPASS2, 'FSTOP2', FSTOP2, 'ASTOP1', ASTOP1, 'APASS', APASS, ...
   'ASTOP2', ASTOP2, 'MATCH', MATCH);

for iP = 1:pnum
   for iCh = 1:size(Data{iP},1)
      Data{iP}(iCh,:) = single(filtfilt(bp_Filt,double(Data{iP}(iCh,:)))); 
   end
end

if exist(fullfile(Block,Filt_Folder),'dir')==0
    mkdir(fullfile(Block,Filt_Folder));
end

fname = cell(numel(Ch),pnum);
for iP = 1:pnum
   iCount = 0;
   for iCh = pCh{iP}
       iCount = iCount + 1;
       fname{iCount,iP} = strrep(F(abs(Ch-iCh)<eps & ...
                                   abs(pval.'-iP)<eps).name,RAW_ID,FILT_ID);
   end
end

if USE_CLUSTER
   for iP = 1:pnum
       parfor iCh = 1:numel(pCh{iP})
           fprintf(1,'\n\t Saving %s...',fname{iCh,iP});
           % Put data into proper format
           fs = FS;
           data = Data{iP}(iCh,:); %#ok<NASGU>
           parsavedata(fullfile(Block,Filt_Folder,fname{iCh,iP}), ...
                           'data',data,'fs',fs);
           fprintf(1,'complete.\n');
       end
   end
else
    fs = FS;
    for iP = 1:pnum
       for iCh = 1:numel(pCh{iP})
           fprintf(1,'\n\t Saving %s...',fname{iCh,iP});
           % Put data into proper format
           data = Data(iCh,:); %#ok<NASGU>
           save(fullfile(Block,Filt_Folder,fname{iCh,iP}),'data','fs','-v7.3');
           fprintf(1,'complete.\n');
       end
    end
end

%% DO RE-REFERENCING
if USE_CLUSTER
    set(myJob,'Tag',['Re-referencing and saving data for ' name '...']);
end


for iP = 1:pnum
    refData = mean(Data{iP},1);
    iCount = 1;
    for iCh = pCh{iP}
        Data{iP}(iCount,:) = Data{iP}(iCount,:) - refData;
        iCount = iCount + 1;
    end
end

if exist(fullfile(Block,Car_Folder),'dir')==0
    mkdir(fullfile(Block,Car_Folder));
end

fname = cell(numel(Ch),pnum);
for iP = 1:pnum
   iCount = 0;
   for iCh = pCh{iP}
       iCount = iCount + 1;
       fname{iCount,iP} = strrep(F(abs(Ch-iCh)<eps & ...
                                   abs(pval.'-iP)<eps).name,RAW_ID,CAR_ID);
   end
end

clc;
if USE_CLUSTER
   for iP = 1:pnum
       parfor iCh = 1:numel(pCh{iP})
           fprintf(1,'\n\t Saving %s...',fname{iCh,iP});
           % Put data into proper format
           fs = FS;
           data = Data{iP}(iCh,:); %#ok<NASGU>
           parsavedata(fullfile(Block,Car_Folder,fname{iCh,iP}), ...
                           'data',data,'fs',fs);
           fprintf(1,'complete.\n');
       end
   end
else
    fs = FS;
    for iP = 1:pnum
       for iCh = 1:numel(pCh{iP})
           fprintf(1,'\n\t Saving %s...',fname{iCh,iP});
           % Put data into proper format
           data = Data(iCh,:); %#ok<NASGU>
           save(fullfile(Block,Car_Folder,fname{iCh,iP}),'data','fs','-v7.3');
           fprintf(1,'complete.\n');
       end
    end
end

if USE_CLUSTER
    set(myJob,'Tag',['Complete: ad hoc CAR for ' name]);
end

end