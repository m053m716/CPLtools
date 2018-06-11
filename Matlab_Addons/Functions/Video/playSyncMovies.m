function playSyncMovies(V,varargin)
%% PLAYSYNCMOVIES Plays synchronized movies simultaneously
%
%  PLAYSYNCMOVIES(V,'NAME',value,...)
%
%  --------
%   INPUTS
%  --------
%     V     :     3 x 1 cell of VideoReader objects with synchronized
%                 movies.
%
%  --------
%   OUTPUT
%  --------


%% DEFAULTS
FRAME = 1;
VID_FIG_POSITION = [0.33 0.05 0.33 0.9];
DEF_DIR = 'K:\Rat\Video\Reach Kinematics\Dev\2017-09-12_SyncBac-Test';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if nargin == 0
   [FileName,PathName,~] = uigetfile('*_GP1.*','Select movie',DEF_DIR);
   if FileName == 0
      error('No movie file selected. Script aborted.');
   end
   
   V = cell(3,1);
   for ii = 1:3
      fname = strrep(FileName,'_GP1.',sprintf('_GP%d.',ii));
      V{ii,1} = VideoReader(fullfile(PathName,fname)); %#ok<TNMLP>
   end
end


%% PLAY MOVIES
vidPlayFig = figure('Units','Normalized',...
   'NumberTitle','off',...
   'MenuBar','none',...
   'ToolBar','none',...
   'Position',VID_FIG_POSITION);

s = cell(3,1);
for ii = 1:3
   V{ii}.CurrentTime = 0;
   s{ii} = struct('cdata',zeros(V{ii}.Height,...
                                V{ii}.Width,3,'uint8'),...
                        'colormap',[]);
   k = 1;
   while hasFrame(V{ii})
       s{ii}(k).cdata = readFrame(V{ii});
       k = k+1;
   end
end



ax = cell(3,1);
for ii = 1:3
   ax{ii} = axes(gcf,'Units','Normalized',...
      'Position',[0 0.33 * (ii-1) 1 0.33]);
   imshow(s{ii}(FRAME).cdata,'Parent',ax{ii});
end

f = figure('Units','Normalized',...
   'Position',[0.7 0.7 0.2 0.2],...
   'Name','Video Controller',...
   'ToolBar','none',...
   'NumberTitle','off',...
   'MenuBar','none',...
   'Color','k');
f.UserData{1} = s;
f.UserData{2} = ax;


uicontrol(f,'Style','Pushbutton',...
            'FontName','Arial',...
            'FontSize',16,...
            'BackgroundColor','g',...
            'ForegroundColor','k',...
            'String','Next',...
            'Units','Normalized',...
            'Position',[0 0.7 1 0.25],...
            'Callback',@NextFrame);
         
uicontrol(f,'Style','Pushbutton',...
            'FontName','Arial',...
            'FontSize',16,...
            'BackgroundColor','r',...
            'ForegroundColor','k',...
            'String','Back',...
            'Units','Normalized',...
            'Position',[0 0.4 1 0.25],...
            'Callback',@BackFrame);
         
tb = uicontrol(f,'Style','Edit',...
            'FontName','Arial',...
            'FontSize',16,...
            'BackgroundColor','w',...
            'ForegroundColor','k',...
            'String',sprintf('%d',FRAME),...
            'Units','Normalized',...
            'Position',[0.35 0.1 0.5 0.25],...
            'Callback',@ChangeFrame);
         
uicontrol(f,'Style','text',...
   'FontName','Arial',...
   'FontSize',16,...
   'BackgroundColor','k',...
   'ForegroundColor','w',...
   'String','Frame:',...
   'Units','Normalized',...
   'Position',[0.175 0.15 0.15 0.125]);

   function NextFrame(~,~)
      if FRAME < numel(s{1})
         FRAME = FRAME + 1;
      end
      for n = 1:3
         imshow(s{n}(FRAME).cdata,'Parent',f.UserData{2}{n});
      end
      set(tb,'String',sprintf('%d',FRAME));
   end

   function BackFrame(~,~)
      if FRAME > 1
         FRAME = FRAME - 1;
      end
      for n = 1:3
         imshow(s{n}(FRAME).cdata,'Parent',f.UserData{2}{n});
      end
      set(tb,'String',sprintf('%d',FRAME));
   end

   function ChangeFrame(src,~)
      FRAME = round(str2double(src.String));
      if FRAME < 1
         FRAME = 1;
      elseif FRAME > numel(s{1})
         FRAME = numel(s{1});
      end
      for n = 1:3
         imshow(s{n}(FRAME).cdata,'Parent',f.UserData{2}{n});
      end
   end

end