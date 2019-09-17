function lineCallback(src,~,varargin)
%% LINECALLBACK     Add to 'ButtonDownFcn' property of lines to highlight
%
%   LINECALLBACK(src,~,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%     src       :       Matlab graphical line object. When specifying a
%                       'ButtonDownFcn', if passed anonymously (i.e.
%                       @lineCallback), this will be included automatically
%                       as the first argument.
%
%   varargin    :       (Optional) 'NAME', value input argument pairs. When
%                       specifying 'ButtonDownFcn', you must pass this in a
%                       cell array:
%                       {@lineCallback,'NAME1',value1,'NAME2',value2,...}
%
%                       => 'SEL_COL': (def [0.4 0.4 0.8]; Highlight color
%                                      for line when it is clicked)
%
%                       => 'UNSEL_COL': (def [0.94 0.94 0.94]; Unselect
%                                        color for lines that have not been
%                                        clicked)
%
%                       => 'BRING_FORWARD': (def false; Set to true to
%                                            bring line to front, but must
%                                            configure other axes
%                                            properties to use with it)
%
%   --------
%    OUTPUT
%   --------
%   Setting the ButtonDownFcn property of a line object to this function
%   will allow you to change the color of the line by clicking on it.
%
%   By: Max Murphy  v1.0    05/04/2017  Original version (R2017a)
% See also: PLOT, LINE

%% DEFAULTS
SEL_COL = [0.4 0.4 0.8];
UNSEL_COL = [0.94 0.94 0.94];
BRING_FORWARD = true;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% SWITCH COLORS
if ~any(src.Color - SEL_COL)
   src.Color = UNSEL_COL;
   src.LineWidth = 1;
else
   src.Color = SEL_COL;
   src.LineWidth = 2;
end

%% (OPTIONAL) BRING LINE TO FRONT
if BRING_FORWARD
   p = src.Parent;
   if ~isempty(p.UserData)
      n = numel(p.Children);
      nU = numel(p.UserData);
      ext = (nU+1):(nU+(n - nU));
      
      ind = find(p.UserData==src.UserData,1,'first');
      
      vec = setdiff(p.UserData,ind);
      p.Children = p.Children([ind,vec,ext]);
      p.UserData = p.UserData([ind,vec]);
   end
end

end