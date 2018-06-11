function Extract_Moved_Data(varargin)
%Based on files_moved, this function parallellizes the extraction of all files moved to the Isilon. 

if ~isempty(varargin)
    files_moved = cell(size(varargin{1},1),size(varargin{1},2));

    for i = 1:size(varargin{1},1)
        for ii = 1:size(varargin{1},2)
            files_moved(i,ii) = varargin{1}(i,ii);
        end
    end
    
    if size(files_moved,1) > 1
        parfor x = 1:size(files_moved,1)
            curr_file = files_moved(x,:);
            switch upper(curr_file{2})
                case upper('Intan')
                    if contains(curr_file{3},'.rhd')
                        INTAN2single_ch_wCAR('NAME',fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data',curr_file{1},curr_file{2},curr_file{3}), ...
                            'SAVELOC',fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move\',curr_file{1},curr_file{2}),'gitInfo',curr_file{4})
                    elseif contains(curr_file{3},'.rhs')
                        INTAN2single_RHS2000('NAME',fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data',curr_file{1},curr_file{2},curr_file{3}), ...
                            'SAVELOC',fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move\',curr_file{1},curr_file{2}),'gitInfo',curr_file{4})
                    end
                case upper('LabView')

                case upper('MicroD')
                    MicroDExtraction(curr_file)
                case upper('OpenEphys')

                case upper({'TDTRat','TDTMonkey'})
                    TDTExtraction(curr_file)
            end
        end
    else
        curr_file = files_moved(1,:);
        switch upper(curr_file{2})
            case upper('Intan')
                if contains(curr_file{3},'.rhd')
                    INTAN2single_ch_wCAR('NAME',fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data',curr_file{1},curr_file{2},curr_file{3}), ...
                        'SAVELOC',fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move\',curr_file{1},curr_file{2}),'gitInfo',curr_file{4})
                elseif contains(curr_file{3},'.rhs')
                    INTAN2single_RHS2000_PARA('NAME',fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Recorded_Data',curr_file{1},curr_file{2},curr_file{3}), ...
                        'SAVELOC',fullfile('\\kumc.edu\data\research\SOM RSCH\NUDOLAB\Processed_Data\Extracted_Data_To_Move\',curr_file{1},curr_file{2}),'gitInfo',curr_file{4})
                end
            case upper('LabView')

            case upper('MicroD')
                MicroDExtraction(curr_file)
            case upper('OpenEphys')

            case upper({'TDTRat','TDTMonkey'})
                TDTExtraction(curr_file)
        end
    end
end