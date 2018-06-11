function EMG = stEMG(varargin)
%% STEMG    Stimulus-triggered EMG averaging
%
%   EMG = STEMG('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%                   => ANY constant from DEFAULTS section, notably-
%                   -> 'NPULSES' : Just associates a certain number of
%                                  pulses with the stimulation; purely for
%                                  labeling.
%                   -> 'NCH' : Determines number of channels of EMG to ask
%                              the names of and plot.
%                   -> 'EMG_ID' : Identifier for single-channel files for
%                                 EMG recordings.
%                   -> 'STIM_ID' : Identifier for file containing stimulus 
%                                  pulse onset sample indices.
%                   -> 'RECT' : (Default: false); setting this to true
%                               automatically rectifies all EMG data.
%
%                   ALSO
%                   -> 'MUSCLES' (def: NONE; if not specified, prompts user
%                                            to list the implanted EMG
%                                            muscles. Specify as a cell
%                                            array of strings that is the
%                                            same length as NCH)
%                   -> 'STIMDIR' (specify if the STIM data is in a
%                                 different directory from the EMG data)
%                   -> 'T_BEGIN' / 'T_FINISH' (def: NONE; if not specified,
%                                                   uses entire recording
%                                                   duration. Otherwise,
%                                                   specified in seconds,
%                                                   uses those start and
%                                                   stop times for all data
%                                                   points in recording).
%
%   --------
%    OUTPUT
%   --------
%     EMG       :   Table containing the following fields, with each row
%                   corresponding to a new channel (muscle).
%                   -> ch  : Channel number
%                   -> name: Name of muscle
%                   -> avg : Vector of stim-averaged EMG waveforms
%                   -> tr  : All stimulus trials for EMG waveforms
%                   -> t   : Vector of time values associated avg
%                   -> fs  : EMG sampling frequency
%                   -> n   : Number of pulses per stimulus
%                   -> ID  : Identifier used for single-channel files
%                   -> t_s : Vector of stim times relative to start of the
%                            recording (seconds)
%                   
%   Also generates a figure with stimulus-triggered EMG for each channel.
%
% By: Max Murphy    v1.0    06/07/2017  Original version (R2017a)
%   See also: MOVE_ALL_DATA, MOVERECORDEDDATA, EXTRACT_MOVED_DATA

%% DEFAULTS
NCH = 4;                                % Number of EMG channels

RECT = false;                           % Rectify EMG activity

COL = [0.3 0.3 0.9; ...                 % Associated EMG colors
       0.9 0.3 0.3; ...
       0.3 0.9 0.3; ...
       0.9 0.3 0.9];

T_START = -0.020;                       % Start time for average relative 
                                        % stimulus onset.

T_END   =  0.060;                       % End time for average relative to 
                                        % stimulus onset.

DEF_MUSCLES = {'Triceps'; ...           % Edit this if you run a lot, but 
               'Biceps'; ...            % use different combinations of 
               'Wrist Extensors'; ...   % muscle insertions than rat
               'Wrist Flexors'};        % forelimb.
           
EMG_ID = 'FilW';                        % EMG file identifier

STIM_ID = 'Curr';                       % Stimulus file identifier

NPULSES = 1;                            % Number of pulses per stimulus

NTR = 100;                              % Number of single-trial EMG to
                                        % plot.

STIM_FS = 24414.0625;                   % Should always be unnecessary to 
                                        % specify, unless working with very
                                        % old data (prior to 2015).
                                        
EMG_FS = 4069.01;                       % Should always be unnecessary to 
                                        % specify this as well.
                                        
DEF_DIR = 'P:\Rat';                     % Edit this if you tend to only use
                                        % data from one specific directory.

% Saving: default directory
SAVE_DIR = 'J:\Rat\Muscimol\Pilot Acute Recordings\EMG';
                                        
SAVE_DATA = false;                      % If true, automatically saves mat 
                                        % file with output EMG table.

SAVE_FIG = false;                       % If true, automatically save.
                                        
CLOSE_FIG = false;                      % If true, automatically close 
                                        % figure. (Useful for loops).

%% PARSE INPUTS
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

% Get muscle names for EMG channels
if exist('MUSCLES','var')==0
    pstr = cell(NCH,1);
    for iCh = 1:NCH
        pstr{iCh} = sprintf('Channel %d muscle:',iCh);
    end
    nM = numel(DEF_MUSCLES);
    if nM-NCH > eps
        DEF_MUSCLES = DEF_MUSCLES(1:NCH);
    elseif NCH - nM > eps
        for iCh = (NCH + 1):nM
            DEF_MUSCLES{iCh} = 'unknown';
        end
    end
    MUSCLES = inputdlg(pstr,'Muscle List',1,DEF_MUSCLES);
    if isempty(MUSCLES{iCh})
        error('Must input a name for each muscle.');
    end
    
    if NCH - size(COL,1) > eps
        COL = [COL; rand(NCH-size(COL,1),3)];
    elseif size(COL,1) - NCH > eps
        COL = COL(1:NCH,:);
    end
else
    NCH = numel(MUSCLES);
    if NCH - size(COL,1) > eps
        COL = [COL; rand(NCH-size(COL,1),3)];
    elseif size(COL,1) - NCH > eps
        COL = COL(1:NCH,:);
    end
end

% Get location of data files
if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR,'Select path containing EMG and STIM files');
    if DIR == 0
        error('No path selected, script aborted.');
    end
else
    if exist(DIR,'dir')==0 %#ok<*NODEF>
        error('Invalid data path specified with DIR input.');
    end
end

% Check for user specification of start and end of file
if exist('T_BEGIN','var')==0
    T_BEGIN = 0;
end

if exist('T_FINISH','var')==0
    T_FINISH = nan;
end

%% CHECK IF DATA IS LOCATED HERE
EMG_Files = dir(fullfile(DIR,['*' EMG_ID '*.mat']));
if isempty(EMG_Files)
    error('EMG files not found. Please check EMG_ID or DIR.');
end

STIM_File = dir(fullfile(DIR,['*' STIM_ID '*.mat']));
if isempty(STIM_File)
    if exist('STIM_DIR','var')==0
        STIM_DIR = uigetdir(DEF_DIR,['STIM file not found,' ...
                                     'please select new STIM path']);
    end
    STIM_File = dir(fullfile(STIM_DIR,['*' STIM_ID '*.mat']));
else
    STIM_DIR = DIR;
end

%% GET STIMULATION SAMPLE INDICES AND TIME VECTOR
stim = load(fullfile(STIM_DIR,STIM_File.name));
if ~isfield(stim,'fs')
    stim_fs = STIM_FS;
else
    stim_fs = stim.fs;
end

if ~isnan(T_FINISH)
    stim.data = stim.data(stim.onset <= T_FINISH);
    stim.onset = stim.onset(stim.onset <= T_FINISH); 
end

stim.onset = stim.onset - T_BEGIN;
stim = stim.onset(stim.data > eps & ...
                  stim.onset >= 0);
NS = numel(stim);
t_s = repmat({stim},NCH,1);

%% LOOP THROUGH AND DO CALCULATIONS ON EMG FILES
avg = cell(NCH,1);
t   = cell(NCH,1);
tr  = cell(NCH,1);
fs  = nan(NCH,1);
mu  = nan(NCH,1);
sd  = nan(NCH,1);

ymax = 0;
ymin = 0;

digitalblockname = strsplit(DIR,filesep);
digitalblockname = digitalblockname{end};
clc; fprintf(1,'Computing stimulus-triggered EMG for:\n');
fprintf(1,'->\t%s\n\n',digitalblockname);
fprintf(1,'\tMUSCLES\n');
fprintf(1,'\t-------\n');

for iCh = 1:NCH
    fprintf(1,'\t->\t%s\n',MUSCLES{iCh});
end
    
for iCh = 1:NCH
    emg = load(fullfile(DIR,EMG_Files(iCh).name));
    if isfield(emg,'fs')
        fs(iCh) = emg.fs;
    else
        fs(iCh) = EMG_FS;
    end
    emg.data = interp(double(emg.data),round(stim_fs/fs(iCh)));
    fs(iCh) = fs(iCh) * round(stim_fs/fs(iCh)); % Not "even" factor
    
    % Get selected start/stop times for data
    TT = (0:(numel(emg.data)-1))/fs(iCh);
    if ~isnan(T_FINISH)
        emg.data = emg.data(TT <= T_FINISH);
        TT = TT(TT<=T_FINISH);
    end

    if T_BEGIN > 0
        emg.data = emg.data(TT >= T_BEGIN);
    end
    
    stim_inds = round(T_START * fs(iCh)):round(T_END*fs(iCh));
    
    if isempty(stim_inds)
        error(['No elements in stim_inds. Please check ' ...
               'T_START and T_END; not to be confused with ' ...
               'T_BEGIN and T_FINISH, which define the ' ...
               'recording duration.']);
    end
    
    sd_inds = round(T_START * fs(iCh)):-10; % Pre-stimulus
    sd_vec = [];
    t{iCh} = linspace(T_START,T_END,numel(stim_inds));
    tr{iCh}= nan(NS,numel(stim_inds));
    for iS = 1:NS
        ind = stim_inds + round(stim(iS)*stim_fs);
        
        if (~any(ind<=0) && ...
            max(ind) <= numel(emg.data))
            tr{iCh}(iS,:) = emg.data(ind);
            sd_vec = [sd_vec, sd_inds + round(stim(iS)*stim_fs)]; %#ok<AGROW>
        else
            warning('Stim %d too close to beginning or end.',iS);
        end
    
    end
    if RECT
        tr{iCh} = abs(tr{iCh});
        sd(iCh) = nanstd(abs(emg.data(sd_vec)));
        mu(iCh) = nanmean(abs(emg.data(sd_vec)));
        avg{iCh} = nanmean(tr{iCh});
    else
        sd(iCh) = nanstd(emg.data(sd_vec));
        mu(iCh) = nanmean(emg.data(sd_vec));
        avg{iCh} = nanmean(tr{iCh});
    end
    
    ymax = max(nanmax(avg{iCh}),ymax);
    ymin = min(nanmin(avg{iCh}),ymin);
end

%% GET NAME INFORMATION
rec = strsplit(STIM_File.name,'_');
rec = strjoin(rec(1:2),'_');

nrow = ceil(sqrt(NCH));
ncol = nrow;


%% MAKE FIGURE

figure('Name',[rec '_stEMG'], ...
       'Units','Normalized', ...
       'Position', [0.05 0.05 0.9 0.9]);
   
for iCh = 1:NCH
    subplot(nrow,ncol,iCh);
    
    if size(tr{iCh},1) >= NTR
        plot(t{iCh},tr{iCh}(RandSelect(1:size(tr{iCh},1),NTR),:), ...
              'LineWidth',1.5, ...
              'Color',[0.9 0.9 0.9]);
    else
        plot(t{iCh},tr{iCh}, ...
              'LineWidth',1.5, ...
              'Color',[0.9 0.9 0.9]);
    end
    
    hold on;
    plot(t{iCh},avg{iCh}, 'LineWidth', 5, ...
                          'Color', COL(iCh,:));
                      
    
    for iP = 1:NPULSES
        line([((1e-4)+80/24414.0625)*(iP-1), ...
              ((1e-4)+80/24414.0625)*(iP-1)],[ymin ymax], ...
                                            'LineWidth', 1, ...
                                            'Color', 'r', ...
                                            'LineStyle', '--');
    end
    tlim = [min(t{iCh}) max(t{iCh})];
    line(tlim,[mu(iCh), mu(iCh)],'LineWidth', 1, ...
                                 'Color','k');
    line(tlim,[mu(iCh)+2*sd(iCh), mu(iCh)+2*sd(iCh)],'LineWidth',1, ...
                                 'Color','k', ...
                                 'LineStyle','--');
    line(tlim,[mu(iCh)-2*sd(iCh), mu(iCh)-2*sd(iCh)],'LineWidth',1, ...
                                 'Color','k', ...
                                 'LineStyle','--');
    hold off;    
    ylim([ymin ymax]); 
    ylabel('Amplitude (V)');
    xlim(tlim); 
    xlabel('Time (sec)');
    title(MUSCLES{iCh});   
end

suptitle(sprintf('%s %d pulse stim-triggered EMG',rec,NPULSES));

if SAVE_FIG
    if exist('T_BEGIN','var')==0
        t1 = '0';
    else
        t1 = num2str(T_BEGIN);
    end

    if exist('T_FINISH','var')==0
        t2 = 'end';
    else
        if isnan(T_FINISH)
            t2 = 'end';
        else
            t2 = num2str(T_FINISH);
        end
    end
    
    if exist(SAVE_DIR,'dir')==0 %#ok<*UNRCH>
        SAVE_DIR = uigetdir(DEF_DIR,['Save directory not found, '...
                                     'please specify new directory']);
                                     
        if SAVE_DIR == 0
            disp('Figure not saved.');
        else
            savefig(gcf,fullfile(SAVE_DIR,[rec ... 
                      '_' t1 '_' t2  '_stEMG.fig']));
            saveas(gcf,fullfile(SAVE_DIR,[rec ...
                      '_' t1 '_' t2  '_stEMG.jpeg']));
        end
    else
        savefig(gcf,fullfile(SAVE_DIR,[rec ...
                  '_' t1 '_' t2  '_stEMG.fig']));
        saveas(gcf,fullfile(SAVE_DIR,[rec ...
                  '_' t1 '_' t2  '_stEMG.jpeg']));
    end
end

if CLOSE_FIG
    delete(gcf);
end

%% SPECIFY OUTPUT
ch = reshape(1:NCH,NCH,1);
name = reshape(MUSCLES,NCH,1);
n = repmat(NPULSES,NCH,1); %#ok<*REPMAT>
ID = repmat({EMG_ID},NCH,1);

EMG = table(ch, name, avg, tr, t, mu, sd, fs, n, ID, t_s);

if SAVE_DATA 
    if exist('T_BEGIN','var')==0
        t1 = '0';
    else
        t1 = num2str(T_BEGIN);
    end

    if exist('T_FINISH','var')==0
        t2 = 'end';
    else
        if isnan(T_FINISH)
            t2 = 'end';
        else
            t2 = num2str(T_FINISH);
        end
    end
    if ~SAVE_FIG
        if exist(SAVE_DIR,'dir')==0
            SAVE_DIR = uigetdir(DEF_DIR,['Save directory not found, '...
                                         'please specify new directory']);
                                     
            if SAVE_DIR == 0
                disp('Data not saved.');
                return;
            else
                save(fullfile(SAVE_DIR,[rec ...
                      '_' t1 '_' t2  '_stEMG.mat']),'EMG','-v7.3');
            end
                        
        end
    else
        save(fullfile(SAVE_DIR,[rec ...
                      '_' t1 '_' t2  '_stEMG.mat']),'EMG','-v7.3');
    end
end

end