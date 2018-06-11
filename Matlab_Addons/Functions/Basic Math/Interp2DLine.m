function [xx,yy] = Interp2DLine(x,y,varargin)
%% INTERP2DLINE   Get 2D interpolated data from between points on line
%
% [xx,yy] = INTERP2DLINE(x,y,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%      x        :       Original k-element vector of x-coordinates.
%
%      y        :       Original k-element vector of y-coordinates.
%
%   varargin    :       (Optional) 'NAME', value input argument pairs.
%                       -NVEC : (default: none)
%                               -> If specified, use a k-element vector to
%                                  specify the "time grid" between
%                                  interpolated elements of x and y.
%
%   --------
%    OUTPUT
%   --------
%      xx       :       Interpolated x-dimension data.
%
%      yy       :       Interpolated y-dimension data.
%
%   By: Max Murphy  v1.1    03/13/2017  Fixed bug with optional
%                                       interpolation index vector, NVEC.
%                   v1.0    03/12/2017  Original version (R2016b)

%% DEFAULTS
RESOLUTION = 1;     % Scales # points for interpolation 
                    % -> < 1 == Coarser resolution
                    % -> > 1 == Finer resolution
                    
FRAMERATE = 33;
                    
%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% LOOP THROUGH EACH SET OF POINTS AND INTERPOLATE
if abs(numel(x)-numel(y))>eps
    error('x and y must have same number of coordinates.');
else
    k = numel(x);
    x = reshape(x,1,k);
    y = reshape(y,1,k);
end


if exist('NVEC','var')==0
    xx = [];
    yy = [];
    for iK = 1:(k-1)
        n = max(abs(x(iK)-x(iK+1)),abs(y(iK)-y(iK+1))) * RESOLUTION;
        xx = [xx,linspace(x(iK),x(iK+1),n)];
        yy = [yy,linspace(y(iK),y(iK+1),n)];
    end
else
    xx = interp1(1:numel(x),x,NVEC);
    yy = interp1(1:numel(y),y,NVEC);
    if numel(xx) > FRAMERATE
        xx = fastsmooth(xx,FRAMERATE);
        yy = fastsmooth(yy,FRAMERATE);
    end
end

end