function [Zica, W, T, mu] = fastICA(Z,r,varargin)
%% FASTICA  Use Fast ICA algorithm to do independent components analysis
%
% Syntax:       Zica = fastICA(Z,r);
%               Zica = fastICA(Z,r,TYPE);
%               Zica = fastICA(__,'NAME',value,...);
%               [Zica, W, T, mu] = fastICA(Z,r);
%               
% Inputs:       Z is an d x n matrix containing n samples of d-dimensional
%               data
%               
%               r is the number of independent components to compute
%               
%               [OPTIONAL] == 'NAME', value pairs.
%
%               [OPTIONAL] 'TYPE' = {'kurtosis','negentropy'} specifies
%               which flavor of non-Gaussianity to maximize. The default
%               value is TYPE = 'kurtosis'
%               
%               [OPTIONAL] 'FLAG' determines what status updates to print
%               to the command window. The choices are
%                   
%                       FLAG = 0: no printing
%                       FLAG = 1: print iteration status
%               
% Outputs:      Zica is an r x n matrix containing the r independent
%               components - scaled to variance 1 - of the input samples
%               
%               W and T are the ICA transformation matrices such that
%               Zr = T \ W' * Zica + repmat(mu,1,n);
%               is the r-dimensional ICA approximation of Z
%               
%               mu is the d x 1 sample mean of Z
%               
% Description:  Performs independent component analysis (ICA) on the input
%               data using the Fast ICA algorithm
%               
% Reference:    Hyvärinen, Aapo, and Erkki Oja. "Independent component
%               analysis: algorithms and applications." Neural networks
%               13.4 (2000): 411-430
%               
% Author:       Brian Moore
%               brimoor@umich.edu
%               
% Date:         April 26, 2015
%               November 12, 2016
%

%% DEFAULTS
MIN_LEARNING_RATE = 1e-10; % Minimum change in delta
MIN_TOL = 1e-6;      % Minimum criteria for convergence
TOL = 1e-9;          % Convergence criteria
MAX_ITERS = 250;     % Max # iterations
FLAG = 1;            % 1 = show text, 0 = no info in commandline
TYPE = 'kurtosis';   % Metric to be minimized for ICA
WHITEN = true;       % Center data (0 mean)
CENTER = true;       % Whiten data (remove correlations)
TOTAL_ITERS = 20000; % Total possible iterations


%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end
TYPE = lower(TYPE);

%% CENTER AND WHITEN DATA
if CENTER
   [Zc, mu] = centerRows(Z);
else
   Zc = Z;
   mu = mean(Z,2);
end
   
if WHITEN
   [Zcw, T] = whitenRows(Zc);
else
   Zcw = Zc;
   T = nan;
end

%% NORMALIZE ROWS TO UNIT NORM
normRows = @(X) bsxfun(@rdivide,X,sqrt(sum(X.^2,2)));

%% PERFORM FAST ICA ALGORITHM
if FLAG
    % Prepare status updates
    fmt = sprintf('%%0%dd',ceil(log10(MAX_ITERS + 1)));
    str = sprintf('Iter %s: max(1 - |<w%s, w%s>|) = %%.4g\\n',fmt,fmt,fmt);
    fprintf('***** Fast ICA (%s) *****\n',TYPE);
end
W = normRows(rand(r,size(Z,1))); % Random initial weights
k = 0;
delta = inf;
learning = inf;
iter = MAX_ITERS;
while delta > MIN_TOL && learning > MIN_LEARNING_RATE
   while delta > TOL && k < iter
       k = k + 1;

       % Update weights
       deltalast = delta; % Save last delta
       Wlast = W; % Save last weights
       Sk = permute(W * Zcw,[1, 3, 2]);
       switch TYPE
         case 'kurtosis'
            G = 4 * Sk.^3;
            Gp = 12 * Sk.^2;
         case 'negentropy'
            G = Sk .* exp(-0.5 * Sk.^2);
            Gp = (1 - Sk.^2) .* exp(-0.5 * Sk.^2);
          otherwise
             error('Unsupported TYPE: %s', TYPE);
       end
       W = mean(bsxfun(@times,G,permute(Zcw,[3, 1, 2])),3) - ...
                bsxfun(@times,mean(Gp,3),W);
       W = normRows(W);

       % Decorrelate weights
       [U, S, ~] = svd(W,'econ');
       W = U * diag(1 ./ diag(S)) * U' * W;

       % Update convergence criteria
       delta = max(1 - abs(dot(W,Wlast,2)));
       if FLAG
           fprintf(str,k,k,k - 1,delta);
       end
       learning = abs(deltalast - delta);
   end
   iter = iter + MAX_ITERS;
   if iter > TOTAL_ITERS
      break;
   end
end
if FLAG
    fprintf('\n');
end

%% RETURN INDEPENDENT COMPONENTS
Zica = W * Zcw;
end