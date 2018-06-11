classdef VideoScroller < handle
%% VIDEOSCROLLER  Class to play test videos

   properties (Access = 'public')
      Figure
      Frame
      Video
      Position
      StepForward
      StepBackward
      Timer
      Period
      Play
      Stop
      Info
   end
   
   methods (Access = 'public')
      function obj = VideoScroller(filename)
         %% LOAD VIDEO
         obj.Video.File = VideoReader(filename);         
         
         [~,fname,~] = fileparts(filename);
         str = sprintf('%s -- %3.3g FPS -- %d x %d pixels -- %s', ...
            fname,obj.Video.File.FrameRate,...
            obj.Video.File.Width, ...
            obj.Video.File.Height,...
            obj.Video.File.VideoFormat);
         
         
         %% MAKE DISPLAY FIGURE
         obj.Figure = figure('Name','Video Test Display',...
            'Units','Normalized',...
            'Color','k',...
            'Position',[0.2 0.2 0.6 0.6]);
         
         obj.Frame.CurNum = 1;
         obj.Frame.Min = 1;
         obj.Frame.Max = obj.Video.File.NumberOfFrames;
         
         obj.Timer = timer('TimerFcn',@obj.TimerUpdate,...
                           'ExecutionMode','fixedRate');
         
         obj.Period = round(1000/obj.Video.File.FrameRate)/1000;
%          obj.Period = round(1000/30)/1000;
                        
         controlpanel = uipanel(obj.Figure,'Units','Normalized',...
            'BackgroundColor','w',...
            'ForegroundColor','k',...
            'Position',[0 0 1 0.2]);
         
         obj.StepForward = uicontrol('Parent',controlpanel,...
            'Style','Pushbutton',...
            'ForegroundColor','k',...
            'BackgroundColor','w',...
            'FontName','Arial',...
            'FontSize',16,...
            'String','->',...
            'Units','Normalized',...
            'Position',[0.9 0 0.1 0.5],...
            'Callback',@obj.ForwardButtonPush);
         
         obj.StepBackward = uicontrol('Parent',controlpanel,...
            'Style','Pushbutton',...
            'ForegroundColor','k',...
            'BackgroundColor','w',...
            'FontName','Arial',...
            'FontSize',16,...
            'String','<-',...
            'Units','Normalized',...
            'Position',[0 0 0.1 0.5],...
            'Callback',@obj.BackwardButtonPush);
         
         obj.Position = uicontrol('Parent',controlpanel,...
            'Style','slider',...
            'Units','Normalized',...
            'BackgroundColor','k',...
            'ForegroundColor','w',...
            'Value',1,...
            'Min',obj.Frame.Min,...
            'Max',obj.Frame.Max,...
            'Position',[0.1 0 0.8 1], ...
            'Callback',@obj.SetFrame);
         
         obj.Play = uicontrol('Parent',controlpanel,...
            'Style','Pushbutton',...
            'ForegroundColor','k',...
            'BackgroundColor','g',...
            'FontName','Arial',...
            'FontSize',16,...
            'String','play',...
            'Enable','on',...
            'Units','Normalized',...
            'Position',[0 0.5 0.1 0.5],...
            'Callback',@obj.PlayButtonPush);
         
         obj.Stop = uicontrol('Parent',controlpanel,...
            'Style','Pushbutton',...
            'ForegroundColor','k',...
            'BackgroundColor','r',...
            'FontName','Arial',...
            'FontSize',16,...
            'String','stop',...
            'Enable','off',...
            'Units','Normalized',...
            'Position',[0.9 0.5 0.1 0.5],...
            'Callback',@obj.StopButtonPush);
         
         obj.Info = uipanel(obj.Figure,'Units','Normalized',...
            'BackgroundColor','w','ForegroundColor','k',...
            'FontName','Arial',...
            'FontSize',18,...
            'Position',[0 0.21 1 0.76],...
            'Title',str);
         
         obj.Video.Disp = axes('Parent',obj.Info,...
            'Units','Normalized',...
            'Position',[0 0 1 1]);
         
         obj.Video.File = VideoReader(filename);
         obj.UpdateVideoPosition;
         
      end

      function PlayButtonPush(obj,src,~)
         set(obj.Stop,'Enable','on');
         src.Enable = 'off';
         start(obj.Timer);
      end
      
      function StopButtonPush(obj,src,~)
         set(obj.Play,'Enable','on')
         src.Enable = 'off';
         stop(obj.Timer);
      end
      
      function UpdateVideoPosition(obj)
         obj.Video.Image = readFrame(obj.Video.File);
         set(obj.Video.Disp.Children(1),'CData',obj.Video.Image);
      end
      
      function ForwardButtonPush(obj,~,~)
         obj.Position.Value = min(obj.Position.Value+1,obj.Frame.Max);
         obj.SetFrame(obj.Position,nan);
      end
      
      function BackwardButtonPush(obj,~,~)
         obj.Position.Value = max(obj.Position.Value-1,obj.Frame.Min);
         obj.SetFrame(obj.Position,nan);
      end
      
      function TimerUpdate(obj,~,~)
         %executed at each timer period, when playing the video
        if round(obj.Frame.CurNum) < obj.Frame.Max % if we are not at the end, advance on frame
            obj.Position.Value=min(obj.Position.Value+1,obj.Frame.Max);
            obj.SetFrame(obj.Position,nan);
        elseif strcmp(get(obj.Timer,'Running'), 'on')
            stop(obj.Timer);  %stop the timer if the end is reached
            set(obj.Play,'Enable','on'); %reset push button
            set(obj.Stop,'Enable','off');
        end
      end
      
      function SetFrame(obj,src,~)
         
         obj.Frame.CurNum = src.Value; % read the slider value
         obj.Video.File.CurrentTime = obj.Frame.CurNum ...
            / obj.Video.File.FrameRate;
         
         obj.UpdateVideoPosition;

    end
   end

end