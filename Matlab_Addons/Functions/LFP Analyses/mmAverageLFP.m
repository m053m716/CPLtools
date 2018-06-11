function [f,t,P] = mmAverageLFP(varargin)
%% MMAVERAGELFP  AVERAGE LFP SPECTRA ACROSS MANY RECORDINGS/CHANNELS
%
%   [f,t,P] = MMAVERAGELFP;
%   [f,t,P] = MMAVERAGELFP(F);
%   [f,t,P] = MMAVERAGELFP(__,'NAME',value,...);
%
%   --------
%    INPUTS
%   --------
%       F       :       (Optional) List of full filenames (with path also)
%                       for all LFP spectrogram files to average together.
%
%   varargin    :       (Optional) 'NAME',value input argument pairs.
%
%   --------
%    OUTPUT
%   --------
%      f        :       1 x N vector of frequency bin centers for points in
%                       P.
%
%      t        :       1 x T vector of times at which estimates were
%                       obtained.
%
%      P        :       N x T matrix of average spectral power from all
%                       files input.
%
% By: Max Murphy    v1.0    08/15/2017  Original version (R2017a)
%   See also: MMMEMFREQ, MMDN_FILT, MMDS

%% DEFAULTS
% Recording options
TMIN = 0;                   % Start time (minutes)
TMAX = 90;                  % End Time (minutes)
REZ = 100;                  % Smoothing (milliseconds)
K = 101;                    % Number of frequency bins
KMIN = 2;                   % Min. frequency bin
KMAX = 202;                 % Max. frequency bin

% File options
DEF_DIR = 'P:/Rat';         % Default UI selection directory

% Plot options
PLOT = true;                % Plot when finished?
NEWFIG = true;              % Make a new figure for this plot
CAXIS = [-6 6];             % Default color axis

LINEX = [15 15; ...         % Dashed line for marking epochs.
         35 35];            % (Values in minutes)

%% PARSE VARARGIN
if nargin>0
    if nargin == 1
        F = varargin{1};
    elseif rem(nargin,2)==0
        for iV = 1:2:numel(varargin)
            eval([upper(varargin{iV}) '=varargin{iV+1};']);
        end
    else
        F = varargin{1};
        for iV = 2:2:numel(varargin)
            eval([upper(varargin{iV}) '=varargin{iV+1};']);
        end
    end
end

%% GET INPUT
if exist('F','var')==0
    [fname,pname] = uigetfile('*MEM*.mat','Select LFP MEM files',DEF_DIR,...
                              'MultiSelect','on');      
    if iscell(fname)
        F = cell(numel(fname),1);
        for iF = 1:numel(fname)
            F{iF} = fullfile(pname,fname{iF});
        end
    else
        F = {fullfile(pname,fname)};
    end
end

pathnames = cell(size(F));
for iF = 1:numel(F)
    pathnames{iF} = strsplit(F{iF},filesep);
    pathnames{iF} = strjoin(pathnames{iF}(1:end-1),filesep);
end
nRec = numel(unique(pathnames));

%% SET UP INTERPOLATION VECTOR
T = (TMIN*60):(REZ*1e-3):(TMAX*60);

p = nan(K,numel(T),numel(F));
for iF = 1:numel(F)
    indata = load(F{iF},'amp','fs','pars');
    % Make sure there are the right frequency components
    if (abs(max(indata.pars.FREQS)-KMAX)>eps || ...
        abs(min(indata.pars.FREQS)-KMIN)>eps || ...
        abs(numel(indata.pars.FREQS)-K)>eps)
        continue;
    end
    t = indata.pars.NSAMP_PER_WIN/indata.fs;
    fprintf(1,'Interpolating file %d of %d',iF,numel(F));
    
    % Do transformation on power data
    indata.amp = log(indata.amp);
    for iK = 1:K
        if rem(iK-1,20)==0
            fprintf(1,'. ');
        end
        
        % Remove outlier points
        indata.amp(iK,indata.amp(iK,:)>(nanmean(indata.amp(iK,:))...
            +10*nanstd(indata.amp(iK,:)))) = nan;
        
        % Interpolate vector so all time series match up
        fnorm = (indata.amp(iK,:)-nanmean(indata.amp(iK,:)))./...
                  nanstd(indata.amp(iK,:));
        fnorm(t>max(T)) = [];
        p(iK,:,iF) = interp1(t(t<=max(T)),fnorm,T);
    end    
    fprintf(1,'complete.\n');
end

f = indata.pars.FREQS;
t = T;
P = nanmean(p,3)*sqrt(nRec); 

%% PLOT, IF SPECIFIED
if PLOT
    if NEWFIG
        figure('Name','Normalized MEM LFP Average Spectral Estimate',...
           'Units','Normalized', ...
           'Color','w',...
           'Position',[0.2 0.2 0.6 0.6]);
    end
    
    load('zmap.mat','zmap');
    colormap(zmap);
    fvec = logspace(0.1,2,1000)*KMIN;
    logP = nan(1000,numel(T));
    for iT = 1:numel(T)
        logP(:,iT) = interp1(f,P(:,iT),fvec);
    end
    
    o = imagesc(t./60,fvec,logP); 
    hold on;
    for iL = 1:size(LINEX,1)
        line([LINEX(iL,1) LINEX(iL,2)],...
             [min(o.YData) max(o.YData)], ...
               'Color','k',...
               'LineStyle','-.',...
               'LineWidth',2);
    end
           
    ylim([min(o.YData) max(o.YData)]);
    
    a = gca;
    a.YScale = 'log';
    a.YTick = [5 10 30 60 100 150 200];
    a.YTickLabel = [5 10 30 60 100 150 200];
    a.YDir = 'normal';
    c = colorbar;
    c.Label.String = 'Power (normalized)';
    caxis(CAXIS);
    
    if NEWFIG
        title('Maximum Entropy Method LFP Spectrum Average');
    end
    ylabel('Frequency (Hz)');
    xlabel('Time (min)');
end

end