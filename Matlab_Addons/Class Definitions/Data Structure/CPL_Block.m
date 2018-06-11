classdef CPL_Block < handle
%% CPL_BLOCK Create a datastore object based on CPL data structure
%
%  obj = CPL_BLOCK;
%  obj = CPL_BLOCK('NAME','VALUE',...);
%
%  ex: 
%  obj = CPL_BLOCK('DIR','P:\Your\Block\Directory\Here');
%
%  CPL_BLOCK Properties:
%     Name - Name of recording BLOCK.
%
%     Fields - List of property field names that may have files associated
%              with them.
%
%     Graphics - Graphics objects that are associated with CPL_BLOCK
%                object. Currently contains Spikes subfield, which is a
%                SPIKEIMAGE object that is available after calling the
%                PLOTSPIKES method. The Waves subfield is only available
%                after calling the PLOTWAVES method. To recall the
%                SPIKEIMAGE object once it has been constructed, call as
%                obj.Graphics.Spikes.Build.
%
%  CPL_BLOCK Methods:
%     CPL_Block - Class constructor. Call as obj = CPL_BLOCK(varargin)
%
%     UpdateID - Update the File or Folder ID for a particular Field, which
%                is listed in obj.Fields. Call as
%                obj.UpdateID(name,type,value); name is the name of the
%                field, type is the ID type ('File' or 'Folder'), and value
%                is the new ID. For example:
%                obj.UpdateID('Spikes','Folder','pca-PT_Spikes') would
%                change where the CPL_BLOCK finds its spikes files.
%
%     UpdateContents - Using current information for File and Folder ID
%                      string identifiers, update the list of files
%                      associated with a particular information field.
%
%     PlotWaves -    Make a preview of the filtered waveform for all 
%                    channels, and include any sorted, clustered, or 
%                    detected spikes for those channels as highlighted 
%                    marks at the appropriate time stamp.
%
%     PlotSpikes -   Display all spikes for a particular channel as a
%                    SPIKEIMAGE object.
%
%     LoadSpikes -   Call as x = obj.LoadSpikes(channel) to load spikes
%                    file contents to the structure x.
%
%     LoadClusters - Call as x = obj.LoadClusters(channel) to load 
%                    class file contents to the structure x.
%
%     LoadSorted -   Call as x = obj.LoadSorted(channel) to load class file
%                    contents to the structure x.
%
% By: Max Murphy  v1.0  08/27/2017

%% PUBLIC PROPERTIES
   properties (Access = public)
      Name        % Base name of block
      
      Fields      % List of property field names
      
      % Graphics - Graphical objects associated with CPL_BLOCK object.
      % -> Spikes : SPIKEIMAGE object. Once constructed, can
      %             call as obj.Graphics.Spikes.Build to
      %             recreate the spikes figure.
      % -> Waves : AXES object. Destroyed when figure is
      %            closed.
      Graphics    % Graphical objects associated with block
      
      Status      % Completion status for each element of CPL_BLOCK/FIELDS
      
      Channels    % List of channels from board, from probe, and masking.
   end

%% PRIVATE PROPERTIES
   properties (Access = private)
      DIR         % Full directory of block
      Raw         % Raw Data files
      Filt        % Filtered files
      CAR         % CAR-filtered files
      DS          % Downsampled files
      Spikes      % Spike detection files
      Clusters    % Unsupervised clustering files
      Sorted      % Sorted spike files
      MEM         % LFP spectra files
      Digital     % "Digital" (extra) input files
      ID          % Identifier structure for different elements
      Notes       % Notes from text file
   end
   
   properties(Access = private)
      DEF = 'P:/Rat'; % Default for UI BLOCK selection
      CH_ID = 'Ch';   % Channel index ID
      CH_FIELDWIDTH = 3; % Number of characters in channel number 
                         % (example: Example_Raw_Ch_001.mat would be 3)
      VERBOSE = true; % Whether to report list of files and fields.
      MASK  % Whether to include channels or not
      REMAP % Mapping of channel numbers to actual numbers on probe
   end
   
%% PUBLIC METHODS
   methods (Access = public)
      function obj = CPL_Block(varargin)
         %% CPL_BLOCK Create a datastore object based on CPL data structure
         %
         %  obj = CPL_BLOCK;
         %  obj = CPL_BLOCK('NAME',Value,...);
         %
         %  ex: 
         %  obj = CPL_BLOCK('DIR','P:\Your\Block\Directory\Here');
         %
         %  List of 'NAME', Value input argument pairs:
         %
         %  -> 'DIR' : (def: none) Specify as string with full directory of
         %              recording BLOCK. Specifying this will skip the UI
         %              selection portion, so it's useful if you are
         %              looping the expression.
         %
         %  -> 'VERBOSE' : (def: true) Setting this to false suppresses
         %                  output list of files and folders associated
         %                  with the CPL_BLOCK object during
         %                  initialization.
         %
         %  -> 'DEF' : (def: 'P:/Rat') If you are using the UI selection
         %              interface a lot, and typically working with a more
         %              specific project directory, you can specify this to
         %              change where the default UI selection directory
         %              starts. Alternatively, just change the property in
         %              the code under private properties.
         %
         %  -> 'CH_ID' : (def: 'Ch') If you have a different file name
         %               identifier that precedes the channel number for
         %               that particular file, specify this on object
         %               construction.
         %
         %               ex: 
         %               obj.List('Raw')
         %               
         %               Current Raw files stored in [obj.Name]:
         %               -> Example_Raw_Chan_001.mat
         %
         %               In this case, you would specify 'Chan' during
         %               construction of obj:
         %               obj = CPL_Block('CH_ID','Chan');
         %
         %  -> 'CH_FIELDWIDTH' : (def: 3) Number of characters in the
         %                        channel number in the file name.
         %
         %  -> 'MASK' : (def: []) If specified, use as a nChannels x 1
         %              logical vector of true/false for channels to
         %              include/exclude.
         %
         %  -> 'REMAP' : (def: []) If specified, use as a nChannels x 1
         %               double vector of channel mappings.
         %
         % By: Max Murphy  v1.0  08/25/2017
         
         %% PARSE VARARGIN
         for iV = 1:2:numel(varargin)
            if ~ischar(varargin{iV})
               continue
            end
            p = findprop(obj,varargin{iV});
            if isempty(p)
               continue
            end
            obj.(varargin{iV}) = varargin{iV+1};
         end
         
         %% LOOK FOR BLOCK DIRECTORY
         if isempty(obj.DIR)
            obj.DIR = uigetdir(obj.DEF,'Select recording BLOCK');
            if obj.DIR == 0
               error('No block selected. Object not created.');
            end
         else
            if exist(obj.DIR,'dir')==0
               error('%s is not a valid block directory.',obj.DIR);
            end
         end
         
         %% CONSTRUCT BLOCK OBJECT
         obj.init;
         
      end
      
      function UpdateID(obj,name,type,value)
         %% UPDATEID Update the file or folder identifier for block
         %
         %  obj.UPDATEID(name,type,value)
         %
         %  --------
         %   INPUTS
         %  --------
         %    name   :  String corresponding to one of the structure data
         %              types (example: 'Raw' or 'Filt' etc.)
         %
         %    type   :  'File' or 'Folder'.
         %
         %    value  :  String corresponding to updated ID value. 
         %
         %  NOTE: Inputs can be strings, or cell arrays of strings
         %  corresponding to multiple simultaneous updates. If cell arrays
         %  are specified, element i of each array correspond to one
         %  another; therefore, each cell array must be the same length.
         %
         % By: Max Murphy  v1.0  08/25/2017  Original version (R2017a)
         
         %% PARSE INPUT         
         if (~ischar(name) || ~ischar(type) || ~ischar(value)) 
            % Look for cell inputs:
            if (~iscell(name) && ~iscell(type) && ~iscell(value))
               error('Inputs must be strings or cell array of strings of equal length.');
            elseif (~iscell(name) && ~iscell(type))
               % Only one field changed, but with multiple options:
               name = lower(name);
               name(1) = upper(name(1));
               if strcmp(name,'Delimiter')
                  error('ID.Delimiter cannot take multiple values.');
               end
               type = lower(type); 
               type(1) = upper(type(1));
               if ~ismember(type,{'File'; 'Folder'})
                  error('Type is %s, but must be ''File'' or ''Folder''',type);
               end
                              
               str = strjoin(value,' + ');
               fprintf(1,'ID.%s.%s updated to %s\n',name,type,str);
               obj.ID.(name).(type) = cell(numel(value),1);
               for ii = 1:numel(value)
                  obj.ID.(name).(type){ii} = value{ii};
               end
               
               obj.UpdateContents(name);
               return;
               
            else
               for iN = 1:numel(name)
                  name{iN} = lower(name{iN});
                  name{iN}(1) = upper(name{iN}(1));
                  type{iN} = lower(type{iN}); 
                  type{iN}(1) = upper(type{iN}(1));
               end
            end
         else
            name = lower(name);
            name(1) = upper(name(1));
            if strcmp(name,'Delimiter')
               % Special case: update delimiter
               obj.ID.Delimiter = value;
               fprintf(1,'ID.Delimiter updated to %s\n',value);
               % Must update all fields since all are affected.
               for iL = 1:numel(obj.Fields)
                  obj.UpdateContents(obj.Fields{iL});
               end
               fprintf(1,'Fields changed to reflect updated delimiter.\n');
               return;
            end
            type = lower(type); 
            type(1) = upper(type(1));
            if ~ismember(type,{'File'; 'Folder'})
               error('Type is %s, but must be ''File'' or ''Folder''',type);
            end
         end
         
         %% UPDATE PROPERTY
         if ~iscell(name)
            obj.ID.(name).(type) = value;
            fprintf(1,'ID.%s.%s updated to %s\n',name,type,value);
            obj.(name).dir = dir(fullfile(obj.DIR,...
               [obj.Name obj.ID.Delimiter obj.ID.(name).Folder], ...
               ['*' obj.ID.(name).File '*.mat']));
            
            obj.(name).ch = [];
            for ii = 1:numel(obj.(name).dir)
               temp = strsplit(obj.(name).dir(ii).name,obj.ID.Delimiter);
               ch_ind = find(ismember(temp,obj.CH_ID),1,'last')+1;
               obj.(name).ch = [obj.(name).ch; ...
                  str2double(temp{ch_ind}(1:obj.CH_FIELDWIDTH))];
            end
         else
            % If multiple, update all first:
            for iN = 1:numel(name)
               obj.ID.(name{iN}).(type{iN}) = value{iN};
               fprintf(1,'ID.%s.%s updated to %s\n',name{iN},type{iN},value{iN});
            end
            
            % Then update lists
            for iN = 1:numel(name)
               obj.UpdateContents(name{iN});
            end
         end
         
      end
      
      function List(obj,name)
         %% LIST  Give list of current files associated with field.
         %
         %  obj.LIST;
         %  obj.LIST(name);
         %
         %  Note: If called without an input argument, returns names of all
         %  associated files for all fields.
         %
         %  -------
         %   INPUT
         %  -------
         %    name   :  Name of a particular field you want to return a
         %              list of files for.
         %
         % By: Max Murphy  v1.0  08/25/2017 Original Version (R2017a)
         
         %% RETURN LIST OF VALUES
         if nargin == 2
            if isempty(obj.(name).dir)
               fprintf(1,'\nNo %s files found for %s.\n',name,obj.Name);
            else
               fprintf(1,'\nCurrent %s files stored in %s:\n->\t%s\n\n',...
                  name, obj.Name, ...
                  strjoin({obj.(name).dir.name},'\n->\t'));
            end
         else
            for iL = 1:numel(obj.Fields)
               name = obj.Fields{iL};
               if isempty(obj.(name).dir)
                  fprintf(1,'\nNo %s files found for %s.\n',name,obj.Name);
               else
                  fprintf(1,'\nCurrent %s files stored in %s:\n->\t%s\n\n',...
                     name, obj.Name, ...
                     strjoin({obj.(name).dir.name},'\n->\t'));
               end
            end
         end
      end
      
      function PlotWaves(obj,WAV,SPK)
         %% PLOTWAVES  Uses PLOTCHANNELS for this recording BLOCK
         %
         %  obj.PLOTWAVES
         %  obj.PLOTWAVES(WAV)
         %  obj.PLOTWAVES(WAV,SPK)
         %
         %  --------
         %   INPUTS
         %  --------
         %     WAV   :     Folder containing either FILT or CARFILT waves.
         %
         %     SPK   :     Folder containing either SORTED, CLUSTERS, or
         %                 SPIKES.
         %
         %  See also: PLOTCHANNELS
         
         %% PARSE VARARGIN
         if nargin==1
            if ~isempty(obj.CAR.dir)
               WAV = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
                  obj.ID.CAR.Folder]);
            elseif ~isempty(obj.Filt.dir)
               WAV = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
                  obj.ID.Filt.Folder]);
            else
               plotChannels;
               return;
            end
            
            if ~isempty(obj.Sorted.dir)
               SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
                  obj.ID.Sorted.Folder]);
            elseif ~isempty(obj.Clusters.dir)
               SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
                  obj.ID.Clusters.Folder]);
            elseif ~isempty(obj.Spikes.dir)
               SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
                  obj.ID.Spikes.Folder]);
            else
               plotChannels('DIR',WAV); 
               return;
            end
         end
         
         if nargin==2
            if ~isempty(obj.Sorted.dir)
               SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
                  obj.ID.Sorted.Folder]);
            elseif ~isempty(obj.Clusters.dir)
               SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
                  obj.ID.Clusters.Folder]);
            elseif ~isempty(obj.Spikes.dir)
               SPK = fullfile(obj.DIR,[obj.Name obj.ID.Delimiter ...
                  obj.ID.Spikes.Folder]);
            else
               plotChannels('DIR',WAV); 
               return;
            end
         end
         obj.Graphics.Waves = plotChannels('DIR',WAV,'SPK',SPK);
         
         
      end
      
      function PlotSpikes(obj,ch)
         %% PLOTSPIKES  Show all spike clusters for a given channel.
         %
         %  obj.PLOTSPIKES(ch)
         %
         %  --------
         %   INPUTS
         %  --------
         %     ch    :     Channel number to show spikes for.
         %
         %
         % By: Max Murphy  v1.1  08/27/2017  Original version (R2017a)
         % See also: SPIKEIMAGE
         
         %% CHECK FOR SPIKES
         if isempty(obj.Spikes.dir)
            error('No spikes currently detected.');
         end
         
         %% FIND CORRESPONDING CHANNELS FROM SPIKES FILE
         ind = find(abs(obj.Spikes.ch-ch)<eps,1,'first');
         load(fullfile(obj.Spikes.dir(ind).folder,...
               obj.Spikes.dir(ind).name),'spikes','peak_train','pars');
            
         fs = pars.FS;
         
         %% CHECK FOR CLUSTERS AND GET CORRESPONDING CHANNEL
         if ~isempty(obj.Sorted.dir)
            ind = find(abs(obj.Sorted.ch-ch)<eps,1,'first');
            load(fullfile(obj.Sorted.dir(ind).folder,...
               obj.Sorted.dir(ind).name),'class');
         elseif ~isempty(obj.Clusters.dir)
            ind = find(abs(obj.Clusters.ch-ch)<eps,1,'first');
            load(fullfile(obj.Clusters.dir(ind).folder,...
               obj.Clusters.dir(ind).name),'class');
         else
            % (If no clusters yet, just make everything class "1")
            class = ones(size(spikes,1),1);
         end
         
         obj.Graphics.Spikes = SpikeImage(spikes,fs,peak_train,class);
      end
      
      function out = LoadSpikes(obj,ch)
         %% LOADSPIKES  Load spikes file for a given channel.
         %
         %  out = obj.LOADSPIKES(ch)
         %
         %  --------
         %   INPUTS
         %  --------
         %     ch    :  Channel number (scalar)
         %
         %  --------
         %   OUTPUT
         %  --------
         %     out   :  Data structure with the following fields:
         %              -> artifact: [1 x # artifact samples double]
         %              -> features: [K x # features matrix for K spikes]
         %              -> pars: parameters structure for spike detection
         %              -> peak_train: [N x 1 sparse vector of spike peaks]
         %              -> pp: [K x 1 double vector of peak prominences]
         %              -> pw: [K x 1 double vector of peak widths]
         %              -> spikes: [K x M matrix of spike snippets for M
         %                          samples per snippet.]
         %
         % By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)
         
         %%
         if isempty(obj.Spikes.ch)
            error('No Spikes files currently in %s block.',obj.Name);
         end
         
         ind = find(abs(obj.Spikes.ch - ch) < eps,1,'first');
         out = load(fullfile(obj.Spikes.dir(ind).folder,...
                                   obj.Spikes.dir(ind).name));
         out.ch = ch;
      end
      
      function out = LoadClusters(obj,ch)
         %% LOADCLUSTERS  Load clusters file for a given channel.
         %
         %  out = obj.LOADCLUSTERS(ch)
         %
         %  --------
         %   INPUTS
         %  --------
         %     ch    :  Channel number (scalar)
         %
         %  --------
         %   OUTPUT
         %  --------
         %     out   :  Data structure with the following fields:
         %              -> class: [K x 1 unsupervised class labels for K
         %                               spikes from SPC output]
         %              -> clu: [# temps x # clust matrix of SPC cluster
         %                       assignments for all temperatures used in
         %                       SW iterative procedure]
         %              -> pars: parameters structure used for SPC
         %              -> tree: tree showing how many members each cluster
         %                       was assigned for each temperature. Used in
         %                       determining which temperature to select
         %                       from the SPC procedure.
         %
         % By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)
         
         %%
         if isempty(obj.Clusters.ch)
            error('No Clusters files currently in %s block.',obj.Name);
         end
         
         ind = find(abs(obj.Clusters.ch - ch) < eps,1,'first');
         out = load(fullfile(obj.Clusters.dir(ind).folder,...
                             obj.Clusters.dir(ind).name));                          
         out.ch = ch;
      end
      
      function out = LoadSorted(obj,ch)
         %% LOADSORTED  Load sorted file for a given channel.
         %
         %  out = obj.LOADSORTED(ch)
         %
         %  --------
         %   INPUTS
         %  --------
         %     ch    :  Channel number (scalar)
         %
         %  --------
         %   OUTPUT
         %  --------
         %     out   :  Data structure with the following fields:
         %              -> class: [K x 1 manually assigned class labels for
         %                               K spikes using CRC]
         %              -> tag: [K x 1 manually assigned label tags for K
         %                             spikes using CRC]
         %
         % By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)
         
         %%
         if isempty(obj.Sorted.ch)
            error('No Sorted files currently in %s block.',obj.Name);
         end
         
         ind = find(abs(obj.Sorted.ch - ch) < eps,1,'first');
         out = load(fullfile(obj.Sorted.dir(ind).folder,...
                             obj.Sorted.dir(ind).name));                          
         out.ch = ch;
      end
         
      function UpdateContents(obj,fieldname)
         %% UPDATECONTENTS    Update files for particular field
         %
         %  obj.UPDATECONTENTS(fieldname)
         %
         %  ex:
         %  obj.UpdateContents('Raw');
         %
         %  --------
         %   INPUTS
         %  --------
         %  fieldname   :  (String) name of field to re-check for new
         %                 files.
         %
         % By: Max Murphy  v1.1  08/27/2017  (R2017a)
         
         %% GET CORRECT SYNTAX
         fieldmatch = false(size(obj.Fields));
         for ii = 1:numel(obj.Fields)
            fieldmatch(ii) = strcmpi(fieldname,obj.Fields{ii});
         end
         
         if sum(fieldmatch) > 1
            error(['Redundant field names.\n' ...
               'Check Block_Defaults.mat or %s CPL_BLOCK object.\n'],...
               obj.Name);
         elseif sum(fieldmatch) < 1
            error('No matching field in %s. Check CPL_BLOCK object.\n', ...
               obj.Name);
         else
            fieldname = obj.Fields{fieldmatch};
         end
         
         %% UPDATE FILES DEPENDING ON CELL OR STRING CASES
         if (~iscell(obj.ID.(fieldname).Folder) && ...
               ~iscell(obj.ID.(fieldname).File))
            obj.(fieldname).dir = [];
            obj.(fieldname).dir = [obj.(fieldname).dir; ...
               dir(fullfile(obj.DIR, ...
               [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder],...
               ['*' obj.ID.(fieldname).File '*.mat']))];
            
            obj.(fieldname).ch = [];
            for ii = 1:numel(obj.(fieldname).dir)
               temp = strsplit(obj.(fieldname).dir(ii).name,obj.ID.Delimiter);
               ch_ind = find(ismember(temp,obj.CH_ID),1,'last')+1;
               if isempty(ch_ind)
                  obj.(fieldname).ch = [obj.(fieldname).ch; nan];
                  continue;
               end
               obj.(fieldname).ch = [obj.(fieldname).ch; ...
                  str2double(temp{ch_ind}(1:obj.CH_FIELDWIDTH))];
            end
            if isempty(obj.(fieldname).dir)
               dname = fullfile(obj.DIR,...
                [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder]);
             if obj.VERBOSE
               if exist(dname,'dir')==0
                  fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
                     obj.Name,fieldname,dname);
               else
                  fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
                     obj.Name,fieldname);
               end
             end
            else
               if obj.VERBOSE
                  fprintf(1,'\nFound %s -- %s:\n->\t%s\n',obj.Name,fieldname,...
                     strjoin({obj.(fieldname).dir.name},'\n->\t'));
               end
            end
         elseif (iscell(obj.ID.(fieldname).Folder) && ...
               ~iscell(obj.ID.(fieldname).File))
            obj.(fieldname).dir = [];
            for ii = 1:numel(obj.ID.(fieldname).Folder)
               obj.(fieldname).dir = [obj.(fieldname).dir; ...
                dir(fullfile(obj.DIR, ...
                [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder{ii}],...
                ['*' obj.ID.(fieldname).File '*.mat']))];
            end
            
            obj.(fieldname).ch = [];
            for ii = 1:numel(obj.(fieldname).dir)
               temp = strsplit(obj.(fieldname).dir(ii).name,obj.ID.Delimiter);
               ch_ind = find(ismember(temp,obj.CH_ID),1,'last')+1;
               if isempty(ch_ind)
                  obj.(fieldname).ch = [obj.(fieldname).ch; nan];
                  continue;
               end
               obj.(fieldname).ch = [obj.(fieldname).ch; ...
                  str2double(temp{ch_ind}(1:obj.CH_FIELDWIDTH))];
            end
            if isempty(obj.(fieldname).dir)
               dname = fullfile(obj.DIR,...
                [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder{ii}]);
             if obj.VERBOSE
               if exist(dname,'dir')==0
                  fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
                     obj.Name,fieldname,dname);
               else
                  fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
                     obj.Name,fieldname);
               end
             end
            else
               if obj.VERBOSE
                  fprintf(1,'\nFound %s -- %s:\n->\t%s\n',obj.Name,fieldname,...
                     strjoin({obj.(fieldname).dir.name},'\n->\t'));
               end
            end
         elseif (iscell(obj.ID.(fieldname).File) && ...
               ~iscell(obj.ID.(fieldname).Folder))
            obj.(fieldname).dir = [];
            for ii = 1:numel(obj.ID.(fieldname).File)
               obj.(fieldname).dir = [obj.(fieldname).dir; ...
                dir(fullfile(obj.DIR, ...
                [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder],...
                ['*' obj.ID.(fieldname).File{ii} '*.mat']))];
            end
            
            obj.(fieldname).ch = [];
            for ii = 1:numel(obj.(fieldname).dir)
               temp = strsplit(obj.(fieldname).dir(ii).name,obj.ID.Delimiter);
               ch_ind = find(ismember(temp,obj.CH_ID),1,'last')+1;
               if isempty(ch_ind)
                  obj.(fieldname).ch = [obj.(fieldname).ch; nan];
                  continue;
               end
               obj.(fieldname).ch = [obj.(fieldname).ch; ...
                  str2double(temp{ch_ind}(1:obj.CH_FIELDWIDTH))];
            end
            if isempty(obj.(fieldname).dir)
               dname = fullfile(obj.DIR,...
                [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder]);
             if obj.VERBOSE
               if exist(dname,'dir')==0
                  fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
                     obj.Name,fieldname,dname);
               else
                  fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
                     obj.Name,fieldname);
               end
             end
            else
               if obj.VERBOSE
                  fprintf(1,'\nFound %s -- %s:\n->\t%s\n',obj.Name,fieldname,...
                     strjoin({obj.(fieldname).dir.name},'\n->\t'));
               end
            end
         elseif (iscell(obj.ID.(fieldname).File) && ...
               iscell(obj.ID.(fieldname).Folder))
            obj.(fieldname).dir = [];
            for ii = 1:numel(obj.ID.(fieldname).File)
               for kk = 1:numel(obj.ID.(fieldname).Folder)
                  obj.(fieldname).dir = [obj.(fieldname).dir; ...
                   dir(fullfile(obj.DIR, ...
                   [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder{kk}],...
                   ['*' obj.ID.(fieldname).File{ii} '*.mat']))];
               end
            end
            
            obj.(fieldname).ch = [];
            for ii = 1:numel(obj.(fieldname).dir)
               temp = strsplit(obj.(fieldname).dir(ii).name,obj.ID.Delimiter);
               ch_ind = find(ismember(temp,obj.CH_ID),1,'last')+1;
               if isempty(ch_ind)
                  obj.(fieldname).ch = [obj.(fieldname).ch; nan];
                  continue;
               end
               obj.(fieldname).ch = [obj.(fieldname).ch; ...
                  str2double(temp{ch_ind}(1:obj.CH_FIELDWIDTH))];
            end
            if isempty(obj.(fieldname).dir)
               dname = fullfile(obj.DIR,...
                [obj.Name obj.ID.Delimiter obj.ID.(fieldname).Folder{kk}]);
             if obj.VERBOSE
               if exist(dname,'dir')==0
                  fprintf(1,'\nMissing %s -- %s:\n->\t[%s not found]\n',...
                     obj.Name,fieldname,dname);
               else
                  fprintf(1,'\nFound %s -- %s:\n->\t[Empty]\n',...
                     obj.Name,fieldname);
               end
             end
            else
               if obj.VERBOSE
                  fprintf(1,'\nFound %s -- %s:\n->\t%s\n',obj.Name,fieldname,...
                     strjoin({obj.(fieldname).dir.name},'\n->\t'));
               end
            end
         end
         if isempty(obj.(fieldname).dir)
            obj.Status(fieldmatch) = false;
         else
            obj.Status(fieldmatch) = true;
         end
      end
      
      function TakeNotes(obj)
         %% TAKENOTES   View or update notes on current BLOCK.
         %
         %  obj.TAKENOTES
         %
         % By: Max Murphy  v1.0  08/27/2017  Original version (R2017a)
         
         %%
         h = NotesUI;
         if isempty(obj.Notes.File)
            obj.Notes.File = fullfile(obj.DIR,[obj.Name ' Description.txt']);
         end
         h.addNotes(obj,obj.Notes);

      end
      
   end

%% PUBLIC HIDDEN METHODS
   methods (Access = public, Hidden = true)
      function UpdateNotes(obj,str)
         %% UPDATENOTES Update notes
         obj.Notes.String{1} = str;
      end
   end
   
%% PRIVATE METHODS
   methods (Access = 'private')
      function init(obj)
         %% INIT Initialize BLOCK object
         %
         %  obj.INIT;
         %
         %  By: Max Murphy v1.0  08/25/2017  Original version (R2017a)
         
         %% LOAD DEFAULT ID SETTINGS
         defs = load('Block_Defaults.mat');
         obj.ID = struct;
         obj.ID.Delimiter = defs.Delimiter;
         obj.ID.CAR.File = defs.CAR_File_ID;
         obj.ID.CAR.Folder = defs.CAR_Folder_ID;
         obj.ID.Clusters.File = defs.Clusters_File_ID;
         obj.ID.Clusters.Folder = defs.Clusters_Folder_ID;
         obj.ID.DS.File = defs.DS_ID;
         obj.ID.DS.Folder = defs.DS_ID;
         obj.ID.MEM.File = defs.MEM_ID;
         obj.ID.MEM.Folder = defs.MEM_ID;
         obj.ID.Filt.File = defs.Filt_File_ID;
         obj.ID.Filt.Folder = defs.Filt_Folder_ID;
         obj.ID.Raw.File = defs.Raw_File_ID;
         obj.ID.Raw.Folder = defs.Raw_Folder_ID;
         obj.ID.Spikes.File = defs.Spikes_File_ID;
         obj.ID.Spikes.Folder = defs.Spikes_Folder_ID;
         obj.ID.Sorted.File = defs.Sorted_File_ID;
         obj.ID.Sorted.Folder = defs.Sorted_Folder_ID;
         obj.ID.Digital.File = defs.Digital_File_ID;
         obj.ID.Digital.Folder = defs.Digital_Folder_ID;
         obj.Fields = defs.List;
         obj.Status = false(size(obj.Fields));
         
         %% LOOK FOR NOTES
         notes = dir(fullfile(obj.DIR,'*Description.txt'));
         if ~isempty(notes)
            obj.Notes.File = fullfile(notes.folder,notes.name);
            fid = fopen(obj.Notes.File,'r');
            obj.Notes.String = textscan(fid,'%s',...
               'CollectOutput',true,...
               'Delimiter','\n');
            fclose(fid);
         else
            obj.Notes.File = [];
            obj.Notes.String = [];
         end
         
         %% ADD PUBLIC BLOCK PROPERTIES
         path = strsplit(obj.DIR,filesep);
         obj.Name = path{numel(path)};
         finfo = strsplit(obj.Name,obj.ID.Delimiter);
         
         for iL = 1:numel(obj.Fields)
            obj.UpdateContents(obj.Fields{iL});
         end
         
         %% ADD CHANNEL INFORMATION
         if ismember('CAR',obj.Fields(obj.Status))
            obj.Channels.Board = sort(obj.CAR.ch,'ascend');
         elseif ismember('Filt',obj.Fields(obj.Status))
            obj.Channels.Board = sort(obj.Filt.ch,'ascend');
         elseif ismember('Raw',obj.Fields(obj.Status))
            obj.Channels.Board = sort(obj.Raw.ch,'ascend');
         end
         
         % Check for user-specified MASKING
         if ~isempty(obj.MASK)
            if abs(numel(obj.MASK)-numel(obj.Channels.Board))<eps
               obj.Channels.Mask = obj.MASK;
            else
               warning('Wrong # of elements in specified MASK.');
               fprintf(1,'Using all channels by default.\n');
               obj.Channels.Mask = true(size(obj.Channels.Board));
            end
         else
            obj.Channels.Mask = true(size(obj.Channels.Board));
         end
         
         % Check for user-specified REMAPPING
         if ~isempty(obj.REMAP)
            if abs(numel(obj.REMAP)-numel(obj.Channels.Board))<eps
               obj.Channels.Probe = obj.REMAP;
            else
               warning('Wrong # of elements in specified REMAP.');
               fprintf(1,'Using board channels by default.\n');
               obj.Channels.Probe = obj.Channels.Board;
            end
         else
            obj.Channels.Probe = obj.Channels.Board;
         end
         
      end
   end
   
   
end