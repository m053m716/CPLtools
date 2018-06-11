classdef CPL_Audio < handle
%% CPL_AUDIO   Object for audio data associated with video record.
%
%  obj = CPL_AUDIO;
%  obj = CPL_AUDIO(file_in);
%
%  Example usage:
%  --------------
%  obj = CPL_AUDIO('test.mp3')
%  This would import the file 'test.mp3' from the default location
%  specified by the path property. The name property would be
%  updated to 'test.mp3'.
%
%  obj.path = 'my/dir';
%  If 'test.mp3' is located at 'my/dir', this would update the
%  path string and update the audio associated with the CPL_AUDIO
%  object if 'my/dir/test.mp3' is different from
%  'def/dir/test.mp3'.
%  
%  obj = CPL_AUDIO('my/dir/here/test.mp3')
%  Would update the path property.
%
%  CPL_AUDIO Properties:
%     in       - Audio record currently in object.
%     name     - Name of audio file.
%     path     - Path where audio file is located.
%     epochs   - Time epochs corresonding to audio feature detection.
%
%  CPL_AUDIO Methods:
%     CPL_Audio         - Class constructor.
%     GetSpectrum       - Get frequency content of audio signal.
%     PlotSpectrum      - Plot frequency content of audio signal.
%     GetEpochs         - Get epochs based on current epoch type criteria.
%     DefineEpochType   - Set new epoch labels and definitions.

   properties (Access = 'public', SetObservable = true, AbortSet = true)
      % in - Audio record currently in object
      %
      %  -> data : N x 2 (for stereo) double matrix of audio samples.
      %  -> fs   : Sample rate (48000 for videos in RC study).
      %  -> spect : Defined using the GetSpectrum method. Frequency
      %             content of audio for the duration of the recording.
      in   % Audio-in object
      
      name % Name of audio file
      
      path % Path where audio file is located
      
      % epochs - Time epochs corresponding to audio feature detection
      %          [K x 2 double matrix of start/stop times (seconds)]
      %
      %  -> pain : Epochs where 22-24kHz power exceeds threshold, as
      %            defined from study of arthritic rats (they went up to
      %            28kHz but we can only achieve 24kHz with fs audio)
      %            (Bernard et al. NeuroReport. 1996)
      %
      %  -> artifact : User-defined epochs of sound artifact (manually set)
      %
      %  -> [other] : Set using the DefineEpochs method. Can specify epochs
      %               based on various parameters of the frequency spectrum
      %               and also time-series data.
      epochs % Time epochs corresponding to audio feature occurrences.
   end
   
   properties (Access = 'public', Hidden = true)
      VERBOSE = true;
   end
   
   properties (Access = 'private')
      DEFAULTS_FILE = 'CPL_Audio_Defaults.mat'; 
      DEF;                  % Default directory path for audio files
      DEF_F = 10:100:29910; % Cyclical frequencies for spectral estimate
      Epoch_List = {'pain';'artifact'};
   end
   
   methods (Access = 'public')
      function obj = CPL_Audio(file_in)
         %% CPL_AUDIO   Object for audio data associated with video record.
         %
         %  obj = CPL_AUDIO;
         %  obj = CPL_AUDIO(file_in);
         %
         %  Example usage:
         %  --------------
         %  obj = CPL_AUDIO('test.mp3')
         %  This would import the file 'test.mp3' from the default location
         %  specified by the path property. The name property would be
         %  updated to 'test.mp3'.
         %
         %  obj.path = 'my/dir';
         %  If 'test.mp3' is located at 'my/dir', this would update the
         %  path string and update the audio associated with the CPL_AUDIO
         %  object if 'my/dir/test.mp3' is different from
         %  'def/dir/test.mp3'.
         %  
         %  obj = CPL_AUDIO('my/dir/here/test.mp3')
         %  Would update the path property.
         
         %% INITIALIZE DEFAULT PARAMETERS
         if obj.VERBOSE
            clc;
         end
         def_file_name = fullfile(pwd,obj.DEFAULTS_FILE);
         if exist(def_file_name,'file')==0
            DEF = uigetdir(pwd,'Select default location for audio files.');
            save(def_file_name,'DEF','-v7.3');
         else
            load(def_file_name,'DEF');
         end
         obj.DEF = DEF;
         
         %% INITIALIZE AUDIO DATA
         % If no input, prompt for file
         if nargin < 1
            obj.importVideoMp3(nan,nan);
         else % Otherwise specify file
            obj.importVideoMp3(nan,nan,'FILE',file_in);
         end
         
         %% ADD LISTENERS TO PROPERTIES
         addlistener(obj,'name','PostSet',@obj.importVideoMp3);
         addlistener(obj,'path','PostSet',@obj.importVideoMp3);
         
         %% BY DEFAULT, GET FREQUENCY SPECTRUM AND EPOCHS
         obj.GetSpectrum;
         obj.GetEpochs;
      end
      
      function GetSpectrum(obj)
         %% GETSPECTRUM Obtain frequency spectrum from audio time-series
         %
         %  obj.GETSPECTRUM;
         %
         % By: Max Murphy  v1.0  08/29/2017  Original version (R2017a)
         
         %% ESTIMATE TIME-FREQUENCY SPECTRUM FOR AUDIO CONTENT
         tic;
         fprintf(1,'\n%s:\n',obj.name);
         obj.in.spect = struct;
         fprintf(1,'->\tComputing spectrogram...');
         [obj.in.spect.s,obj.in.spect.f,obj.in.spect.t] = spectrogram(...
            mean(obj.in.data,2),...       % input data is average of stereo
            2^nextpow2(obj.in.fs),...             % # window samples
            floor(0.8*(2^nextpow2(obj.in.fs))),...% # overlap samples
            obj.DEF_F, ...                        % frequencies to evaluate
            obj.in.fs);
         fprintf(1,'complete.\n');
         
         %% GET NORMALIZED POWER ESTIMATE BY FREQUENCY
         obj.in.spect.norm = nan(size(obj.in.spect.s));
         fprintf(1,'->\tNormalizing frequency power...');
         for iF = 1:numel(obj.in.spect.f)
            obj.in.spect.norm(iF,:) = ...
               (log(abs(obj.in.spect.s(iF,:)).^2) - ...
                mean(log(abs(obj.in.spect.s(iF,:)).^2)))/...
               std(log(abs(obj.in.spect.s(iF,:)).^2));
         end
         fprintf(1,'complete.\n');
         toc;
         fprintf(1,'\n');
         
      end
      
      function PlotSpectrum(obj)
         %% PLOTSPECTRUM Generate figure with spectrogram for audio file.
         %
         %  obj.PLOTSPECTRUM
         %
         % By: Max Muprhy  v1.0  08/29/2017  Original Version (R2017a)
         
         %%
         if ~isfield(obj.in,'spect')
            error('Must call GetSpectrum method first.');
         end
         figure('Name','Audio Frequency Spectrum',...
            'Color','w',...
            'NumberTitle','off',...
            'Units','Normalized',...
            'Position',[0.25 0.1 0.5 0.8]);
         
         subplot(2,1,1); 
         pxx = mag2db(abs(obj.in.spect.s).^2);
         imagesc(obj.in.spect.t,...
            obj.in.spect.f,...
            pxx);
         ylabel('Frequency (Hz)',...
            'FontName','Arial',...
            'FontSize',16);
         title('Raw Spectrum',...
            'FontName','Arial',...
            'FontSize',16);
         colormap(gca,'jet');
         set(gca,'CLim',[median(pxx(:))-iqr(pxx(:)),...
            median(pxx(:))+iqr(pxx(:))]);
         set(gca,'YDir','normal');
         set(gca,'YTick',5000:5000:25000);
         set(gca,'YTickLabel',5000:5000:25000);
         colorbar;
         
         subplot(2,1,2); 
         imagesc(obj.in.spect.t,...  % time
                 obj.in.spect.f,...  % frequencies
                 obj.in.spect.norm); % normalized power
         title('Normalized Power Spectrum',...
            'FontName','Arial',...
            'FontSize',16);
         set(gca,'YDir','normal'); 
         set(gca,'UserData',duration(0,0,obj.in.spect.t));
         set(gca,'YTick',5000:5000:25000);
         set(gca,'YTickLabel',5000:5000:25000);
         xlabel('Time (sec)',...
            'FontName','Arial',...
            'FontSize',16);
         ylabel('Frequency (Hz)',...
            'FontName','Arial',...
            'FontSize',16); 
         if exist('zmap.mat','file')~=0
            load('zmap.mat');
            colormap(gca,zmap); 
         end
         colorbar;
         
         suptitle(strrep(obj.name(1:end-4),'_','\_'));
      end
      
      function GetEpochs(obj)
         %% GETEPOCHS Identify epoch periods from epoch specifications
         %
         %  obj.GETEPOCHS
         %
         % By: Max Murphy  v1.0  08/29/2017  Original version (R2017a)
         
         %% SET CURRENT EPOCHS
         obj.epochs = struct;
         for iL = 1:numel(obj.Epoch_List)
            obj.epochs.(obj.Epoch_List{iL}) = [];
         end
         
         %% GET PAIN EPOCHS
         
      end
      
      function DefineEpochType(obj,EpochName,EpochFcn)
         %% DEFINEEPOCHTYPE Set new epoch fields and function for detection
         %
         %  obj.DEFINEEPOCHTYPE(EpochName,EpochFcn)
         %
         %  --------
         %   INPUTS
         %  --------
         %  EpochName   :  Name (label) of this sub-field of obj.epochs
         %                 property.
         %
         %  EpochFcn    :  Function handle for defining epoch periods from
         %                 time-series or frequency spectrum.
         %
         % By: Max Murphy  v1.0  08/29/2017  Original version (R2017a)
         
         %%
      end
   end
   
   methods (Access = 'private')
      function importVideoMp3(obj,~,~,varargin)
         %% IMPORTVIDEOMP3('NAME',value,...)
         %  Imports audio data from avi audio exported by VirtualDub.exe as mp3
         %  
         %  'NAME', value pairs:
         %  -> 'DEF' // (def: fullfile(pwd,'audio')) Specifies default UI folder.
         %  -> 'DIR' // (def: fullfile(pwd,'audio')) Default if file name specified
         %                                           but no path.
         %  -> 'FILE' // (def: none) If specified, can be given as full file name,
         %                           or just the file name if file is located in
         %                           default path specified by 'DIR.'
         %
         %  

         %% DEFAULTS
         params = struct;
         if isempty(obj.path)
            params.DEF = obj.DEF;
         else
            params.DEF = obj.path;
         end
         params.DIR = params.DEF;

         %% PARSE VARARGIN
         for iV = 1:2:numel(varargin)
            params.(upper(varargin{iV})) = varargin{iV+1};
         end
         
         if isempty(varargin)
            if ~isempty(obj.name)
               params.FILE = obj.name;
            end
         end

         %% GET FILE NAME AND DIRECTORY
         if isfield(params,'FILE')
            % Check for how the file was submitted
            [DIR,FILE,EXT] = fileparts(params.FILE);

            % Check extension type
            if isempty(EXT)
               EXT = '.mp3';
            elseif ~strcmpi(EXT,'.mp3')
               error('This code only for importing .mp3 files. Wrong file type.');
            end

            % Make sure file has name and extension
            FILE = [FILE,EXT];

            % If the full filename (path also) was specified, assign the full path
            if ~isempty(DIR)
               params.DIR = DIR;
            end
            params.FILE = FILE;
            
         else
            % If nothing is specified, prompt with UI
            [params.FILE,params.DIR,~] = uigetfile('*.mp3',...
                  'Select mp3 audio file to import',...
                  params.DEF);
         end

         %% IMPORT DATA
         file_in = fullfile(params.DIR,params.FILE);
         if exist(file_in,'file')==0
            if exist(params.DIR,'dir')==0
               error('%s is not a valid directory. Audio data not updated.', ...
                  params.DIR);
            else
               error('%s is a valid directory, but %s is not a file there.', ...
                  params.DIR,params.FILE);
            end
         else
            obj.in = importdata(file_in);
            obj.name = params.FILE;
            if isempty(obj.path)
               obj.path = params.DIR;
            end
            if ~obj.VERBOSE
               return;
            end
            fprintf(1,'\n');
            fprintf(1,'\t----------------------\n');
            fprintf(1,'\t Audio object updated \n');
            fprintf(1,'\t----------------------\n');
            fprintf(1,'->\tFile: %s\n',params.FILE); 
            fprintf(1,'->\tPath: %s\n',params.DIR);
            if size(obj.in.data,2) > 1
               fprintf(1,'->\t[Stereo]\n');
            else
               fprintf(1,'->\t[Mono]\n');
            end
            fprintf(1,'->\t%d samples in record\n',size(obj.in.data,1));
            secs = size(obj.in.data,1)/obj.in.fs;
            hrs = floor(secs/3600);
            secs = secs - hrs * 3600;
            mins = floor(secs/60);
            secs = secs - mins * 60;
            if hrs > 0
               fprintf(1,'->\tDuration: %g hours, %g minutes, %g seconds\n',...
                  hrs,mins,secs);
            elseif mins > 0
               fprintf(1,'->\tDuration: %g minutes, %g seconds\n',...
                  mins,secs);
            else
               fprintf(1,'->\tDuration: %g seconds\n',secs);
            end
            fprintf(1,'\n');
         end
      end
   end
   
   
end