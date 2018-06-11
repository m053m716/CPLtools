function expAI(fig,filename,varargin)
%% EXPAI export figure in appropriate format for Adobe Illustrator
%
%   EXPAI(filename);
%
%   --------
%    INPUTS
%   --------
%      fig      :   Handle to the figure you wish to export.
%   
%   filename    :   String with output filename (and extension) of figure 
%                   to export for Adobe Illustrator.
%
%   varargin    :   Optional 'NAME', value input argument pairs.
%
%   --------
%    OUTPUT
%   --------
%   A second file with the same name for use with Adobe Illustrator.
%
% By: Max Murphy    v1.1    01/03/2017  Modified to not include the
%                                       FORMATOPT -cmyk. This improves
%                                       export of heatmaps to AI.
%                   v1.0    12/09/2016  Original Version

%% DEFAULT PARAMETERS
%Note: default configuration should work well for AI export as is.

%Boolean options
FORMATFONT  = true;                 %Automatically reconfigure axes fonts
% OPENFIG     = true;                 %Automatically open new fig in AI

%Figure property modifiers
FONTNAME = 'Arial';                 %Set font name (if FORMATFONT true)
FONTSIZE = 16;                      %Set font size (if FORMATFONT true)

%Print function modifiers
FORMATTYPE  = '-dpsc2';             % Vector output format
% FORMATTYPE = '-dpdf';               % Full-page PDF
% FORMATTYPE = '-dsvg';               % Scaleable vector graphics format
% FORMATTYPE = '-dpsc';               % Level 3 full-page PostScript, color
% FORMATTYPE = '-dmeta';              % Enhanced Metafile (WINDOWS ONLY)
% FORMATTYPE = '-depsc';              % EPS Level 3 Color
% FORMATTYPE = '-dtiffn';             % TIFF 24-bit (not compressed)
UIOPT       = '-noui';              % Excludes UI controls
% FORMATOPT   = '-cmyk';              % Format options for color
% FORMATOPT   = '-loose';             % Use loose bounding box
RENDERER    = '-painters';          % Graphics renderer
% RESIZE      = '-fillpage';          % Alters aspect ratio
% RESIZE      = '-bestfit';           % Choose best fit to page
RESOLUTION  = '-r600';              % Specify dots per inch (resolution)


%% PARSE VARARGIN
for iV = 1:2:length(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET CORRECT OUTPUT FILE EXTENSION
if strcmp(FORMATTYPE, '-dtiffn')
    ext = '.tif';
elseif strcmp(FORMATTYPE, '-dpsc2')
    ext = '.ps';
elseif strcmp(FORMATTYPE, '-dsvg')
    ext = '.svg';
elseif strcmp(FORMATTYPE, '-dpdf')
    ext = '.pdf';
else
    ext = '.ai';
end

% temp = strsplit(filename, '.');
% if numel(temp) > 1
%     filename = [temp{1} '.' ext];
% else
%     filename = [filename '.' ext];
% end
% clear temp

%% MODIFY FIGURE PARAMETERS
set(gcf, 'Renderer', RENDERER(2:end));
if FORMATFONT
    c = get(gcf, 'Children');
    for iC = 1:length(c)
        set(c(iC),'FontName',FONTNAME);
        set(c(iC),'FontSize',FONTSIZE);
    end
end

%% OUTPUT CONVERTED FIGURE
print(fig,          ...
...      RESIZE,       ...
      RESOLUTION,   ...
      FORMATTYPE,   ...
      UIOPT,        ...
...      FORMATOPT,    ...
      RENDERER,     ...
      filename);
  
%% OPEN FIGURE IN ADOBE ILLUSTRATOR FOR CONVENIENCE
% if OPENFIG
%     eval(['!' filename]);
% end

end