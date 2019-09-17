function showHideMetadata(src,~)
%% SHOWHIDEMETADATA  Show or hide metadata associated with a scatter point
%
%  SHOWHIDEMETADATA(src,~)
%
%  --------
%   INPUTS
%  --------
%     src      :     Object for which this function is set as
%                       'ButtonDownFcn' property. example:
%                       scatter3(x,y,z,'ButtonDownFcn',@showHideMetadata):
%
% By: Max Murphy  v1.0  2019-06-21  Original version (R2017a)

srcProps = src.UserData;
if srcProps.isHighlighted
   clc;
   src.MarkerFaceColor = 'k';
   src.MarkerEdgeColor = 'none';
   src.SizeData = 20;
else
   src.MarkerFaceColor = 'b';
   src.MarkerEdgeColor = 'c';
   src.SizeData = 72;
   disp(srcProps.metadata);
end
src.UserData.isHighlighted = ~srcProps.isHighlighted;
end