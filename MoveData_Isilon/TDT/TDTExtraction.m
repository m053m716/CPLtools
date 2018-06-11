function TDTExtraction(files_in) %#ok<*INUSD>
% Extract data from TDT block passed via files_in. Create folder schema and
% split wave data into individual channel files (_RawData). Filter wave data and save
% as individual channels (_Filtered). Run though any other streaming fields
% and seperate data (_Digital). Remaining block data saved in trial folder
% (_EpocSnipInfo)

    % Extract from TDT
    block = TDTbin2mat(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data',files_in{1,1},files_in{1,2},files_in{1,3}),'TYPE',{'EPOCS','SNIPS','STREAMS','SCALARS'});
    
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
        mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_FilteredCAR']))
    elseif ~exist(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3}),'dir')
        mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3}))
        mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_RawData']))
        mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_Digital']))
        mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_Filtered']))
        mkdir(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_FilteredCAR']))
    end
    
    
    if exist('block','var')
        block_fields = fieldnames(block);
        for i = 1:length(block_fields)
            if contains(block_fields{i}, 'streams')
                fn = fieldnames(block.streams);
                wav_data = fn(contains(fn,'Wav'));
                
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
                        
                        hold_filt = zeros(size(block.streams.(wav_data{x}).data));
                        for y = 1:size(block.streams.(wav_data{x}).data,1)
                            data = single(block.streams.(wav_data{x}).data(y,:) * 10^6);  %#ok<*NASGU>
                            fs = block.streams.(wav_data{x}).fs;
                            save(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_RawData'],[files_in{1,3} '_Raw' probe 'Ch_' num2str(y, '%03i') '.mat']),'data','fs','gitInfo','-v7.3');
                            [~, bpFilt] = BandPassFilt('FS',fs);
                            data = single(filtfilt(bpFilt,double(data)));
                            hold_filt(y,:) = data;
                            save(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_Filtered'],[files_in{1,3} '_Filt' probe 'Ch_' num2str(y, '%03i') '.mat']),'data','fs','gitInfo','-v7.3');
                            data = [];
%                             data = data - ref;
%                             save(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_FilteredCAR'],[files_in{1,3} '_FiltCAR' probe 'Ch_' num2str(y, '%03i') '.mat']),'data','fs','gitInfo','-v7.3');
                        end
                        
                        ref = mean(hold_filt,1);
                        
                        for y = 1:size(hold_filt,1)
                            data = hold_filt(y,:) - ref;
                            save(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_FilteredCAR'],[files_in{1,3} '_FiltCAR' probe 'Ch_' num2str(y, '%03i') '.mat']),'data','fs','gitInfo','-v7.3');
                        end
                        block.streams = rmfield(block.streams,wav_data{x});
                    end
                end
                
                % If there are any other streams, extract those in the same manner as
                % above, but save in '_Digital' folder. Also, instead of 'P1', etc, the
                % name of the stream is saved in the file name. As each stream is
                % saved, that stream is removed from the structure.
                if isempty(fieldnames(block.streams))
                    block = rmfield(block,'streams');
                else
                    fn = fieldnames(block.streams);
                    for x = 1:length(fn)
                        if ~contains(fn{x},'pNeu')
                            for y = 1:size(block.streams.(fn{x}).data,1)
                                data = block.streams.(fn{x}).data(y,:); 
                                fs = block.streams.(fn{x}).fs;
                                save(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_Digital'],[files_in{1,3} '_' fn{x} '_Ch_' num2str(y, '%03i') '.mat']),'data','fs','gitInfo','-v7.3');
                            end
                            block.streams = rmfield(block.streams,fn{x});
                        end
                    end
                end
                
            % If there is an 'epocs' field, extract all the fields within
            % to the _Digital folder.
            elseif contains(block_fields{i}, 'epocs')
                fn = fieldnames(block.epocs);
                for x = 1:length(fn)
                    data = block.epocs.(fn{x}).data;
                    onset = block.epocs.(fn{x}).onset;
                    offset = block.epocs.(fn{x}).offset;
                    save(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_Digital'],[files_in{1,3} '_' fn{x} '.mat']),'data','onset','offset','gitInfo','-v7.3');
                    block.epocs = rmfield(block.epocs,fn{x});
                end
                
                if isempty(fieldnames(block.epocs))
                    block = rmfield(block,'epocs');
                end
            end
        end
    end

    % Whatever remains in the structure is saved in a .mat file within that
    % trials folder.
    save(fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move',files_in{1,1},files_in{1,2},ani,files_in{1,3},[files_in{1,3} '_pNeuSnipInfo.mat']),'block','gitInfo','-v7.3');
end