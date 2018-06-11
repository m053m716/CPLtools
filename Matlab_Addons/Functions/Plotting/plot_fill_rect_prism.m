function [X,Y,Z] = plot_fill_rect_prism(xmin,xmax,ymin,ymax,zmin,zmax)
%% PLOT_FILL_RECT_PRISM    Returns inputs for fill3 for rectangular prism
%
%  [X,Y,Z] = PLOT_FILL_RECT_PRISM(xmin,xmax,ymin,ymax,zmin,zmax)
%
% By: Max Murphy  v1.0  11/08/2017  Original version (R2017a)

%% SPECIFY ALL VERTICES NECESSARY TO FILL RECTANGULAR PRISM

%                    FACE
%     1      2      3      4      5      6
X = [xmin , xmin , xmin , xmin , xmin , xmax ; ... % 1
     xmin , xmin , xmax , xmax , xmin , xmax ; ... % 2   EDGE
     xmax , xmax , xmax , xmax , xmin , xmax ; ... % 3
     xmax , xmax , xmin , xmin , xmin , xmax ];    % 4
  
%                    FACE
%     1      2      3      4      5      6
Y = [ymin , ymax , ymin , ymin , ymin , ymin ; ... % 1
     ymin , ymax , ymin , ymin , ymax , ymax ; ... % 2   EDGE
     ymin , ymax , ymax , ymax , ymax , ymax ; ... % 3
     ymin , ymax , ymax , ymax , ymin , ymin ];    % 4
  
%                    FACE
%     1      2      3      4      5      6
Z = [zmin , zmin , zmin , zmax , zmin , zmin ; ... % 1
     zmax , zmax , zmin , zmax , zmin , zmin ; ... % 2   EDGE
     zmax , zmax , zmin , zmax , zmax , zmax ; ... % 3
     zmin , zmin , zmin , zmax , zmax , zmax ];    % 4
                                         
                                         
end