function P = test_bimodal(data,varargin)
%% TEST_BIMODAL Get distribution values and plot bimodal distribution
%
%   P = test_bimodal(data,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%     data      :       Vector of data values.
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
DATA_NAME = '';
DATA_TITLE = '';

% HMIN = 0.8;     % Minimum histogram bin
% HMAX = 1.4;     % Maximum histogram bin
NBINS = 25;     % Number of histogram bins

MUSTART = [0.25 0.75];  % Starting guess for means
PSTART = 0.6;           % Starting guess for 1st component proportion

MAXITER = 1000;      % Number of function iterations per evaluation in MLE
MAXEVAL = 3000;      % Number of function evaluations in MLE

BARCOL = [0 0 0];   % Histogram bar color
NLINEPTS = 1000;    % Number of line points for smooth curve

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if exist('HMIN','var')==0
    HMIN = min(data) * 1.1;
end

if exist('HMAX','var')==0
    HMAX = max(data) * 1.1;
end

%% EQUATION FOR BIMODAL NORMAL DISTRIBUTION MIXTURE
pdf_normmixture = @(x,p,mu1,mu2,sigma1,sigma2) ...
p*normpdf(x,mu1,sigma1) + (1-p)*normpdf(x,mu2,sigma2);

%% SET UP 
pStart = PSTART;
muStart = quantile(data,MUSTART);
sigmaStart = sqrt(abs(var(data) - .1*diff(muStart).^2));
start = [pStart muStart sigmaStart sigmaStart];
lb = [0 -Inf -Inf 0 0];
ub = [1 Inf Inf Inf Inf];
options = statset('MaxIter',MAXITER, 'MaxFunEvals',MAXEVAL);

%% GET ESTIMATES
paramEsts = mle(data, 'pdf',pdf_normmixture, 'start',start, ...
'lower',lb, 'upper',ub, 'options',options);


fprintf(1,'\nComponent proportions: 1) %d \t\t 2) %d',paramEsts(1),...
                                                    1-paramEsts(1));
fprintf(1,['\n\n\t\t\t\t\t\tmu1 = %d\t\tsigma1 = %d\n\n' ...
               '\t\t\t\t\t\tmu2 = %d\t\tsigma2 = %d\n'],...
    paramEsts(2),paramEsts(4),paramEsts(3),paramEsts(5));

%% GET HISTOGRAM
hvec = linspace(HMIN,HMAX,NBINS+1);
y = histcounts(data,hvec);

%% PLOT
figure('Name',[DATA_NAME ' Normal Mixture MLE Fit'], ...
       'Units','Normalized',...
       'Position',[0.2 0.2 0.4 0.4]);
bar(hvec(1:end-1)+mode(diff(hvec))/2, ...
    y/(numel(data)*mode(diff(hvec))),1,'FaceColor',BARCOL);

% xlims = quantile(data,[0.025 0.975]);
xlims = [min(data)*0.95 max(data)*1.05];
xgrid = linspace(xlims(1),xlims(2),NLINEPTS);
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
title(DATA_TITLE);
ylabel('Probability Density');
xlabel(DATA_NAME);
xlim([xlims(1) xlims(2)]);
hold off;

%% OUTPUT
P = struct('pdf',pdf_normmixture,'pars',paramEsts);

end