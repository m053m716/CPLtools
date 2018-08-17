function TDTExtraction_adhoc(varargin) %#ok<*INUSD>
% Extract data from TDT block passed via files_in. Create folder schema and
% split wave data into individual channel files (_RawData). Filter wave data and save
% as individual channels (_Filtered). Run though any other streaming fields
% and seperate data (_Digital). Remaining block data saved in trial folder
% (_EpocSnipInfo)
USE_STATE_FILTER = true;    % Use state HPF?
STATE_FC = 300;             % state filter high pass cutoff

myJob = getCurrentJob;


files_in = varargin(1:4);
set(myJob,'Tag',['Extracting TDT block data for ' files_in{1,3} '...']);
% Extract from TDT
block = TDTbin2mat(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data',files_in{1,1},files_in{1,2},files_in{1,3}));

set(myJob,'Tag',['TDT extraction for ' files_in{1,3} ' complete, saving raw and filtered single-channel files...']);
% Get the animal name from the portion of the block name before first
% underscore
ani = files_in{1,3}(1:(find(files_in{1,3} == '_',1,'first')-1));
gitInfo = files_in{1,4};

% Create folder structure in 'Extracted_Data_To_Move' folder
if ~exist(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani),'dir')
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani))
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3}))
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_RawData']))
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_Digital']))
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_Filtered']))
elseif ~exist(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3}),'dir')
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3}))
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_RawData']))
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_Digital']))
    mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_Filtered']))
end

% First get the wave streams
if isfield(block,'streams')
    fn = fieldnames(block.streams);
    wav_data = fn(contains(fn,'Wav'));
end

% Run through each stream that begins with 'Wav' and save each channels
% data and the sample frequency in '_RawData' folder. 'Wave' is
% associated with 'P1' (Probe 1), 'Wav2' is associated with 'P2' and so
% on. As each wave stream is saved, that stream is removed from the
% structure.
if ~isempty(wav_data)
    for x = 1:length(wav_data)
        if strcmp(wav_data{x},'Wave')
            probe = '_P1_';
        else
            probe = ['_P' wav_data{x}(end) '_'];
        end

        for y = 1:size(block.streams.(wav_data{x}).data,1)
            data = single(block.streams.(wav_data{x}).data(y,:) * 10^6);  %#ok<*NASGU>
            data(isnan(data) | isinf(data)) = 0; % Make sure there isn't something that would mess up the filtering step.
            fs = double(block.streams.(wav_data{x}).fs);
            save(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_RawData'],[files_in{1,3} '_Raw' probe 'Ch_' num2str(y, '%03i') '.mat']),'data','fs','gitInfo','-v7.3');
            if USE_STATE_FILTER
               data = single(HPF(double(data),STATE_FC,fs));
            else
               [~, bpFilt] = extractionBandPassFilt('FS',fs);
               data = single(filtfilt(bpFilt,double(data)));
            end
            save(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_Filtered'],[files_in{1,3} '_Filt' probe 'Ch_' num2str(y, '%03i') '.mat']),'data','fs','gitInfo','-v7.3');
        end
        block.streams = rmfield(block.streams,wav_data{x});
    end
end

set(myJob,'Tag',['TDT extraction for ' files_in{1,3} ' complete, saving digital single-channel files...']);
% If there are any other streams, extract those in the same manner as
% above, but save in '_Digital' folder. Also, instead of 'P1', etc, the
% name of the stream is saved in the file name. As each stream is
% saved, that stream is removed from the structure.
if isfield(block,'streams') && isempty(fieldnames(block.streams))
    block = rmfield(block,'streams');
elseif isfield(block,'streams') && ~isempty(fieldnames(block.streams))
    fn = fieldnames(block.streams);
    for x = 1:length(fn)
        for y = 1:size(block.streams.(fn{x}).data,1)
            data = block.streams.(fn{x}).data(y,:); 
            fs = block.streams.(fn{x}).fs;
            save(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_Digital'],[files_in{1,3} '_' fn{x} '_Ch_' num2str(y, '%03i') '.mat']),'data','fs','gitInfo','-v7.3');
        end
    end
    block = rmfield(block,'streams');
end

% Whatever remains in the structure is saved in a .mat file within that
% trials folder.
save(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_EpocSnipInfo.mat']),'block','gitInfo','-v7.3');
set(myJob,'Tag',[files_in{1,3} ' single-channel extraction complete.']);
end