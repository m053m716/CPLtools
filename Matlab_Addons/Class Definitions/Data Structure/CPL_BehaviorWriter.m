classdef CPL_BehaviorWriter < matlab.System
%CPL_BehaviorWriter   Delimited metadata text file writer System object
%
%   NOTE: This code is adapted from the Matlab dspdemo.TextFileWriter class
%         example. For better documentation, see:  
%         <a href="matlab: 
%         web(fullfile(docroot,'matlab/create-system-objects.html'))" 
%         >Creating system objects</a>.
%
%   FW = CPL_BehaviorWriter returns a metadata text file writer handle
%   object(TM), which streams multichannel numeric data to a text file
%   using the default settings.
% 
%   FW = CPL_BehaviorWriter('PropertyName', PropertyValue, ...)
%   returns a text file writer System object, with each specified
%   property set to a specified value.
%
%   Step method syntax:
%
%   step(FW, X) writes the multichannel data in input matrix X into the
%   file specified in FW.Filename. Rows of the matrix X are saved as
%   delimiter-separated values in the target text file, using the value in
%   FW.Delimiter.
%   The first call to step creates a new file with the specified name,
%   deletes any pre-existing file with the same name, and writes the
%   content of FW.Header at the very beginning of the file, followed by the
%   data in X. If X is complex, the real and imaginary parts of X are
%   stored as separate interleaved channels.
%   Subsequent calls to step append the new data to the file.
%   The individual data samples are written to the text file using the
%   data format specified in FW.DataFormat
%   Internally, the step method uses the built-in MATLAB function fprintf.
% 
%   System objects may be called directly like a function instead of using
%   the step method. For example, step(obj, x) and obj(x) are equivalent.
%
%   CPL_BehaviorWriter methods:
% 
%   step        - See above description for use of this method
%   release     - Release control of the file and cause the object to
%                 re-initialize when step is next called
%   clone       - Create a new text file writer object with the same
%                 property values and internal states. The original and the
%                 cloned objects are able to write the same file
%                 independently. The cloned object will keep pointing at
%                 the same file location as the original object
%   reset       - Resume data writing from the line immediately
%                 following the last header line.
%   isLocked    - Locked status (logical). isLocked returns true between
%                 the first call to step (or setup) and a call to release
%
%   CPL_BehaviorWriter properties:
% 
%   Filename    - Name of the file where data is written
%   Header      - Content of the text header, written at the beginning of
%                 the file before any data content
%   DataFormat  - Format of each data sample written to the file
%   Delimiter   - Delimiter used to separate samples from different
%                 channels within a single line in the target file
%
% % EXAMPLE: Create an array of random numbers, write them
% % to a text file a frame at a time, read the data back and compare the
% % two
% 
%     A = rand(4096,4);
%     source = dsp.SignalSource('Signal',A, 'SamplesPerFrame',1024);
%     writer = CPL_BehaviorWriter;
%     for k = 1:4
%         dataframe = step(source);
%         step(writer, dataframe)
%     end
%     release(writer)
% 
%     sink = dsp.SignalSink;
%     reader = CPL_MetadataReader;
%     for k = 1:4
%         newdataframe = step(reader);
%         step(sink, newdataframe);
%     end
%     release(reader)
% 
%     assert(all(all(A == sink.Buffer)))
 
%   Copyright 2014-2016 The MathWorks, Inc.

    properties (Nontunable)
        %Filename File name
        % Name of the file to write, including
        % a file extension. If a file with this names already exists,
        % TextFileWriter deletes it and creates a new one without
        % prompting or warning
        Filename   = 'tempfile.txt'
        %Header Header preceding the data
        % Content used as header for the new file created
        % by TextFileReader. The value of Header can be a character string
        % with any number of lines. Data are written to the file in lines,
        % starting from the line immediately following the Header.
        Header = 'Button,Reach,Grasp,Outcome,Forelimb\n'
    end
    
    properties
        %DataFormat Data format 
        % Numeric format of each data sample written
        % to the file. DataFormat accepts any value assignable as
        % Conversion Specifier within the formatSpec string used
        % by the MATLAB built-in function fprintf. 
        % DataFormat applies to all channels written to the file. 
        DataFormat = '%d'
        %Delimiter Data delimiter
        % Character used to separate samples within a line in the target 
        % file. Values belonging to the same row in the input matrix to
        % step: are written to the same line in the file, and represent
        % samples from different channels at the same time instant.
        Delimiter = ','
    end

    properties(Access=private)
        % Saved value of the file identifier
        pFID = -1
        % Starting position of the data in the file
        pDataOffset
        % Number of channels = number of columns in the matrix provided as
        % input to step
        pNumChannels
        % Format specification of a line of data
        pLineFormat
    end
    
    methods
        % Constructor for the System object
        function obj = CPL_BehaviorWriter(varargin)
            setProperties(obj, nargin, varargin{:});
        end
    end
    
    % Overridden implementation methods
    methods(Access = protected)
        % initialize the object
        function setupImpl(obj, u)
            % Populate obj.pFID
            getWorkingFID(obj,'w')
            
            % Write header
            fprintf(obj.pFID, obj.Header);
            
            % Store current file pointer, which is where data has to begin
            obj.pDataOffset = ftell(obj.pFID);
            
            % Compose and lock down format string
            storeNumChannels(obj, u)
            lockLineFormat(obj)
        end
        
        % reset the state of the object
        function resetImpl(obj)
            % go to beginning of the file
            fseek(obj.pFID, obj.pDataOffset, 'bof');
        end
        
        % execute the core functionality
        function stepImpl(obj, u)
            if(isreal(u))
                fprintf(obj.pFID, obj.pLineFormat, u.');
            else
                % If input is complex, interleave real and imag parts as
                % separate adjacent channels
                ri = zeros(size(u,1),obj.pNumChannels,'like',u);
                ri(:,1:2:end) = real(u);
                ri(:,2:2:end) = imag(u);
                fprintf(obj.pFID, obj.pLineFormat, ri.');
            end
        end
        
        % release the object and its resources
        function releaseImpl(obj)
            fclose(obj.pFID);
            obj.pFID = -1;
        end
        
        function loadObjectImpl(obj,s,wasLocked)
            % Call base class method
            loadObjectImpl@matlab.System(obj,s,wasLocked);

            % Re-load state if saved version was locked
            if wasLocked
                % All the following were set at setup
                % Set obj.pFID - needs obj.Filename (restored above)
                obj.pFID = -1; % Superfluous - already set to -1 by default
                getWorkingFID(obj,'a');
                % Go to saved position
                fseek(obj.pFID, s.SavedPosition, 'bof');
                
                obj.pDataOffset = s.pDataOffset;
                obj.pNumChannels = s.pNumChannels;
                obj.pLineFormat = s.pLineFormat;
            end
        end
        
        function s = saveObjectImpl(obj)
            % Default implementation saves all public properties
            s = saveObjectImpl@matlab.System(obj);

            if isLocked(obj)
                % All the fields in s are properties set at setup
                s.SavedPosition = ftell(obj.pFID);
                s.pDataOffset = obj.pDataOffset;
                s.pNumChannels = obj.pNumChannels;
                s.pLineFormat = obj.pLineFormat;
            end
        end
        
        function processTunedPropertiesImpl(obj)
            % Compose and lock down line-reading format
            lockLineFormat(obj);
        end
        
        function processInputSizeChangeImpl(obj, u)
            % Compose and lock down line-reading format
            storeNumChannels(obj, u)
            lockLineFormat(obj);
        end
        
    end
    
    methods(Access = private)
        
        function getWorkingFID(obj, permission)
            if(obj.pFID < 0)
                [obj.pFID, err] = fopen(obj.Filename, permission);
                if ~isempty(err)
                    error(message('dsp:FileWriter:fileError', err));
                end
            end
        end
        
        function storeNumChannels(obj, u)
            if(isreal(u))
                obj.pNumChannels = size(u,2);
            else
                obj.pNumChannels = 2*size(u,2);
            end
        end
        
        function lockLineFormat(obj)
            numChannels = obj.pNumChannels;
            % Compose and lock line-reading format
            fmt = obj.DataFormat;
            obj.pLineFormat = [...
                repmat([fmt,obj.Delimiter,'\t'],1,numChannels-1),...
                fmt,'\n'];
            % obj.pNumChannels = numChannels;
        end
        
    end
end


