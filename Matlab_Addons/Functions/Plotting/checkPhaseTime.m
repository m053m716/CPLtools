function checkPhaseTime(varargin)
%% CHECKPHASETIME   Check duration of each period from splitting.
%
%   CHECKPHASETIME('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%
%   -> 'DIR'    :   def none \\ If specified automatically loops through
%                               all "block" folders within a given
%                               directory. 
%
%   --------
%    OUTPUT
%   --------
%   Plots the phase times on subplot graph to make sure that there is
%   consistency in how the phases are defined.
%
% By: Max Murphy    v1.0    08/01/2017  Original version (R2017a)

%% DEFAULTS
DEF_DIR = 'P:\Rat\ITLProject';
BLOCK_ID = 'R*Day*';
PHASE_ID = '_PhaseTime.mat';
FIG_ID = '_PhaseDurations';
YLIM = [0 100];

%% PARSE VARARGIn
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% CHECK DIRECTORY
if exist('DIR','var')==0
    DIR = uigetdir(DEF_DIR,'Select animal TANK');
    if DIR == 0
        error('No selection.');
    end
end

F = dir(fullfile(DIR,BLOCK_ID));

%% LOOP AND PLOT
figure('Name','Phase Durations', ...
       'Units','Normalized', ...
       'Color','w', ...
       'Position', [0.2 0.2 0.6 0.6]);

nRow = ceil(sqrt(numel(F)));
nCol = nRow;

for iF = 1:numel(F)
    load(fullfile(F(iF).folder,F(iF).name,[F(iF).name PHASE_ID]), ...
         'EPOCH_LABEL','phaseTime');
    
    N = size(EPOCH_LABEL,1);
     
    % Plot
    subplot(nRow,nCol,iF);
    stem(1:N,phaseTime);
    ylim(YLIM);
    xlim([0.5 N+0.5]);
    for iN = 1:N
        EPOCH_LABEL{iN} = strrep(EPOCH_LABEL{iN},'_',' ');
    end
    set(gca,'XTickLabel',EPOCH_LABEL);
    set(gca,'XTickLabelRotation',45);
    pname = strsplit(F(iF).name,'_');
    pname = pname{end};
    title(pname);
end
name = strsplit(DIR,filesep);
name = name{end};
suptitle(name);

%% SAVE FIGURE
savefig(gcf,fullfile(DIR,[name FIG_ID '.fig']));
saveas(gcf,fullfile(DIR,[name FIG_ID '.jpeg']));

end