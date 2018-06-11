function files_moved = MoveRecordedData(rec_directory,mv_directory,ext_directory,mv_filename)
%This function will move all recorded data to the Isilon

Cluster = 'local';
myCluster = parcluster(Cluster);
num_workers = myCluster.NumWorkers;

poolobj = gcp('nocreate'); % If no pool, do not create new one.
if isempty(poolobj)
    poolobj = parpool(Cluster,num_workers); %#ok<*NASGU>
else
    poolobj = gcp;
end

recData = dir(rec_directory);
isfolder = [recData(:).isdir];
rec_folders = {recData(isfolder == 1).name}';
rec_folders(ismember(rec_folders,{'.','..'})) = [];
files_moved = [];
for x = 1:length(rec_folders)
    rec_folder = rec_folders{x};
    recData = dir(fullfile(rec_directory,rec_folders{x}));
    isfolder = [recData(:).isdir];
    dev_folders = {recData(isfolder == 1).name}';
    dev_folders(ismember(dev_folders,{'.','..'})) = [];
    
    for y = 1:length(dev_folders)
        switch upper(dev_folders{y})
            case upper('Intan')
                recType = 1;
            case upper('LabView')
                recType = 2;
            case upper('MicroD')
                recType = 3;
            case upper('OpenEphys')
                recType = 4;
            case upper({'TDTRat','TDTMonkey'})
                recType = 5;
        end
        dev_folder = dev_folders{y};
        recData = dir(fullfile(rec_directory,rec_folders{x},dev_folders{y}));
        recData = recData(~ismember({recData.name},{'.','..'}));
        recData = {recData(:).name}';
        par_mv_files = cell(length(recData),1);
        try
            parfor z = 1:length(recData)
                fprintf('Checking: %s - %s - %s\n',rec_folder,dev_folder,recData{z})
                incl = 0;
                if recType == 5
                    files = dir(fullfile(rec_directory,rec_folder,dev_folder,recData{z}));
                    incl = any(cell2mat(strfind({files(:).name},'.tsq')));
                elseif recType == 1
                    files = dir(fullfile(rec_directory,rec_folder,dev_folder,recData{z}));
                    incl = contains(files.name,'.rh');
                end
                
                if incl
                    fprintf('Moving: %s - %s - %s\n',rec_folder,dev_folder,recData{z})
                    movefile(fullfile(rec_directory,rec_folder,dev_folder,recData{z}),fullfile(mv_directory,rec_folder,dev_folder,recData{z}),'f')
                    files_moved = [files_moved; {rec_folder, dev_folder, recData{z}}];  
                end
            end
        catch
            disp('Error: MoveRecordedData parfor.')
        end
    end
end

delete(poolobj)

if ~isempty('files_moved')
    save(fullfile(ext_directory,mv_filename),'files_moved')
end