function CompletedName = SortClusters(varargin)
%% SORTCLUSTERS View all clusters within folder & manually select good ones
%
%   CompletedName = SORTCLUSTERS('NAME', value, ...)
%
%   Suggested usage: 
%   ------------------
%   TrackSorting = [];
%   TrackSorting = [TrackSorting; {SortClusters('DEFDIR',Tank)}];
%
%   or
%   
%   % These may change depending on file structure organization:
%   TANK = 'P:\Rat\ITLProject'; % Example tank location
%   BK_ID = 'R*';   % Example block identifier. Could use 'M*' for monkey.
%   SPK_ID = '_pca-PT_SPC_CAR_Spikes'; % Example spike folder identifier
%
%   % Gets all blocks from a rat tank and loop through them
%   temp = dir(fullfile(TANK,BK_ID));  
%   for iF = 1:numel(sd)          % get all "spike directories"
%       bkdir{iF,1} = fullfile(F(iF).folder,F(iF).name);
%       bk{iF,1} = F(iF).name;
%       spikes{iF,1} = fullfile(bkdir{iF},[bk{iF} SPK_ID]);
%   end
%   
%   % Make file folder structure:
%   F = struct('bk',bk,'bkdir',bkdir,'spikes',spikes,'sorted',false);
%
%   % This command can be repeated to keep track of manual sorting:
%   SortClusters('DIR',F(iF).spikes,'FSTRUCT',F); iF = iF + 1;
%
%   Because 'FSTRUCT' has been provided as an optional input argument, then
%   when the UI is submitted F(iF).sorted will update to true.
%
%   --------
%    INPUTS
%   --------
%   varargin        :       'NAME', value optional input argument pairs.
%                           --------------------------------------------
%                           'DEFDIR' : (def: P:/Rat) String specifying
%                                       default directory for selection UI.
%
%                           'DIR' : String specifying directory with split
%                                   clusters. If left empty (default), a
%                                   dialog box will prompt the user for the
%                                   correct directory.
%
%                           'ODIR' : (For 'O'ther DIR; in cases where you
%                                     want to split clusters by periods
%                                     within a given recording, specify the
%                                     full paths of the 'SPLITTED' sister
%                                     directories; cell array with each 
%                                     cell the full path as a string).
%
%                           'FSTRUCT' : (def: none) If provided, will
%                                       update the base workspace with sort
%                                       completion status of current
%                                       sorting.
%
%                                       NOTE: Must refer to the spike
%                                       directory as a field named "spikes"
%
%                           'FSTRUCT_NAME' : If other than 'F' then this
%                                            must be specified as a string
%                                            to match the base workspace
%                                            file-structure organizing
%                                            variable.
%
%                           'YLIM'  :   (def: [-200 100]) Can be specified
%                                       to change plot axis scaling.
%
%   --------
%    OUTPUT
%   --------
%   CompletedName   :       Returns the name as a string of the folder you
%                           just sorted spikes in. 
%
%   Creates two sub-folders in the specified directory. Moves the profiles
%   identified as "good" into the "good" folder, and the profiles
%   identified as "bad" into the "bad" folder. All clusters start out
%   identified as "bad" (red), but by clicking the background color you can
%   switch them between "bad" and "good" (light-blue). 
%
% By: Max Murphy    v1.3 07/21/2017    Added option to specify extra
%                                      directories that should have spikes
%                                      assigned as "good" or "artifact" in
%                                      the same fashion as the current
%                                      directory.
%                   v1.2 02/03/2017    Moved to server, slightly modified
%                                      parameters.
%                   v1.1 12/27/2016    Plots up to MAXSPIKES original
%                                      waveforms in grey.
%                   v1.0 11/18/2016    Original version

%% DEFAULTS
% Maybe modify:
MAXSPIKES  = 100;    % Max # spikes to plot
T          = 1.4;    % Snippet length (depends upon spike detection method)
SPKCOL     = 'k';    % Color of spike traces
TMPCOL     = 'w';    % Color of template (dashed) trace
YLIM       = [-250 150];    % (Bias towards negative peak)

% Best to modify this through varargin:
DEFDIR     = 'P:/Rat';  % Default tank UI search directory
FSTRUCT_NAME = 'F';     % Default name for file organization structure

% Please only modify on local versions:
SAVEFLAG    = true;                 % Flags whether data has been saved
GFOLDER     = 'Good';               % "Good" spikes folder name
BFOLDER     = 'Artifact';           % "Bad" spikes folder name
MAT_ID      = '*ptrain*.mat';       % ID for SPC files
DIR_ID      = '*_Clust*';           % ID for SPC folder
PROBE_ID    = 3;                    % Number of '_' separations from end
BKCOL       = [216/255 220/255 224/255; 178/255 222/255 183/255];     % Background colors

%% ADD HELPER FUNCTIONS
pname = mfilename('fullpath');
fname = mfilename;
pname = pname(1:end-length(fname));

% addpath([pname 'libs']);
clear pname fname

%% ASSIGN handles
handles.SAVEFLAG = SAVEFLAG;
handles.GFOLDER = GFOLDER;
handles.BFOLDER = BFOLDER;
handles.BKCOL = BKCOL;
handles.MAXSPIKES = MAXSPIKES;
handles.T = T;
handles.SPKCOL = SPKCOL;
handles.TMPCOL = TMPCOL;
handles.YLIM = YLIM;
handles.MAT_ID = MAT_ID;
handles.DEFDIR = DEFDIR;
handles.FSTRUCT_NAME = FSTRUCT_NAME;
handles.FSTRUCT_PASSED = false;

%% PARSE VARARGIN
for iV = 1:2:length(varargin)
    eval(['handles.' upper(varargin{iV}) '=varargin{iV+1};']);
    if strcmp(varargin{iV},'FSTRUCT')
       handles.FSTRUCT_PASSED = true;
    end
end

%% SELECT FOLDER
% If pre-specified in optional arguments, skip this step.
if ~isfield(handles,'DIR') 
    handles.DIR = uigetdir(handles.DEFDIR);
    
    if handles.DIR == 0 % Must select a directory
        error('Must select a valid directory.');
    elseif exist(handles.DIR, 'dir') == 0
        error('Must select a valid directory.');
    end
    
    contents = dir([handles.DIR filesep DIR_ID]);
    if isempty(contents)
    
        listing = dir([handles.DIR filesep handles.MAT_ID]);

        if isempty(listing) % Must contain valid files
            error([handles.DIR ' does not contain any files of the format ' ...
                   handles.MAT_ID '. Check IDENTIFIER or verify that directory' ...
                   ' contains appropriate files.']);
        end
        
    elseif numel(contents) > 1
        error('More than one Cluster directory. Please select directory.');
        
    else
        handles.DIR = [handles.DIR filesep contents.name];
        listing = dir([handles.DIR filesep handles.MAT_ID]);
        
    end
    CompletedName = handles.DIR;
    
else    % If a pre-specified path exists, must be a valid path.
    
    if handles.DIR == 0  % Must select a directory
        error('Must select a valid directory.');
    elseif exist(handles.DIR, 'dir') == 0
        error('Must select a valid directory.');
    end
    
%     handles.DIR = DIR;
    contents = dir([handles.DIR filesep DIR_ID]);
    if isempty(contents)

        listing = dir([handles.DIR filesep MAT_ID]);
        
        if isempty(listing) % Must contain valid files
            error([handles.DIR ' does not contain any files of the format ' ...
                   MAT_ID '. Check IDENTIFIER or verify that directory' ...
                   ' contains appropriate files.']);
        end
        
    elseif numel(contents) > 1
        error('More than one Cluster directory. Please select directory.');
        
    else
        handles.DIR = [handles.DIR filesep contents.name];
        listing = dir([handles.DIR filesep handles.MAT_ID]);
        
    end
    CompletedName = handles.DIR;
    
end

%% DETERMINE NUMBER OF PROBES
fnames = {listing.name}.';
handles.pnum = ones(size(fnames));
for iF = 1:numel(fnames)
    temp = strsplit(fnames{iF}, '_');
    temp = temp{end-PROBE_ID}(2:end);
    if isnan(str2double(temp))
        handles.pnum(iF) = 1;
    else
        handles.pnum(iF) = str2double(temp); 
    end
    clear temp;
end
clear iF fnames
nProbes = numel(unique(handles.pnum));

pLabel = cell(nProbes,1);
for iP = 1:nProbes
    pLabel{iP} = ['P' num2str(iP)];
end
clear iP

%% DETERMINE NUMBER OF CLUSTERS AND APPROPRIATE SUBPLOT LAYOUT
nClust = numel(listing);
handles.ClustPlot = cell(nClust,1);
handles.SpikeClusters = false(1,nClust);
handles.probeVec = cell(nProbes,1);
for iP = 1:nProbes
    handles.probeVec{iP} = find(abs(handles.pnum - iP) < eps);   
end
handles.probeNum = 1;
handles.DisableTab = false(nProbes,1);


%% CREATE SUB-FOLDERS



%% CREATE FIGURE FOR ALL CLUSTERS
MainFig = figure('Name', 'Manual Cluster Determinations', ...
                   'Units', 'Normalized', ...
                   'Position', [0.1 0.1 0.8 0.8], ...
                   'Color', [64/255 79/255 96/255], ...
                   'NumberTitle', 'off', ...
                   'ToolBar', 'none', ...
                   'MenuBar', 'none');
   
%% CREATE CLUSTER SUBPLOT PANEL
ClustPanel = uipanel(MainFig, 'Units', 'normalized', ...
                             'Position', [0.05, 0.05, 0.75, 0.9], ...
                             'BackgroundColor', [64/255 79/255 96/255], ...
                             'ForegroundColor', [1 1 1], ...
                             'FontSize', 14, ...
                             'Title', 'Spike Clusters');
                         
%% CREATE TAB GROUP
ProbeGroup = uitabgroup(ClustPanel, ...
                            'SelectionChangedFcn', @tabChangedCB);
    P1tab = uitab(ProbeGroup, 'Title', 'P1', ...
                            'BackgroundColor', [64/255 79/255 96/255], ...
                            'UserData', 1, ...
                            'TooltipString','Probe 1 Clusters', ...
                            'ButtonDownFcn',@SwitchTab);
        

    for iP = 2:nProbes
        uitab(ProbeGroup, 'Title', pLabel{iP}, ...
                        'BackgroundColor', [64/255 79/255 96/255], ...
                        'UserData', iP, ...
                        'TooltipString',sprintf('Probe %d Clusters',iP),...
                        'ButtonDownFcn',@SwitchTab);
    end

%% CREATE SAVE AND EXIT BUTTONS
ProbeSaveButton = uicontrol(MainFig, 'Style', 'pushbutton', ...
                            'Units', 'normalized', ...
                            'Position', [0.825, 0.7, 0.15, 0.1], ...
                            'FontSize', 16, ...
                            'BackgroundColor', [178/255 222/255 183/255], ...
                            'ForegroundColor', 'k', ...
                            'String', 'Save P1', ...
                            'UserData', 1, ...
                            'Callback', @SaveProbeFunction);
                        
if ((nProbes < 2) || (isfield(handles,'ODIR')))
    ProbeSaveButton.Enable = 'off';
end

SubmitButton = uicontrol(MainFig, 'Style', 'pushbutton', ...
                            'Units', 'normalized', ...
                            'Position', [0.825, 0.5, 0.15, 0.1], ...
                            'FontSize', 16, ...
                            'BackgroundColor', [226/255 211/255 174/255], ...
                            'ForegroundColor', 'k', ...
                            'String', 'Submit', ...
                            'Callback', @SubmitFunction);
                        
uicontrol(MainFig, 'Style', 'pushbutton', ...
                            'Units', 'normalized', ...
                            'Position', [0.825, 0.3, 0.15, 0.1], ...
                            'FontSize', 16, ...
                            'BackgroundColor', [222/255 178/255 178/255], ...
                            'ForegroundColor', 'k', ...
                            'String', 'Exit', ...
                            'Callback', @ExitFunction);
                        


%% SUB-FUNCTIONS
    %Create function for selecting clusters
    function ClusterSelect(src, ~) 

        if handles.ClustPlot{src.UserData}.Color(1) < .71
            set(handles.ClustPlot{src.UserData}, 'Color', handles.BKCOL(1,:))
            handles.SpikeClusters(src.UserData) = false;
        else
            set(handles.ClustPlot{src.UserData}, 'Color', handles.BKCOL(2,:));
            handles.SpikeClusters(src.UserData) = true;
        end
    end
    
    %Create function for "saving" ALL data to appropriate sub-folders
    function SubmitFunction(~,~)
        msg = questdlg(['This will move files from current ' ...
              'directory, after which subsequent saves will not work. ' ...
              'Moves files for ALL probes (not just this tab).' ...
              'Proceed?'], ...
              'Confirm Save', ...
              'Yes', 'Cancel', 'Yes');
        if strcmp(msg, 'Cancel')
            disp('Files not saved.');
            return
        else
            SpikeVec = find(handles.SpikeClusters);
            ArtVec   = find(~handles.SpikeClusters);
            MoveFiles(handles.DIR,SpikeVec,ArtVec);
            if isfield(handles,'ODIR')
                for iODIR = 1:numel(handles.ODIR)
                    MoveFiles(handles.ODIR{iODIR},SpikeVec,ArtVec);
                end
            end
        end
        
        msg = questdlg('Exit?', 'Quit', 'Yes', 'No', 'Yes');
        if strcmp(msg, 'Yes')
            delete(MainFig);
            disp(['Manual scoring completed for ' handles.DIR]);
            if handles.FSTRUCT_PASSED
                ind = ismember({handles.FSTRUCT.spikes},handles.DIR);
                handles.FSTRUCT(ind).sorted = true;
                mtb(handles.FSTRUCT_NAME,handles.FSTRUCT);
            end
            clear
            return
        end
    end
    
    %Create function for "saving" single probe data to appropriate sub-folders
    function SaveProbeFunction(src,~)
        msg = questdlg(['This will move files from current ' ...
              'directory, after which subsequent saves will not work. ' ...
              'Proceed?'], ...
              'Confirm Save', ...
              'Yes', 'Cancel', 'Yes');
        if strcmp(msg, 'Cancel')
            disp('Files not saved.');
            return
        else
            thisProbe = (abs(handles.pnum - src.UserData) < eps).';
            GoodSpikes = find(handles.SpikeClusters & thisProbe);
            BadSpikes   = find(~handles.SpikeClusters & thisProbe);

            clc
            disp('Please wait, copying & moving files...');
            GoodSpikes = reshape(GoodSpikes,1,numel(GoodSpikes));
            if exist([handles.DIR filesep handles.GFOLDER], 'dir') == 0
                mkdir([handles.DIR filesep handles.GFOLDER]);
            end

            if exist([handles.DIR filesep handles.BFOLDER], 'dir') == 0
                mkdir([handles.DIR filesep handles.BFOLDER]);
            end

            for ii = GoodSpikes
                copyfile([handles.DIR filesep listing(ii).name], ...
                         [handles.DIR filesep handles.GFOLDER]);
            end

            BadSpikes = reshape(BadSpikes,1,numel(BadSpikes));
            for ii = BadSpikes
                movefile([handles.DIR filesep listing(ii).name], ...
                         [handles.DIR filesep handles.BFOLDER]);
            end

            handles.DisableTab(src.UserData) = true;
            fprintf(1, '\n');
            fprintf(1, '------------------------\n');
            fprintf(1,'%s successful.\n',src.String);
            fprintf(1, '------------------------\n');
            fprintf(1, '\n');
            SubmitButton.Enable = 'off';
            handles.SAVEFLAG = false;    
        end
        
        if ~any(~handles.DisableTab)
            clc;
            msg = questdlg('Exit?', 'Quit', 'Yes', 'No', 'Yes');
            if strcmp(msg, 'Yes')
                disp(['Manual scoring completed for ' handles.DIR]);
                if handles.FSTRUCT_PASSED
                    ind = ismember({handles.FSTRUCT.spikes},handles.DIR);
                    handles.FSTRUCT(ind).sorted = true;
                    mtb(handles.FSTRUCT_NAME,handles.FSTRUCT);
                end
                delete(MainFig);
                return
            end
        end
        
    end

    %Create function to exit this function
    function ExitFunction(~,~)
        if (handles.SAVEFLAG || any(~handles.DisableTab))
            msg = questdlg('Exit without saving?', 'Double-Checking', ...
                           'Yes', 'No', 'No');
                       
            if strcmp(msg, 'No')
                return
            else
                disp('Exited manual scoring without saving.');
            end
        end
        disp(['Exited manual scoring for ' handles.DIR]);
        delete(MainFig);
        return
    end

    %Create function to switch tabs for each probe
    function SwitchTab(src, ~)
        handles.probeNum = src.UserData;
        
        nPchans = numel(handles.probeVec{handles.probeNum});
        nrow = ceil(sqrt(nPchans));
        ncol = nrow;
        
        for iCh = 1:nPchans
            % Load cluster data
            data = load([handles.DIR filesep  ...
                listing(handles.probeVec{handles.probeNum}(iCh)).name], ...
                'spikes');
            if isempty(data.spikes)
                continue
            end

            SpikeTemplate = mean(data.spikes);    
            subplot(nrow, ncol, iCh, 'Parent', ProbeGroup.SelectedTab);
            handles.ClustPlot{handles.probeVec{handles.probeNum}(iCh)} = ...
                subplot(nrow,ncol,iCh, ...
                    'UserData', handles.probeVec{handles.probeNum}(iCh), ...
                    'Parent', ProbeGroup.SelectedTab, ...
                    'ButtonDownFcn', @ClusterSelect); 
            hold on 
            delete(get(gca,'Children'));
            nspk = size(data.spikes,1);
            nspkSamples = numel(data.spikes(1,:));
            TVEC = linspace(0,handles.T,nspkSamples);

            if nspk >= handles.MAXSPIKES
                spkvec = RandSelect(1:nspk,handles.MAXSPIKES);
                plot(TVEC, data.spikes(spkvec,:).', ...
                     'Color', handles.SPKCOL);
            else
                plot(TVEC, data.spikes.', ...
                     'Color', handles.SPKCOL);
            end
            
            plot(TVEC, SpikeTemplate, ...
                         'LineWidth', 2.5, ...
                         'Color', handles.TMPCOL, ...
                         'LineStyle', '--');

            hold off

            clear data
            
            if handles.SpikeClusters(handles.probeVec{handles.probeNum}(iCh))
                set(gca, 'Color', handles.BKCOL(2,:));
            else
                set(gca, 'Color', handles.BKCOL(1,:));
            end
            set(gca, 'XColor', [64/255 79/255 96/255]);
            set(gca, 'YColor', [64/255 79/255 96/255]);
            set(gca, 'UserData', handles.probeVec{handles.probeNum}(iCh));
            set(gca, 'Parent', ProbeGroup.SelectedTab);
            set(gca, 'ButtonDownFcn', @ClusterSelect);
            set(gca, 'XLim', [min(TVEC) max(TVEC)]);
            set(gca, 'YLim', handles.YLIM);
            
            tempChildren = get(gca,'Children');
            for iT = 1:numel(tempChildren)
                set(tempChildren(iT),'ButtonDownFcn', @ClusterSelect);
                set(tempChildren(iT),'UserData', ...
                    handles.probeVec{handles.probeNum}(iCh));
            end
            
            handles.ClustPlot{handles.probeVec{handles.probeNum}(iCh)}=gca;

        end
    end

    %Create function to speed up switching tabs
    function tabChangedCB(~,eventdata)
        if isa(eventdata, 'matlab.ui.eventdata.MouseData')
            handles.oldProbeNum = handles.newProbeNum;
            handles.newProbeNum = eventdata.Source.UserData;
            delete(get(eventdata.Source,'Children'));
            ProbeSaveButton.String = ['Save P' num2str(handles.newProbeNum)];
            ProbeSaveButton.UserData = handles.newProbeNum;
        elseif isa(eventdata.OldValue, 'matlab.ui.container.Tab')
            
            delete(get(eventdata.OldValue,'Children'));
            handles.oldProbeNum = get(eventdata.OldValue, 'UserData');
            handles.newProbeNum = get(eventdata.NewValue, 'UserData');
            ProbeSaveButton.String = ['Save P' num2str(handles.newProbeNum)];
            ProbeSaveButton.UserData = handles.newProbeNum;
            if handles.DisableTab(handles.oldProbeNum)
                set(eventdata.OldValue, 'ButtonDownFcn', @tabChangedCB)
                set(eventdata.OldValue, 'BackgroundColor', [222/255 178/255 178/255]);
                set(eventdata.OldValue, 'ForegroundColor', 'k');
            end
        end
    end

    % Create function to move files when saving
    function MoveFiles(curdir,SpikeVec,ArtVec)
        
        spikefiles = dir(fullfile(curdir,handles.MAT_ID));
        if exist([curdir filesep handles.GFOLDER], 'dir') == 0
            mkdir([curdir filesep handles.GFOLDER]);
        end

        if exist([curdir filesep handles.BFOLDER], 'dir') == 0
            mkdir([curdir filesep handles.BFOLDER]);
        end

        clc
        disp('Please wait, copying & moving files...');
        for ii = SpikeVec
            copyfile([curdir '/' spikefiles(ii).name], ...
                     [curdir '/' handles.GFOLDER]);
        end
        for ii = ArtVec
            movefile([curdir '/' spikefiles(ii).name], ...
                     [curdir '/' handles.BFOLDER]);
        end

        handles.DisableTab = true(numel(handles.DisableTab),1);
        handles.SAVEFLAG = false;
        disp('Files moved successfully.');
    end

    %% INITIALIZE
    SwitchTab(P1tab);

end