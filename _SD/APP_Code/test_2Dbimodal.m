function s = test_2Dbimodal(X,h)
%% TEST_2DBIMODAL   Check for bimodality with respect to elements of X
%
%   p = TEST_2DBIMODAL(X)
%   p = TEST_2DBIMODAL(X,h)
%
%   --------
%    INPUTS
%   --------
%      X        :       N x 2 matrix of observations, where each row is an
%                       observation and each column is a variable.
%
%      h        :       (Optional) Figure axes handle.
%
%   --------
%    OUTPUT
%   --------
%      s        :       "Surprise" score for coming from a uni-modal
%                       distribution. Higher values indicate greater
%                       surprise that the observed data in X come from a
%                       single distribution, based on the assumption of a
%                       bivariate normal distribution.
%
% By: Max Murphy    v1.0    08/07/2017  Original version (R2017a)
%   See also: WHITENROWS

%% DEFAULTS
if nargin < 2
   doPlot = false;
else
   doPlot = true;
end

%% WHITEN DATA
X = whitenRows(X.').';

%% PLOT DATA
if doPlot
    scatter(h,X(:,1),X(:,2),5,'filled',...
        'MarkerFaceColor',[0.3 0.3 0.6],...
        'MarkerEdgeColor','none');
end

s = nan;

end