function insertPSTH(t,y,ii,varargin)
%% INSERTPSTH   Insert PSTH with significance estimates to current axes
%
%   INSERTPSTH(t,y,ii,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%      t        :       Vector of histogram bin centers (from AA_PSTH).
%
%      y        :       Table from AA_PSTH output. Each row is an
%                       identified single or multi-unit cluster.
%
%      ii       :       Index of the cluster within table y.
%
%   varargin    :       (Optional) 'NAME', value input argument pairs.
%
%   --------
%    OUTPUT
%   --------
%   Inserts PSTH to the currently selected axes in an existing figure. If
%   no figure is available, creates a new figure and inserts there instead.



%% DEFAULTS
CB = 0.95;      % Confidence bounds about the mean (assumes symmetry)
XLAB = '';                  % X label text
YLAB = '';                  % Y label text
TITLE = '';                 % Title text
XLIM = [0 28];              % X limits of axes
YLIM = [0 1];               % Y limits of axes
BLANKING = 6;               % Blanking imposed by stimulus artifact
COL = 'm';                  % Blanking face color
F_ID = '*_PSTHdata.mat';    % PSTH file identifier
DEF_DIR = 'P:\Rat';         % Default directory to look for PSTH file

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% CHECK INPUT, IF EMPTY LET USER LOAD
if (isempty(t) || isempty(y))
    [fname,pname,~]=uigetfile('*_PSTHdata.mat','Select PSTHdata file', ...
                              DEF_DIR);
                          
    load(fullfile(pname,fname));
    if (isempty(t) || isempty(y))
        error('Invalid file.');
    end
end

%% ESTIMATE CONFIDENCE BOUNDS
NR = size(y.rcounts{ii},1);
ind_UB = round((CB + 0.5 * (1-CB)) * NR);
ind_LB = round(((1-CB) - 0.5 * (1-CB)) * NR);

if (ind_UB > NR || ind_LB < 1)
    error(['Confidence bounds too wide given ' ...
           'rounding error and amount of resampling.']);
end

resamp = y.rcounts{ii};
for iR = 1:size(resamp,2)
    resamp(:,iR) = sort(resamp(:,iR),'ascend');
end
resamp_UB = resamp(ind_UB,:)/numel(y.stimts{ii});
resamp_LB = resamp(ind_LB,:)/numel(y.stimts{ii});

%% INSERT PSTH
bar(t,y.scounts{ii}/numel(y.stimts{ii}),1, ...
    'EdgeColor','none','FaceColor','k'); 
hold on; 
plot(t,resamp_UB,'MarkerEdgeColor','r', ...
                'Marker','sq', ...
                'LineStyle','none', ...
                'MarkerSize',3.5, ...
                'MarkerFaceColor','r');
plot(t,resamp_LB,'MarkerEdgeColor','b', ...
                'Marker','sq', ...
                'LineStyle','none', ...
                'MarkerSize',3.5, ...
                'MarkerFaceColor','b');
fill([min(XLIM), min(XLIM), BLANKING, BLANKING], ...
     [min(YLIM), max(YLIM), max(YLIM), min(YLIM)], ...
     COL);
hold off;
xlim(XLIM); ylim(YLIM);
title(TITLE); ylabel(YLAB); xlabel(XLAB);

                                
end