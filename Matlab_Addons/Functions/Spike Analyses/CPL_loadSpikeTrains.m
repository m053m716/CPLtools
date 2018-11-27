function [X,fs,SPK] = CPL_loadSpikeTrains(varargin)
%% CPL_LOADSPIKETRAINS  Load spike trains from BLOCK structure
%
%  [X,fs,SPK] = CPL_LOADSPIKETRAINS;
%  [X,fs,SPK] = CPL_LOADSPIKETRAINS('NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  varargin       :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%     X           :     Cell array of spike peak trains.
%
%     fs          :     Sampling rate for amplifier acquisition in this
%                          recording block.
%
%   SPK           :     Formatted table with columns corresponding to X and
%                          fs, as well as additional columns corresponding
%                          to spike filename (and metadata?)
%
% By: Max Murphy  v1.0  11/26/2018  Original version (R2017b)

%% DEFAULTS
X = nan;
FS = 24414.0625;
DIR = nan;

DEF_DIR = 'P:\Rat\BilateralReach\Murphy';
SPIKE_DIR = '_wav-sneo_CAR_Spikes';
SPIKE_ID = 'ptrain';

DEBUG = false;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% SELECT BLOCK IF NECESSARY
if isnan(DIR)
   DIR = uigetdir(DEF_DIR,'Select recording BLOCK');
   if DIR==0
      error('No block selected, script aborted.');
   end
else
   if exist(DIR,'dir')==0
      error('Invalid BLOCK location. Check DIR (%s)',DIR);
   end
end

block = strsplit(DIR,filesep);
block = block{end};

%% LOAD ALL SPIKE TRAINS INTO CELL ARRAY AND GET SAMPLING RATE IF PRESENT
F = dir(fullfile(DIR,[block SPIKE_DIR],['*' SPIKE_ID '*.mat']));

if ~iscell(X)
   X = cell(numel(F),1);
   fprintf(1,'\nLoading spike trains for %s...',block)
   h = waitbar(0,'Please wait, loading spike trains...');
   for ii = 1:numel(F)
      in = load(fullfile(F(ii).folder,F(ii).name));
      X{ii} = in.peak_train;
      if DEBUG
         mtb(X); %#ok<UNRCH>
      end
      if ii == 1
         if isfield(in,'pars')
            if isfield(in.pars,'FS')
               fs = in.pars.FS;
               fprintf(1,'\n->\tFS detected: %g Hz\t\t\t\t ...',FS);
            else
               beep;
               fprintf(1,'\n->\tUsing default FS: %g Hz\t\t\t\t ...',FS);
               fs = FS;
            end
         else
            beep;
            fprintf(1,'\n->\tUsing default FS: %g Hz\t\t\t\t ...',FS);
            fs = FS;
         end
      end
      waitbar(ii/numel(F));
   end
   delete(h);
   if exist('alert.mat','file')==0
      beep;
   else
      alertSound = load('alert.mat','fs','sfx');
      sound(alertSound.sfx,alertSound.fs);
   end
   fprintf(1,'complete.\n');
else
   if exist('alert.mat','file')==0
      beep;
      pause(0.5);
      beep;
   else
      alertSound = load('alert.mat','fs','sfx');
      sound(alertSound.sfx,alertSound.fs);
      pause(0.5);
      sound(alertSound.sfx,alertSound.fs);
   end
   fprintf(1,'\n->\tUsing default FS: %g Hz\t\t\t\t ...\n',FS);
   fs = FS;
end

%% FORMAT TO TABLE
pname = {F.folder}.';
fname = {F.name}.';

SPK = table(pname,fname,repmat(fs,numel(pname),1),X);
SPK.Properties.VariableNames = {'pname','fname','fs','Peaks'};

end