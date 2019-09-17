function [xData_out,yData_out] = lineify(xData_in,yData_in)
%% LINEIFY  Make data into format with NaN inserted for plotting vertical lines
%
%  [xData_out,yData_out] = LINEIFY(xData_in,yData_in);
%
%  --------
%   INPUTS
%  --------
%  xData_in    :     X-Data to format by making 2 copies of each entry and
%                       inserting NaN. "nSamples" long.
%
%  yData_in    :     (optional) 2 x 1 or 2 x nSamples vector of y data
%                       values corresponding to the line. If not provided,
%                       default output value corresponds to the number of
%                       lines with values [0; 1]. Top row is minima, bot
%                       row is maxima.
%
%  --------
%   OUTPUT
%  --------
%  xData_out   :     [xData_in(1) xData_in(1) NaN xData_in(2) ...]
%
%  yData_out   :     [0 1 NaN 0 ...]
%
% By: Max Murphy  v1.0  2019-05-06  Original version (R2017a)

%% PARSE INPUT
nSamples = numel(xData_in);
xData_in = reshape(xData_in,1,nSamples);
if nargin < 2
   yData_in = [zeros(1,nSamples); ones(1,nSamples)];
   
elseif (size(yData_in,2) < nSamples) && (numel(yData_in)==2)
   yData_in = [ones(1,nSamples)*yData_in(1);...
      ones(1,nSamples)*yData_in(2)];
   
elseif size(yData_in,2) ~= (nSamples)
   error(['yData_in (%g x %g) must have the same number of columns'...
      ' as number elements in xData_in (%g).'],...
      size(yData_in,1),size(yData_in,2),numel(xData_in));
end

%% 
xData_out = reshape([xData_in; xData_in; nan(1,nSamples)],1,nSamples*3);
yData_out = reshape([yData_in; nan(1,nSamples)],1,nSamples*3);


end