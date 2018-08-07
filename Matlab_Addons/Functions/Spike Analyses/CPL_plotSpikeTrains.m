function CPL_plotSpikeTrains(behaviorData,external_events,varargin)
%% CPL_PLOTSPIKETRAINS  Plot all rasters for spike trains in a given BLOCK
%
%  CPL_PLOTSPIKETRAINS;
%  CPL_PLOTSPIKETRAINS(behaviorData);
%  CPL_PLOTSPIKETRAINS(behaviorData,external_events,'NAME',value,...);
%  CPL_PLOTSPIKETRAINS([],[],'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  behaviorData   :     Table from CPL_READBEHAVIOR. First N-2 variables
%                       are different alignment times (such as 'reach 
%                       onset' or 'grasp onset' etc.) relating to a single
%                       trial per row. Second to last variable is the trial
%                       outcome (0: fail, 1: successful) and last is some
%                       other trial identifier char; for example, 
%                       'L' vs 'R' to delineate between left and right
%                       reaches but could be other things as well.
%
%  external_events :    Struct where each field is a vector of times of
%                       "external" events that happened at some time during
%                       the experiment, which can then be superimposed on
%                       trial rows of rasters.
%
% varargin        :     (OPTIONAL) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Makes figures with rasters aligned to the time points in behaviorData,
%  by Unit, with different subplot columns corresponding to different trial
%  type identifiers from the last column of behaviorData.
%
% By: Max Murphy  v1.0  05/07/2018  Original version (R2017b)
%                                   [rough - could be improved a lot]
%
%                 v1.1  07/29/2018  Added more flexible handling so that
%                                   different types of 'behaviorData'
%                                   tables can be used (from different
%                                   experiments). Also added save features
%                                   for the actual plots.


%% DEFAULTS
DIR = nan;
FS = 24414.0625; % Default for oldest, which is TDT, which may not have pars.FS in files

DEF_DIR = 'P:\Rat\BilateralReach\Murphy';
SPIKE_DIR = '_wav-sneo_CAR_Spikes';
SPIKE_ID = 'ptrain';

BEHAV_ID = '_Scoring.mat';

ALIGNMENT = {'Reach';'Grasp'};
NUM_ID_VARNAME = 'Outcome';
CHAR_ID_VARNAME = 'Forelimb';
DEBUG = false;

AUTO_SAVE = true;
OUT_ID = 'Rasters';

X = nan;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET DIRECTORY
if isnan(DIR)
   DIR = uigetdir(DEF_DIR,'Select recording BLOCK');
   if DIR == 0
      error('No recording BLOCK specified. Script aborted.');
   end
end

block = strsplit(DIR,filesep);
block = block{end};

%% LOAD BEHAVIOR DATA IF NOT SUPPLIED ALREADY
% Check for behaviorData table
if exist('behaviorData','var')~=0
   if ~istable(behaviorData)
      beh_file = fullfile(DIR,[block BEHAV_ID]);
      if exist(beh_file,'file')==0
         error('Behavior scoring not yet done for %s, or bad ID: %s.',...
            block,BEHAV_ID);
      else
         b = load(beh_file);
         if isfield(b,'external_events')
            % Automatically get "extra" alignment events
            external_events = b.external_events;
            
         end
         
         if isfield(b,'behaviorData')
            behaviorData = b.behaviorData;   
         else
            error('No behaviorData variable found.');
         end
      end
   end
end


% Check for "external_events" input argument as well
if exist('external_events','var')~=0
   if ~isempty(external_events)
      ex_V = fieldnames(external_events);
      nEx = numel(ex_V);

      Z = cell(nEx,1);
      for iV = 1:nEx
         Z{iV} = external_events.(ex_V{iV});
      end
   else
      ex_V = [];
      Z = [];
      nEx = 0;
   end
end

%% DOUBLE-CHECK VARIABLE NAMES IN BEHAVIORDATA
v = behaviorData.Properties.VariableNames;

% Check "alignment" possibilities (behavior strings usually)
iKeep = true(size(ALIGNMENT));
for iA = 1:numel(ALIGNMENT)
   if ~ismember(ALIGNMENT{iA},v)
      warning('%s is not an alignment option.\n',ALIGNMENT{iA});
      iKeep(iA) = false;
   end
end
ALIGNMENT = ALIGNMENT(iKeep);

% Check numeric variable trial identifier
if ~ismember(NUM_ID_VARNAME,v)
   warning('%s is not a valid numeric trial ID variable. Using %s instead.',...
      NUM_ID_VARNAME,v{numel(v)-1});
   NUM_ID_VARNAME = v{numel(v)-1};
end

% Check character variable trial identifier
if ~ismember(CHAR_ID_VARNAME,v)
   warning('%s is not a valid char trial ID variable. Using %s instead.',...
      CHAR_ID_VARNAME,v{numel(v)});
      CHAR_ID_VARNAME = v{numel(v)};
end

%% LOAD SPIKE TRAINS
F = dir(fullfile(DIR,[block SPIKE_DIR],['*' SPIKE_ID '*.mat']));

if ~iscell(X)
   X = cell(numel(F),1);
   fprintf(1,'\nLoading spike trains for %s...',block)
   h = waitbar(0,'Please wait, loading spike trains...');
   for ii = 1:numel(F)
      in = load(fullfile(F(ii).folder,F(ii).name));
      X{ii} = in.peak_train;
      if DEBUG
         mtb(X);
      end
      if ii == 1
         if isfield(in,'pars')
            if isfield(in.pars,'FS')
               FS = in.pars.FS;
               fprintf(1,'\n->\tFS detected: %g Hz\t\t\t\t ...',FS);
            else
               beep;
               fprintf(1,'\n->\tUsing default FS: %g Hz\t\t\t\t ...',FS);
            end
         else
            beep;
            fprintf(1,'\n->\tUsing default FS: %g Hz\t\t\t\t ...',FS);
         end
      end
      waitbar(ii/numel(F));
   end
   delete(h);
   fprintf(1,'complete.\n');
else
   beep;
   fprintf(1,'\n->\tUsing default FS: %g Hz\t\t\t\t ...\n',FS);
end


char_ID = unique(behaviorData.(CHAR_ID_VARNAME));
num_ID = unique(behaviorData.(NUM_ID_VARNAME));

%% MAKE ONE FIGURE PER CHANNEL, PER ALIGNMENT, WITH SUBPLOTS (ONE AT A TIME)
for ii = 1:numel(F) % Represents all channels
   for iA = 1:numel(ALIGNMENT) % Represents all alignments per trial
      % Get spike times
      byChannel = CPL_alignspikes(X,behaviorData.(ALIGNMENT{iA}),'FS',FS);
      
      % Get "extra" alignment times
      if nEx > 0
         byVar = CPL_alignspikes(Z,behaviorData.(ALIGNMENT{iA}),'FS',FS);
         EX = cell(numel(byVar{1}),numel(byVar));
         for iEx = 1:nEx
            EX(:,iEx) = byVar{iEx};
         end
      end
                               
      fig_xy = rand(1,2) * 0.3; % Jitter each figure around a little bit
      fig_str = sprintf('%s: Channel %02g (%s)',block,ii,ALIGNMENT{iA}); 
      figure('Name',[block ': Channel ' num2str(ii-1,'%02g')],...
         'Color','w',...
         'Units','Normalized',...
         'Position',[fig_xy, 0.4 0.3]);
   
      % Keep track of which subplot we're on (for simplicity)
      subplot_pos = 1;
      for iNum = 1:numel(num_ID) % Flexible (i.e. outcome 0 vs 1 for success)
         for iChar = 1:numel(char_ID) % Flexible (i.e. 'L'/'R' for hand)
            subplot(numel(num_ID),numel(char_ID),subplot_pos);
            
            % Get alignment trials that meet criteria
            curIdx = getTrialSubset(char_ID(iChar),num_ID(iNum),...
                                    behaviorData.(CHAR_ID_VARNAME),...
                                    behaviorData.(NUM_ID_VARNAME));
                                 
            % Make the raster plot for this channel/alignment subplot
            if nEx > 0
               CPL_plotSpikeRaster(byChannel{ii}(curIdx),...
                  'PlotType','vertline',...
                  'AutoLabel',true,...
                  'Extra',EX,...
                  'ExtraLabel',ex_V);
            else
               CPL_plotSpikeRaster(byChannel{ii}(curIdx),...
                  'PlotType','vertline',...
                  'AutoLabel',true);
            end
            titlestr = sprintf('%s - %s: %d',...
               char_ID(iChar),...
               NUM_ID_VARNAME,...
               num_ID(iNum));
            title(titlestr);

            subplot_pos = subplot_pos + 1;
         end
      end
      
      % Make super-title for all subplots and save if desired
      suptitle(strrep(fig_str,'_','-'));
      
      
      % Save and close, if desired
      if AUTO_SAVE
         align_ID = ['_' ALIGNMENT{iA}];
         save_close_fig(gcf,DIR,block,F(ii).name,SPIKE_ID,OUT_ID,align_ID);
      end
   end
end

   function curIdx = getTrialSubset(char_ID_match,...
                                    num_ID_match,...
                                    char_ID_candidates,...
                                    num_ID_candidates)

      curIdx = ismember(char_ID_candidates,char_ID_match) & ...
               ismember(num_ID_candidates,num_ID_match);
   end

   function save_close_fig(fig,DIR,block,spikename,spike_ID,out_ID,align_ID)
      savepath = fullfile(DIR,[block '_' out_ID]);
      if exist(savepath,'dir')==0
         mkdir(savepath);
      end
      
      fname = strrep(spikename(1:(end-4)),spike_ID,[out_ID align_ID]);
      savefig(fig,fullfile(savepath,[fname '.fig']));
      saveas(fig,fullfile(savepath,[fname '.jpeg']));
      delete(fig);
      
   end
end