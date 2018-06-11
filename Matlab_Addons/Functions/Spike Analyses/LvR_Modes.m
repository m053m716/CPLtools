function P = LvR_Modes(D,varargin)
%% LVR_MODES Get LvR values and plot bimodal distribution
%
%   paramEsts = LVR_MODES(D,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%      D        :       Table from SIMPLE_SPIKE_ANALYSIS
%
%   varargin    :       (Optional) 'NAME', value pairs, from DEFAULTS.
%
%   --------
%    OUTPUT
%   --------
%      P        :       Struct containing following fields-
%                       -> pdf   :  Function used for PDF estimate.
%                       -> pars  :  Parameter estimates.

%% DEFAULTS
HMIN = 0.8;     % Minimum histogram bin
HMAX = 1.4;     % Maximum histogram bin
NBINS = 25;     % Number of histogram bins

MUSTART = [0.25 0.75];  % Starting guess for means
PSTART = 0.5;           % Starting guess for 1st component proportion

MAXITER = 300;      % Number of function iterations per evaluation in MLE
MAXEVAL = 600;      % Number of function evaluations in MLE

BARCOL = [0 0 0];   % Histogram bar color
NLINEPTS = 1000;    % Number of line points for smooth curve
%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% EQUATION FOR BIMODAL NORMAL DISTRIBUTION MIXTURE
pdf_normmixture = @(x,p,mu1,mu2,sigma1,sigma2) ...
p*normpdf(x,mu1,sigma1) + (1-p)*normpdf(x,mu2,sigma2);

%% SET UP 
x = D.Regularity;
pStart = PSTART;
muStart = quantile(x,MUSTART);
sigmaStart = sqrt(var(x) - .25*diff(muStart).^2);
start = [pStart muStart sigmaStart sigmaStart];
lb = [0 -Inf -Inf 0 0];
ub = [1 Inf Inf Inf Inf];
options = statset('MaxIter',MAXITER, 'MaxFunEvals',MAXEVAL);

%% GET ESTIMATES
paramEsts = mle(x, 'pdf',pdf_normmixture, 'start',start, ...
'lower',lb, 'upper',ub, 'options',options);
clc;
fprintf(1,'\nComponent proportions: 1) %d \t\t 2) %d',paramEsts(1),...
                                                    1-paramEsts(1));
fprintf(1,['\n\n\t\t\t\t\t\tmu1 = %d\t\tsigma1 = %d\n\n' ...
               '\t\t\t\t\t\tmu2 = %d\t\tsigma2 = %d\n'],...
    paramEsts(2),paramEsts(4),paramEsts(3),paramEsts(5));

%% GET HISTOGRAM
hvec = linspace(HMIN,HMAX,NBINS);
y = histcounts(x,hvec);

%% PLOT
figure('Name','LvR Modes', ...
       'Units','Normalized',...
       'Position',[0.2 0.2 0.4 0.4]);
bar(hvec(1:end-1)+mode(diff(hvec))/2, ...
    y/(numel(x)*mode(diff(hvec))),1,'FaceColor',BARCOL);
xgrid = linspace(min(hvec),max(hvec),NLINEPTS);
pdfgrid = pdf_normmixture(xgrid, ...
    paramEsts(1),paramEsts(2),paramEsts(3),paramEsts(4),paramEsts(5));

% Add smoothed curve and identify means
hold on;
plot(xgrid,pdfgrid,'LineStyle','-','LineWidth',3,'Color','b')
line([paramEsts(2),paramEsts(2)], ...
     [0,pdf_normmixture(paramEsts(2),paramEsts(1),paramEsts(2), ...
                                     paramEsts(3),paramEsts(4), ...
                                     paramEsts(5))], ...
     'Color','b','LineStyle','--','LineWidth',2);
line([paramEsts(3),paramEsts(3)], ...
     [0,pdf_normmixture(paramEsts(3),paramEsts(1),paramEsts(2), ...
                                     paramEsts(3),paramEsts(4), ...
                                     paramEsts(5))], ...
     'Color','r','LineStyle','--','LineWidth',2);
title('LvR - Full Session');
ylabel('Probability Density');
xlabel('LvR');
hold off;

%% OUTPUT
P = struct('pdf',pdf_normmixture,'pars',paramEsts);

end