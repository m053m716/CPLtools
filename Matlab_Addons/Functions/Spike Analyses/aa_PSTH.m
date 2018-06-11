function [y,t] = aa_PSTH(varargin)
%% AA_PSTH  Post-stimulus time histogram [28 ms, 1 ms bin, 4ms blanking]
%
%   [y,t] = AA_PSTH('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs
%                   
%                   --> ANY parameter in DEFAULTS section
%                   --> SPECIAL:
%                       * 'DIR' (default: doesn't exist)
%                           If specified, user is not prompted with UI
%                           popup to select directory with location of
%                           peakDetection folder.
%
%   --------
%    OUTPUT
%   --------
%      y        :   Table containing the following fields for each
%                   identified unit cluster:
%                   - tt: [scalar] total time duration of session
%                   - scounts: [1x28 vector] binned spike counts
%                   - tau: [scalar] bin width
%                   - n: [scalar] total spikes during session
%                   - stimts: [Mx1 vector, for M stimulation times] 
%                             stimulation times during session
%                   - randstims: [MxK vector, for K re-sampled trials] 
%                                random alignment stim times
%                   - rcounts: [Kx28 vector] binned spike counts for random
%                              stim alignments
%                   - isicounts: [28x28 matrix] rows represent #
%                                 milliseconds from stim to first spike;
%                                 columns represent # milliseconds from
%                                 first spike to second spike.
%                   - risicounts: [Mx1 cell] isicounts matrices with
%                                 randomly reshuffled stimulus times.
%
%
%      t        :   [1x28 vector] Time bin centers for PSTH count vectors 
%                   (both experimental and jittered vectors use the same 
%                   time bin centers).
%                   
% By: Max Murphy    v1.3    07/26/2017  Updated parameters to reflect 95%
%                                       confidence interval instead 90%
%                                       confidence interval for
%                                       reshuffling.
%                   v1.2    06/06/2017  Changed "name" detection to look
%                                       for full string before '_'
%                                       delimiter.
%                   v1.1    06/03/2017  Spike jitter code is not working
%                                       efficiently so it has been
%                                       commented out. Added code to look
%                                       at "post-stimulus spike" triggered
%                                       ISI distribution.
%                   v1.0    05/27/2017  Original version (R2017a)

%% DEFAULTS
% Important info
TSTART_ACCUMULATE = 0; % Must be set to match T_SPLIT(1,1) for this block
USE_DAY = false;     % If included, uses 2nd '_' delimited field to 
                     % identify the recording date.
FS = 24414.0625;     % def: Nudo Lab TDT extracellular LFP acquisition rate 
SIG_UB = 0.975;      % Significance level for upper bound of resampling.
SIG_LB = 0.025;      % Significance level for lower bound of resampling.
BLANK = 4;           % Blanking period (milliseconds after stimulus to 
                     %                  reject any spikes)
NR = 40;             % Number of stim re-shuffling iterations.
BIN_MAX = 28;        % Maximum bin edge from stimulus onset (milliseconds)
TAU = 1;             % Binwidth (milliseconds)
T  = 0:TAU:BIN_MAX;  % "Edge" vector for histogram bins (milliseconds)
                     %      NOTE: bins should all be same width
STIM_SECT = 1;       % Stim section to evaluate
                     %      IMPORTANT NOTE: the code assumes that all
                     %      folders will be arranged in descending order
                     %      when ordered by name, due to having '01', '02',
                     %      '03',... etc. somewhere in the name in order to
                     %      denote the section order. This way, all basal
                     %      and stimulation sessions alternate. If there
                     %      are consecutive basal or stimulation sessions,
                     %      it will mess up the way the code extracts the
                     %      "tStart" variable, which aligns the spike times
                     %      and electrical stimulation onset times.

% Optional figures
NORM_Y_AXIS = false;
MAKE_FIGS = true;
SAVE_FIGS = true;
SAVE_DATA = true;
USE_CLUSTER = false;       
UNC_PATH = '\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\';

% Load info
    % Naming conventions
    DEFDIR = 'P:';  % For 'processed data' directory at Nudo Lab
                    
    % Folder and file IDs
    SECT_ID = 'R';          % Identifier for section folders
                
%% PARSE VARARGIN
% Get optional input arguments
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

% Now have all data needed to construct histogram bar plot x-axis vector
t = T(1:(end-1))+TAU/2; % Bin centers

%% GET DIRECTORY
if ~USE_CLUSTER
    if exist('DIR','var')==0
        DIR = uigetdir(DEFDIR,'Select Sorted_Splitted folder');
        if DIR==0
            error('No directory selected. PSTH algorithm canceled.');
        end
    else
        if exist(DIR,'dir')==0 %#ok<NODEF>
            error('Invalid directory, please re-check DIR entry.');
        end
    end
else
    DIR = [UNC_PATH DIR((find(DIR == filesep,1,'first')+1):end)]; %#ok<NODEF>
end

if exist('SAVE_DIR','var')==0
    SAVE_DIR = DIR;
end

%% LOAD DATA
% Get "base" folder data and recording name
basefolder = strsplit(DIR,filesep);
name = strsplit(basefolder{end},'_');
if USE_DAY
    name = strjoin(name(1:2),'_');
else
    name = name{1};
end
basefolder = strjoin(basefolder(1:end-1),filesep);
if USE_CLUSTER
    basefolder = [filesep basefolder];
end

% Get individual section data
sections = dir([DIR filesep SECT_ID '*']);
sections = [sections([sections.isdir])];
tStart = TSTART_ACCUMULATE;
for iS = 1:(2*STIM_SECT-1)
    % find any peak_train file to load, just want total # of samples in
    % file, which should be the same for any of them
    F = dir([DIR filesep sections(iS).name filesep '*.mat']);
    load([DIR filesep sections(iS).name filesep F(1).name],'peak_train');

    % accumulate offset to subtract from StimTS timestamps
    tStart = tStart + numel(peak_train)/FS; 

end


% Get data for stim session of interest
stimfolder = [DIR filesep sections(2*STIM_SECT).name]; 
S = dir([stimfolder filesep '*.mat']);  % list of stimmed peak_train files
nC = numel(S);                          % number of Clusters

%% GET STIM DATA
% Load Stim_TS
load([basefolder filesep name '_StimTS.mat'],'StimTS');

% Should be no "0" phase
StimTS.phase(StimTS.phase<eps) = 1; %#ok<*NODEF>

% Only use Stim_TS that correspond to desired stimulation section
if abs(numel(StimTS.peak_val) - numel(StimTS.phase)) < eps
    stim = StimTS.peak_train(StimTS.peak_val > 0 & ...
                         abs(StimTS.phase-2*STIM_SECT)<eps).' - tStart;
else
    stim = StimTS.peak_train(StimTS.peak_train < min(StimTS.phase_ts(...
                 abs(StimTS.phase-2*STIM_SECT-1)<eps)) & ...
                 StimTS.peak_train > max(StimTS.phase_ts(...
                 abs(StimTS.phase-2*STIM_SECT+1)<eps)) &...
                 StimTS.peak_val > 0) - tStart;
end
                     
if any(stim<0) % Do error detection
    if numel(find(stim<0)) > 1 
        error(['Negative relative stim time detected. ' ...
               'Check code or file/folder structure or labels.']);
    else
        stim = stim > 0;
    end
end

% Make random stim vector
nStim = numel(stim);
rstim = rand(NR,nStim)*(stim(end)-stim(1)) + stim(1);

%% COMPUTE OUTPUTS FOR EACH CLUSTER FILE
tau = repmat(TAU,nC,1); %#ok<REPMAT>
stimts = repmat({stim},nC,1);

tt  = nan(nC,1);
n   = nan(nC,1);

scounts = cell(nC,1);
rcounts = cell(nC,1);

isicounts = cell(nC,1);
risicounts = cell(nC,NR);

if ~USE_CLUSTER
    h = waitbar(0,'Please wait...');
    clc;
    fprintf(1,'-> %s Stim%d\n',name,STIM_SECT);
    tStartTic = tic;
end

ymax = zeros(nC,1);
for iC = 1:nC % Loop through each cluster file
    % Load spike train and get basic information
    fprintf(1,'\tLoading %s...',S(iC).name);
    load([stimfolder filesep S(iC).name],'peak_train'); 
    tt(iC,1) = (numel(peak_train)-1)/FS; % recording duration (sec)
    spkts = find(peak_train)/FS*1000;    % convert sample indices to ms
    n(iC,1) = numel(spkts);              % total number of spikes
    fprintf(1,'complete\n');
    
    % Get each binned vector
    fprintf(1,'\t->\tComputing observed PSTH...');
    histMat = nan(nStim,numel(t));   
    postStimTS = cell(nStim,1);
    for iStim = 1:nStim
        temp = spkts-stim(iStim)*1000;  % Stims should also be in ms
        histMat(iStim,:) = histcounts(temp,T);
        postStimTS{iStim,1} = temp(temp>=BLANK & temp <=BIN_MAX);
    end
    histMat(:,t<BLANK) = 0;
    scounts{iC,1} = sum(histMat);
    ymax(iC) = max(scounts{iC,1});
    fprintf(1,'complete\n');
    
    % Get random alignment vectors
    fprintf(1,'\t->\tComputing random stimulus PSTH...');
    rhistMat = zeros(NR,numel(t));
    temprhistMat = cell(NR,1);
    for iReshuffle = 1:NR
        temprhistMat{iReshuffle,1} = zeros(nStim,numel(t));
        for iRStim = 1:nStim
            temp = spkts-rstim(iReshuffle,iRStim)*1000; 
            temprhistMat{iReshuffle}(iRStim,:) = histcounts(temp,T);
        end
        temprhistMat{iReshuffle}(:,t<BLANK)=0;
        rhistMat(iReshuffle,:) = sum(temprhistMat{iReshuffle});
    end
    rcounts{iC,1} = rhistMat;
    fprintf(1,'complete\n');
    
    
    % Get ISI counts for spike triplets during poststimulus period
    isicounts{iC} = zeros(numel(t));
    risicounts{iC} = cell(NR,1);
    fprintf(1,'\t->\tComputing stim-associated feature pairs...');
    for iStim = 1:nStim
        if abs(sum(histMat(iStim,:))-2)<eps
            i1 = find(histMat(iStim,:),1,'first');
            i2 = find(histMat(iStim,:),1,'last') - i1;
            isicounts{iC}(i1,i2) = isicounts{iC}(i1,i2) + 1;
        end
    end
    fprintf(1,'complete\n');
    
    fprintf(1,'\t->\tComputing random-associated feature pairs...');
    for iR = 1:NR
        risicounts{iC,iR} = zeros(numel(t));
        for iStim = 1:nStim
            if abs(sum(temprhistMat{iR}(iStim,:))-2)<eps
                i1 = find(temprhistMat{iR}(iStim,:),1,'first');
                i2 = find(temprhistMat{iR}(iStim,:),1,'last') - i1;
                risicounts{iC,iR}(i1,i2)= risicounts{iC,iR}(i1,i2) + 1;
            end
        end
    end
    fprintf(1,'complete\n');
    
    % Update progress status
    if ~USE_CLUSTER
        waitbar(iC/nC);
    end
end
if ~USE_CLUSTER
    delete(h);
    fprintf(1,'\nPSTH data for %s Stim %d complete.\n',name,STIM_SECT);
    ElapsedTime(tStartTic);
end

ymax = max(ymax);

%% ASSIGN OUTPUTS
y = table(tt,tau,n,stimts,scounts,rcounts,isicounts,risicounts);

%% FIGURES

if MAKE_FIGS

    nRow = ceil(sqrt(nC));
    nCol = nRow;
    fprintf(1,'Generating figure...');
    figure('Name','Post Stimulus Time Histograms (PSTHs)', ...
           'Units','Normalized', ...
           'Position', [0.25 0.25 0.5 0.5]);

    ind_UB = ceil(SIG_UB * NR);
    ind_LB = ceil(SIG_LB * NR);
    for ii = 1:nC
        subplot(nRow,nCol,ii)
        bar(t,y.scounts{ii},1,'EdgeColor','none','FaceColor','k'); 
        resamp = y.rcounts{ii};
        for iR = 1:size(resamp,2)
            resamp(:,iR) = sort(resamp(:,iR),'ascend');
        end
        resamp_UB = resamp(ind_UB,:);
        resamp_LB = resamp(ind_LB,:);
        hold on; plot(t,resamp_UB,'MarkerEdgeColor','r', ...
                                            'Marker','sq', ...
                                            'LineStyle','none', ...
                                            'MarkerSize',3.5, ...
                                            'MarkerFaceColor','r');
                 plot(t,resamp_LB,'MarkerEdgeColor','b', ...
                                            'Marker','sq', ...
                                            'LineStyle','none', ...
                                            'MarkerSize',3.5, ...
                                            'MarkerFaceColor','b');

        xlabel('Time (msec)'); ylabel('Spike Counts');
        title(['Ch ' strrep(S(ii).name((end-7):(end-4)),'_',' c')]);
        if NORM_Y_AXIS
            ylim([0 ymax + 100]);
        end
    end 
    suptitle([name ' Stim' num2str(STIM_SECT)]);
    fprintf(1,'complete\n');

    if USE_CLUSTER
        SAVE_DIR = [UNC_PATH  ...
            SAVE_DIR((find(SAVE_DIRDIR == filesep,1,'first')+1):end)];
    end
    
    if SAVE_FIGS
        fprintf(1, '\tSaving PSTH figure...');
        savefig(gcf,[SAVE_DIR filesep name '_Stim' num2str(STIM_SECT) ...
                        '_PSTH.fig']);
        saveas(gcf,[SAVE_DIR filesep name '_Stim' num2str(STIM_SECT) ...
                        '_PSTH.jpg']);
        delete(gcf);
        fprintf(1, 'complete\n\n');
    end
end

if SAVE_DATA
    if (USE_CLUSTER && ~MAKE_FIGS)
        SAVE_DIR = [UNC_PATH  ...
            SAVE_DIR((find(SAVE_DIR == filesep,1,'first')+1):end)];
    end
        
    save([SAVE_DIR filesep name '_PSTHdata.mat'],'y','t','-v7.3');
end

end