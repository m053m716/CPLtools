function data = TDTbin2mat(BLOCK_PATH, varargin)
%TDTBIN2MAT  TDT tank data extraction.
%   data = TDTbin2mat(BLOCK_PATH), where BLOCK_PATH is a string, retrieves 
%   all data from specified block directory in struct format.  This reads
%   the binary tank data and requires no Windows-based software.
%
%   data.epocs      contains all epoc store data (onsets, offsets, values)
%   data.snips      contains all snippet store data (timestamps, channels,
%                   and raw data)
%   data.streams    contains all continuous data (sampling rate and raw 
%                   data)
%   data.scalars    contains all scalar data (samples and timestamps)
%   data.info       contains additional information about the block
%
%   'parameter', value pairs
%        'TYPE'       array of scalars or cell array of strings, specifies 
%                         what type of data stores to retrieve from the tank
%                     1: all (default)
%                     2: epocs
%                     3: snips
%                     4: streams
%                     5: scalars
%                     TYPE can also be cell array of any combination of 
%                         'epocs', 'streams', 'scalars', 'snips', 'all'
%                     examples:
%                         data = TDTbin2mat('MyTank','Block-1','TYPE',[1 2]);
%                             > returns only epocs and snips
%                         data = TDTbin2mat('MyTank','Block-1','TYPE',{'epocs','snips'});
%                             > returns only epocs and snips
%      'STORE'      string, specify a single store to extract
%      'CHANNEL'    integer, choose a single channel, to extract from 
%                       stream or snippet events. Default is 0, to extract 
%                       all channels.
%      'HEADERS'    var, set to 1 to return only the headers for this 
%                       block, so that you can make repeated calls to read 
%                       data without having to parse the TSQ file every 
%                       time. Or, pass in the headers using this parameter.
%                   example:
%                       heads = TDTbin2mat(BLOCK_PATH, 'HEADERS', 1);
%                       data = TDTbin2mat(BLOCK_PATH, 'HEADERS', heads, 'TYPE', {'snips'});
%                       data = TDTbin2mat(BLOCK_PATH, 'HEADERS', heads, 'TYPE', {'streams'});
%

% defaults
TYPE     = 1:5;
STORE    = '';
CHANNEL  = 0;
HEADERS  = 0;
T1       = 0;
T2       = 0;
VERBOSE  = 0;

% parse varargin
for i = 1:2:length(varargin)
    eval([upper(varargin{i}) '=varargin{i+1};']);
end

ALLOWED_TYPES = {'ALL','EPOCS','SNIPS','STREAMS','SCALARS'};

if iscell(TYPE)
    types = zeros(1, numel(TYPE));
    for i = 1:numel(TYPE)
        ind = find(strcmpi(ALLOWED_TYPES, TYPE{i}));
        if isempty(ind)
            error('Unrecognized type: %s\nAllowed types are: %s', TYPE{i}, sprintf('%s ', ALLOWED_TYPES{:}))
        end
        if ind == 1
            types = 1:5;
            break;
        end
        types(i) = ind;
    end
    TYPE = unique(types);
else
    if ~isnumeric(TYPE), error('TYPE must be a scalar, number vector, or cell array of strings'), end
    if TYPE == 1, TYPE = 1:5; end
end

useOutsideHeaders = 0;
doHeadersOnly = 0;
if isa(HEADERS, 'struct')
    useOutsideHeaders = 1;
    headerStruct = HEADERS;
    clear HEADERS;
else
    headerStruct = struct();
    if HEADERS == 1
        doHeadersOnly = 1;
    end
end

%{
// Demo program showing how to read tsq file and tev file, and
// OpenSorter's sort code file.

// tank file structure
//---------------------
// tbk file has block events information and on second time offsets
// to efficiently locate events if the data is queried by time.
//
// tsq file is a list of event headers, each 40 bytes long,
// ordered strictly by time .
//
// tev file contains event binary data
//
// tev and tsq files work together to get an event's data and
//     attributes
//
// tdx file contains just information about epoc stores,
// is optionally generated after recording for fast retrieval
// of epoc information
//
// OpenSorter sort codes file structure
// ------------------------------------
// Sort codes saved by OpenSorter are stored in block subfolders such as
// Block-3\sort\USERDEFINED\EventName.SortResult.
//
// .SortResult files contain sort codes for 1 to all channels within
// the selected block.  Each file starts with a 1024 byte boolean channel
// map indicating which channel's sort codes have been saved in the file.
// Following this map, is a sort code field that maps 1:1 with the event
// ID for a given block.  The event ID is essentially the Nth occurance of
// an event on the data collection timeline. See lEventID below.
%}

% Tank event types (tsqEventHeader.type)
global EVTYPE_UNKNOWN EVTYPE_STRON EVTYPE_STROFF EVTYPE_SCALAR EVTYPE_STREAM  EVTYPE_SNIP;
global EVTYPE_MARK EVTYPE_HASDATA EVTYPE_UCF EVTYPE_PHANTOM EVTYPE_MASK EVTYPE_INVALID_MASK;
EVTYPE_UNKNOWN  = hex2dec('00000000');
EVTYPE_STRON    = hex2dec('00000101');
EVTYPE_STROFF	= hex2dec('00000102');
EVTYPE_SCALAR	= hex2dec('00000201');
EVTYPE_STREAM	= hex2dec('00008101');
EVTYPE_SNIP		= hex2dec('00008201');
EVTYPE_MARK		= hex2dec('00008801');
EVTYPE_HASDATA	= hex2dec('00008000');
EVTYPE_UCF		= hex2dec('00000010');
EVTYPE_PHANTOM	= hex2dec('00000020');
EVTYPE_MASK		= hex2dec('0000FF0F');
EVTYPE_INVALID_MASK	= hex2dec('FFFF0000');

EVMARK_STARTBLOCK	= hex2dec('0001');
EVMARK_STOPBLOCK	= hex2dec('0002');

global DFORM_FLOAT DFORM_LONG DFORM_SHORT DFORM_BYTE 
global DFORM_DOUBLE DFORM_QWORD DFORM_TYPE_COUNT
DFORM_FLOAT		 = 0;
DFORM_LONG		 = 1;
DFORM_SHORT		 = 2;
DFORM_BYTE		 = 3;
DFORM_DOUBLE	 = 4;
DFORM_QWORD		 = 5;
DFORM_TYPE_COUNT = 6;

ALLOWED_FORMATS = {'single','int32','int16','int8','double','int64'};

% % TTank event header structure
% tsqEventHeader = struct(...
%     'size', 0, ...
%     'type', 0, ...  % (long) event type: snip, pdec, epoc etc
%     'code', 0, ...  % (long) event name: must be 4 chars, cast as a long
%     'channel', 0, ... % (unsigned short) data acquisition channel
%     'sortcode', 0, ... % (unsigned short) sort code for snip data. See also OpenSorter .SortResult file.
%     'timestamp', 0, ... % (double) time offset when even occurred
%     'ev_offset', 0, ... % (int64) data offset in the TEV file OR (double) strobe data value
%     'format', 0, ... % (long) data format of event: byte, short, float (typical), or double
%     'frequency', 0 ... % (float) sampling frequency
% );

if strcmp(BLOCK_PATH(end), '\') ~= 1 && strcmp(BLOCK_PATH(end), '/') ~= 1
    BLOCK_PATH = [BLOCK_PATH filesep];
end

if ~useOutsideHeaders
    tsqList = dir([BLOCK_PATH '*.tsq']);
    if length(tsqList) < 1
        error('no TSQ file found')
    elseif length(tsqList) > 1
        error('multiple TSQ files found')
    end

    cTSQ = [BLOCK_PATH tsqList(1).name];
    tsq = fopen(cTSQ, 'rb');
    if tsq < 0
        error('TSQ file could not be opened')
    end
    headerStruct.TEVpath = [BLOCK_PATH strrep(tsqList(1).name, '.tsq', '.tev')];
end

tev = fopen(headerStruct.TEVpath, 'rb');

if tev < 0
    error('TEV file could not be opened')
end

% read TBK notes to get event info
%cTBK = [BLOCK_PATH strrep(tsqList(1).name, '.tsq', '.tbk')]
%tbk = fopen(cTBK, 'r');
%s = fread(tbk, inf, '*char')'; 
%fclose(tbk);
%sp = strsplit(s, '[USERNOTEDELIMITER]');
%notes = ParseNotes(sp{3})
%names = {notes.StoreName}

%codes = cellfun(@name2code, names)

% event type: snips, streams, epocs
%types = arrayfun(@code2type, cellfun(@str2num,{notes.TankEvType}), 'UniformOutput', false)

% single, int32, etc
%formats = arrayfun(@(x)MAP(x),cellfun(@str2num,{notes.DataFormat}), 'UniformOutput', false)

% byte size of each store
%bytes = arrayfun(@format2bytes, formats)

% number of channels and points, for preallocating
%nchans = cellfun(@str2num,{notes.NumChan})
%npts = cellfun(@str2num,{notes.NumPoints})

if ~useOutsideHeaders
    % read start time
    fseek(tsq, 48, 'bof');  
    code1 = fread(tsq, 1, '*int32');
    assert(code1 == EVMARK_STARTBLOCK, 'Block start marker not found');
    fseek(tsq, 56, 'bof'); 
    headerStruct.start_time = fread(tsq, 1, '*double');

    % read stop time
    fseek(tsq, -32, 'eof');
    code2 = fread(tsq, 1, '*int32');
    if code2 ~= EVMARK_STOPBLOCK
        warning('Block end marker not found');
        headerStruct.stop_time = nan;
    else
        fseek(tsq, -24, 'eof');
        headerStruct.stop_time = fread(tsq, 1, '*double');    
    end

    % total duration for data size estimation
    %headerStruct.duration = headerStruct.stop_time-headerStruct.start_time;
    %starttime: '14:37:06'
    %stoptime: '14:37:10'
    %duration: '00:00:04'
    
end

data = struct('epocs', [], 'snips', [], 'streams', [], 'scalars', []);

% set info fields
path_parts = strsplit(BLOCK_PATH,filesep);
t = cellfun(@(x) [x filesep],path_parts(1:(end-2)),'uni',0);
tank = strcat(t{:});
block = path_parts(end-1);
data.info.tankpath = tank;
data.info.blockname = block{1};

data.info.date = datestr(datenum([1970, 1, 1, 0, 0, headerStruct.start_time]),'yyyy-mmm-dd');
data.info.starttime = datestr(datenum([1970, 1, 1, 0, 0, headerStruct.start_time]),'HH:MM:SS');
data.info.stoptime = datestr(datenum([1970, 1, 1, 0, 0, headerStruct.stop_time]),'HH:MM:SS');

s1 = datenum([1970, 1, 1, 0, 0, headerStruct.start_time]);
s2 = datenum([1970, 1, 1, 0, 0, headerStruct.stop_time]);

if headerStruct.stop_time > 0
   data.info.duration = datestr(s2-s1,'HH:MM:SS');
end

data.info.blocktime = datestr(datenum([1970, 1, 1, 0, 0, headerStruct.start_time]));
data.info.streamchannel = CHANNEL;
data.info.snipchannel = CHANNEL;

if ~useOutsideHeaders
    tsqFileSize = fread(tsq, 1, '*int64');
    fseek(tsq, 40, 'bof');

    % get all possible store codes
    %[i, c] = unique([bsq.code], 'stable')
    %[i2, c2] = unique([bsq.code])

    % get their names
    %names = {bsq(c2).name}

    % get their sizes
    %sizes = double([bsq(c2).size])

    % get their types
    %types = [bsq(c2).type]

    % get their header counts
    %headerCounts = hist(double([bsq.code]), double(all_store_codes))

    %estByteSizes = double([bsq(c2).size]).*headerCounts
    % preallocate the arrays
    %data = struct('epocs', [], 'snips', [], 'streams', []);
    %estByteSizes = double([bsq(c2).size]).*headerCounts
    %formats = {bsq(c2).format}
    %bsq(ind).format = MAP(dform);

    % use headers to read from tev files
    % offset = 40;
    % 
    % bsq = memmapfile(cTSQ, ...
    %     'Format', {...
    %     'int32', 1, 'size';...
    %     'int32', 1, 'type';...
    %     'int32', 1, 'code';...
    %     'uint16', 1, 'channel';...
    %     'uint16', 1, 'sortcode';...
    %     'double', 1, 'timestamp';...
    %     'uint64', 1, 'ev_offset';...
    %     'int32', 1, 'dform';...
    %     'single', 1, 'frequency'}, 'Offset', offset, 'Repeat', inf);
    % 

    % read all headers into one giant array
    heads = fread(tsq, Inf, '*uint32');

    % reshape so each column is one header
    heads = reshape(heads, 10, numel(heads)/10);

    headerStruct.timestamps = typecast(reshape(heads(5:6, :), 1, numel(heads(5:6,:))), 'double');
    headerStruct.starttime = headerStruct.timestamps(1);
    headerStruct.timestamps = headerStruct.timestamps - headerStruct.starttime;
    headerStruct.timestamps = headerStruct.timestamps(2:end); % throw out the first one
    
    % do time filter here
    timeInd = [];
    if T1 > 0
        if T2 > 0
            timeInd = find(headerStruct.timestamps >= T1 & headerStruct.timestamps < T2);
        else
            timeInd = find(headerStruct.timestamps >= T1);
        end
    elseif T2 > 0
        timeInd = find(headerStruct.timestamps < T2);
    end
    
    if ~isempty(timeInd)
        timeInd = timeInd + 1;
        % parse out the information we need
        headerStruct.sizes = heads(1,timeInd);
        headerStruct.types = heads(2,timeInd);
        headerStruct.codes = heads(3,timeInd);
        x = typecast(heads(4, timeInd), 'uint16');
        headerStruct.channels = x(1:2:end);
        headerStruct.sortcodes = x(2:2:end);
        clear x;
        
        % which one you use depends on data type, cast both up front for speed
        headerStruct.values = typecast(reshape(heads(7:8, :), 1, numel(heads(7:8,:))), 'double');
        headerStruct.values = headerStruct.values(timeInd); % throw out the first one
        headerStruct.offsets = typecast(headerStruct.values, 'uint64');

        headerStruct.dforms = heads(9,timeInd); % I already know this information
        headerStruct.freqs = typecast(heads(10,:), 'single');
        headerStruct.freqs = headerStruct.freqs(timeInd); % throw out first one
        
    else
        % parse out the information we need
        headerStruct.sizes = heads(1,2:end-1);
        headerStruct.types = heads(2,2:end-1);
        headerStruct.codes = heads(3,2:end-1);
        x = typecast(heads(4, 2:end-1), 'uint16');
        headerStruct.channels = x(1:2:end);
        headerStruct.sortcodes = x(2:2:end);
        clear x;
        
        % which one you use depends on data type, cast both up front for speed
        headerStruct.values = typecast(reshape(heads(7:8, :), 1, numel(heads(7:8,:))), 'double');
        headerStruct.values = headerStruct.values(2:end); % throw out the first one
        headerStruct.offsets = typecast(headerStruct.values, 'uint64');

        headerStruct.dforms = heads(9,2:end-1); % I already know this information
        headerStruct.freqs = typecast(heads(10,:), 'single');
        headerStruct.freqs = headerStruct.freqs(2:end); % throw out first one
    
    end
    
    headerStruct.names = char(typecast(headerStruct.codes, 'uint8'));
    headerStruct.names = reshape(headerStruct.names, 4, numel(headerStruct.names)/4);
    %access the name like this data.(type).(names(:,index)').data
    
    clear heads; % don't need this anymore
    [headerStruct.uniqueCodes, c] = unique(headerStruct.codes);
    headerStruct.uniqueNames = headerStruct.names(:,c)';
    headerStruct.uniqueTypes = num2cell(headerStruct.types(c));
    headerStruct.uniqueDForms = headerStruct.dforms(c);
end
  
if doHeadersOnly
    data = headerStruct;
    return;
end

% get all possible codes, names, and types
currentTypes = cellfun(@code2type, headerStruct.uniqueTypes, 'UniformOutput', false);
currentEpocTypes = cellfun(@epoc2type, headerStruct.uniqueTypes, 'UniformOutput', false);
currentDForms = headerStruct.uniqueDForms;

% loop through all possible stores
for i = 1:numel(headerStruct.uniqueCodes)
    
    % TODO: show similar verbose printout to TDT2mat
    % TODO: filter based on time
    currentCode = headerStruct.uniqueCodes(i);
    currentName = headerStruct.uniqueNames(i,:);
    
    % if looking for a particular store and this isn't it, skip it
    if ~strcmp(STORE, '') && ~strcmp(STORE, currentName), continue; end
    
    varName = fixVarName(currentName, 1);
    currentType = currentTypes{i};
    currentEpocType = currentEpocTypes{i};
    
    ind = find(strcmpi(ALLOWED_TYPES, currentType));
    if ~any(TYPE==ind), continue; end
    
    currentDForm = currentDForms(i);
    fmt = 'unknown';
    sz = 4;
    switch currentDForm
        case DFORM_FLOAT
            fmt = 'single';
        case DFORM_LONG
            fmt = 'int32';
        case DFORM_SHORT
            fmt = 'int16';
            sz = 2;
        case DFORM_BYTE
            fmt = 'int8';
            sz = 1;
        case DFORM_DOUBLE
            fmt = 'double';
            sz = 8;
        case DFORM_QWORD
            fmt = 'int64';
            sz = 8;
    end
    
    % find the header indicies for this store
    ind = find(headerStruct.codes == currentCode);

    % load data struct based on the type
    if isequal(currentType, 'epocs')
        if strcmp(currentEpocType,'offset')
            % this is an offset epoc for another epoc event, get its name
            buddy1 = char(typecast(headerStruct.channels(ind(1)), 'uint8'));
            buddy2 = char(typecast(headerStruct.sortcodes(ind(1)), 'uint8'));
            field = fixVarName([buddy1 buddy2]);
            data.epocs.(field).offset = headerStruct.timestamps(ind)';
            fprintf('info: using %s as offsets for %s epoc event\n', currentName, data.epocs.(field).name);
        else
            data.epocs.(varName).data = headerStruct.values(ind)';
            data.epocs.(varName).onset = headerStruct.timestamps(ind)';
            % make artificial offsets in case there are none
            if ~isfield(data.epocs.(varName),'offset')
                data.epocs.(varName).offset = [data.epocs.(varName).onset(2:end); Inf];
            end
            data.epocs.(varName).name = currentName;
        end
        
    elseif isequal(currentType, 'scalars')
        nchan = double(max(headerStruct.channels(ind)));
        
        % preallocate data array
        data.scalars.(varName).data = zeros(nchan, numel(ind)/nchan, fmt);
        
        % organize data array by channel
        for xx = 1:nchan
            data.scalars.(varName).data(xx,:) = headerStruct.values(ind(headerStruct.channels(ind) == xx));
        end
        
        % only use channel 1 timestamps
        data.scalars.(varName).ts = headerStruct.timestamps(ind(headerStruct.channels(ind) == 1));
        data.scalars.(varName).name = currentName;
        %data.scalars.(varName).fs = freqs(ind(1));
    elseif isequal(currentType, 'snips')
        if CHANNEL > 0
            all_channels = headerStruct.channels(ind);
            ind = ind(ismember(all_channels, CHANNEL));
        end
        
        all_offsets = double(headerStruct.offsets(ind));        
        all_sizes = double(headerStruct.sizes(ind));
            
        % preallocate data array
        npts = (all_sizes(1)-10) * 4/sz;
        data.snips.(varName).data = zeros(numel(ind), npts, fmt);
        
        % now fill it
        for f = 1:numel(ind)
            if fseek(tev, all_offsets(f), 'bof') == -1
                ferror(tev)
            end
            npts = (all_sizes(f)-10) * 4/sz;
            data.snips.(varName).data(f,:) = fread(tev, npts, ['*' fmt]);
        end
        
        % load the rest of the info
        data.snips.(varName).chan = headerStruct.channels(ind)';
        data.snips.(varName).sortcode = headerStruct.sortcodes(ind)';
        data.snips.(varName).ts = headerStruct.timestamps(ind)';
        data.snips.(varName).name = currentName;
        data.snips.(varName).sortname = 'TankSort'; % TODO add others
    elseif isequal(currentType, 'streams')
        if CHANNEL > 0
            all_channels = headerStruct.channels(ind);
            ind = ind(ismember(all_channels, CHANNEL));
        end
        all_offsets = double(headerStruct.offsets(ind));
        all_sizes = double(headerStruct.sizes(ind));
        
        nchan = double(max(headerStruct.channels(ind)));
        chan_index = ones(1,nchan);
        
        % preallocate data array
        npts = (all_sizes(1)-10) * 4/sz;
        if CHANNEL == 0
            data.streams.(varName).data = zeros(nchan, npts*numel(ind)/nchan, fmt);
        else
            data.streams.(varName).data = zeros(1, npts*numel(ind)/nchan, fmt);
        end

        % catch if the data is in SEV file
        sevList = dir([BLOCK_PATH '*.sev']);
        useSEVs = 0;
        for ii = 1:length(sevList)
            if strfind(sevList(ii).name, currentName) > 0
                useSEVs = 1;
            end
        end
        
        if useSEVs
            if CHANNEL == 0
                d = SEV2mat(BLOCK_PATH, 'VERBOSE', 0);
            else
                d = SEV2mat(BLOCK_PATH, 'CHANNEL', CHANNEL, 'VERBOSE', 0);
            end
            data.streams.(varName) = d.(varName);
        else

            % now fill it
            for f = 1:numel(ind)
                curr_chan = headerStruct.channels(ind(f));
                if CHANNEL > 0 && curr_chan ~= CHANNEL
                    continue
                end
                if fseek(tev, all_offsets(f), 'bof') == -1
                    ferror(tev)
                end
                start = chan_index(curr_chan);
                npts = (all_sizes(f)-10) * 4/sz;
                if CHANNEL > 0
                    data.streams.(varName).data(1,start:start+npts-1) = fread(tev, npts, ['*' fmt])';
                else
                    data.streams.(varName).data(curr_chan,start:start+npts-1) = fread(tev, npts, ['*' fmt])';
                end
                chan_index(curr_chan) = chan_index(curr_chan) + npts;
            end
        
            data.streams.(varName).fs = headerStruct.freqs(ind(1));
            data.streams.(varName).name = currentName;
        end
    end
end

if ~useOutsideHeaders
    if (tsq), fclose(tsq); end
end
if (tev), fclose(tev); end

end

function t = epoc2type(code)
%% given epoc event code, return if it is 'onset' or 'offset' event

    global EVTYPE_STRON EVTYPE_STROFF;

    strobeOnTypes = [EVTYPE_STRON];
    strobeOffTypes = [EVTYPE_STROFF];
    t = 'unknown';
    if ismember(code, strobeOnTypes)
        t = 'onset';
    elseif ismember(code, strobeOffTypes)
        t = 'offset';
    end
end

function s = code2type(code)
%% given event code, return string 'epocs', 'snips', 'streams', or 'scalars'

global EVTYPE_STRON EVTYPE_STROFF EVTYPE_SCALAR EVTYPE_SNIP EVTYPE_MASK EVTYPE_STREAM;

strobeTypes = [EVTYPE_STRON EVTYPE_STROFF];
scalarTypes = [EVTYPE_SCALAR];
snipTypes = [EVTYPE_SNIP];

if ismember(code, strobeTypes)
    s = 'epocs';
elseif ismember(code, snipTypes)
    s = 'snips';
elseif bitand(code, EVTYPE_MASK) == EVTYPE_STREAM
    s = 'streams';
elseif ismember(code, scalarTypes)
    s = 'scalars';
else
    s = 'unknown';
end

end

function varname = fixVarName(name, varargin)
    if nargin == 1
        VERBOSE = 0;
    else
        VERBOSE = varargin{1};
    end
    varname = name;
    for ii = 1:numel(varname)
        if ii == 1
            if isstrprop(varname(ii), 'digit')
                varname(ii) = 'x';
            end
        end
        if ~isstrprop(varname(ii), 'alphanum')
            varname(ii) = '_';
        end
    end
    %TODO: use this instead in 2014+
    %varname = matlab.lang.makeValidName(name);
    if ~isvarname(name) && VERBOSE
        fprintf('info: %s is not a valid Matlab variable name, changing to %s\n', name, varname);
    end
end