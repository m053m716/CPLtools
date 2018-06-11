function EMG = spEMG(varargin)
%% SPEMG    Spike-triggered EMG averaging
%
%   EMG = SPEMG('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%                   => ANY constant from DEFAULTS section, notably-
%                   -> 'NCH' : Determines number of channels of EMG to ask
%                              the names of and plot.
%                   -> 'EMG_ID' : Identifier for single-channel files for
%                                 EMG recordings.
%                   -> 'SPIKE_ID' : Identifier for file containing spike 
%                                   onset sample indices.
%                   -> 'RECT' : (Default: false); setting this to true
%                               automatically rectifies all EMG data.
%
%                   ALSO
%                   -> 'MUSCLES' (def: NONE; if not specified, prompts user
%                                            to list the implanted EMG
%                                            muscles. Specify as a cell
%                                            array of strings that is the
%                                            same length as NCH)
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
%     EMG       :   Cell array of tables. Each cell corresponds to a unit,
%                   and contains the following fields, with each table row
%                   corresponding to a new channel (muscle).
%                   -> ch  : Channel number
%                   -> name: Name of muscle
%                   -> avg : Vector of spike-averaged EMG waveforms
%                   -> tr  : All spike trials for EMG waveforms
%                   -> t   : Vector of time values associated avg
%                   -> fs  : EMG sampling frequency
%                   -> ID  : Unit cluster file used for this table
%                   -> t_s : Vector of spike times relative to start of the
%                            recording (seconds)
%                   
%   Also generates a figure with spike-triggered EMG for each channel.
%
% By: Max Murphy    v1.0    06/08/2017  Original version (R2017a)
%   See also: MOVE_ALL_DATA, MOVERECORDEDDATA, EXTRACT_MOVED_DATA

%% DEFAULTS
NCH = 4;                                % Number of EMG channels

RECT = false;                           % Rectify EMG activity

NTR = 100;                              % Number of individual EMG traces 
                                        % plot in grey.

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

SPIKE_ID = 'ptrain';                    % Stimulus file identifier

SPIKE_FS = 24414.0625;                  % Should always be unnecessary to 
                                        % specify, unless working with very
                                        % old data (prior to 2015).
                                        
EMG_FS = 4069.01;                       % Should always be unnecessary to 
                                        % specify this as well.
                                        
DEF_DIR = 'P:\Rat';                     % Edit this if you tend to only use
                                        % data from one specific directory.
                                        
SPIKE_DIR = '_ad-PT_SPC_Clusters\Good';

EMG_DIR = '_Digital';

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
blockname = strsplit(DIR,filesep);
blockname = blockname{end};

EMG_Files = dir(fullfile(DIR,[blockname EMG_DIR], ...
                    ['*' EMG_ID '*.mat']));
if isempty(EMG_Files)
        error(['EMG files not found. ' ...
               'Please check EMG_ID, EMG_DIR, or DIR.']);
end

SPIKE_Files = dir(fullfile(DIR,[blockname SPIKE_DIR], ...
                    ['*' SPIKE_ID '*.mat']));
if isempty(SPIKE_Files)
    error(['SPIKE files not found. ' ...
           'Please check SPIKE_ID, SPIKE_DIR, or DIR.']);
end

EMG_out = cell(numel(SPIKE_Files),1);

%% GET STIMULATION SAMPLE INDICES AND TIME VECTOR
for iSpk = 1:numel(SPIKE_Files)
    spk = load(fullfile(DIR,[blockname SPIKE_DIR], ...
                        SPIKE_Files(iSpk).name));
    if ~isfield(spk,'fs')
        spk_fs = SPIKE_FS;
    else
        spk_fs = spk.fs;
    end

    spk = find(spk.peak_train)./spk_fs;
    
    if ~isnan(T_FINISH)
        spk = spk(spk<=T_FINISH);
    end
    
    spk = spk - T_BEGIN;    
    spk = spk(spk>=0);
    
    NS = numel(spk);
    t_s = repmat({spk},NCH,1);

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
    clc; fprintf(1,'Computing spike-triggered EMG for:\n');
    fprintf(1,'->\t%s, cluster %d\n\n',digitalblockname,iSpk);
    fprintf(1,'\tMUSCLES\n');
    fprintf(1,'\t-------\n');
    for iCh = 1:NCH
        fprintf(1,'\t->\t%s\n',MUSCLES{iCh});
    end

    for iCh = 1:NCH
        emg = load(fullfile(DIR,[blockname EMG_DIR], ...
                        EMG_Files(iCh).name));
        if isfield(emg,'fs')
            fs(iCh) = emg.fs;
        else
            fs(iCh) = EMG_FS;
        end
        emg.data = interp(double(emg.data),round(spk_fs/fs(iCh)));
        fs(iCh) = fs(iCh) * round(spk_fs/fs(iCh)); % Not "even" factor
        
        % Get selected start/stop times for data
        TT = (0:(numel(emg.data)-1))/fs(iCh);
        if ~isnan(T_FINISH)
            emg.data = emg.data(TT <= T_FINISH);
            TT = TT(TT<=T_FINISH);
        end
        
        if T_BEGIN> 0
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
            ind = stim_inds + round(spk(iS)*spk_fs);

            if (~any(ind<=0) && ...
                max(ind) <= numel(emg.data))
                tr{iCh}(iS,:) = emg.data(ind);
                sd_vec = [sd_vec, sd_inds + round(spk(iS)*spk_fs)]; %#ok<AGROW>
            else
                warning('Spike %d too close to beginning or end.',iS);
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
    rec = strsplit(SPIKE_Files(iSpk).name,'_');
    rec = strjoin(rec(1:2),'_');

    nrow = ceil(sqrt(NCH));
    ncol = nrow;


    %% MAKE FIGURE

    figure('Name',[rec '_spEMG'], ...
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
        
        plot(t{iCh},avg{iCh}, 'LineWidth', 3, ...
                              'Color', COL(iCh,:));

        line([0 0],[ymin ymax], ...
            'LineWidth', 1, ...
            'Color', 'r', ...
            'LineStyle', '--');

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

    suptitle(sprintf('%s %d pulse stim-triggered EMG',rec));

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
                savefig(gcf,fullfile(SAVE_DIR,[rec '_spEMG' ...
                    num2str(iSpk)  '_' t1 '_' t2  '.fig']));
                saveas(gcf,fullfile(SAVE_DIR,[rec '_spEMG' ...
                    num2str(iSpk)  '_' t1 '_' t2  '.jpeg']));
            end
        else
            savefig(gcf,fullfile(SAVE_DIR,[rec '_spEMG' ...
                num2str(iSpk)  '_' t1 '_' t2  '.fig']));
            saveas(gcf,fullfile(SAVE_DIR,[rec '_spEMG' ...
                num2str(iSpk)  '_' t1 '_' t2  '.jpeg']));
        end
    end

    if CLOSE_FIG
        delete(gcf);
    end

    %% SPECIFY OUTPUT
    ch = reshape(1:NCH,NCH,1);
    name = reshape(MUSCLES,NCH,1);
    ID = repmat({SPIKE_Files(iSpk).name(1:end-4)},NCH,1);

    EMG = table(ch, name, avg, tr, t, mu, sd, fs,ID, t_s);

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
                    save(fullfile(SAVE_DIR,[rec '_spEMG_'...
                        num2str(iSpk) '_' t1 '_' t2 '.mat']),'EMG','-v7.3');
                end

            end
        else
            save(fullfile(SAVE_DIR,[rec '_spEMG' ...
                num2str(iSpk) '_' t1 '_' t2 '.mat']),'EMG','-v7.3');
        end
    end
    
    EMG_out{iSpk,1} = EMG;
    
end
EMG = EMG_out;


end