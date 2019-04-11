function fig = screenFeatures(Z)
%% SCREENFEATURES    Screen pairs of features to check for separation
%
%  fig = SCREENFEATURES(Z)
%
%  --------
%   INPUTS
%  --------
%     Z     :     N observations x K features matrix.
%
%  --------
%   OUTPUT
%  --------
%    fig    :     Figure with K * (K - 1) / 2 subplots of pairwise feature
%                    scatter plots.
%
%
% By: Max Murphy  v1.0  12/07/2018  Original version (R2017b)

%% PARSE INPUT
N = size(Z,1);
K = size(Z,2);

if K > N
   warning('More feats (%d) than obs (%d). Transposing input matrix.',...
      K,N);
   Z = Z.';
   K = N;
   N = size(Z,1);
end

%% MAKE FIGURE AND PLOT
addpath('APP_CODE');
fig = figure('Name','Feature Comparisons',...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.2 0.2 0.6 0.6]);

if isEven(K)
   nRow = (K - 1);
   nCol = K / 2;
else
   nRow = K;
   nCol = (K - 1) / 2;
end
nTotal = K*(K-1)/2;
iCount = 0;
for ii = 1:K
   for ik = (ii+1):K
      iCount = iCount + 1;
      h = subplot(nRow,nCol,iCount);
      test_2Dbimodal(Z(:,[ii,ik]),h);
      title(sprintf('%0.2d vs %0.2d',ii,ik),'FontName','Arial','Color','k');
   end
end

end
