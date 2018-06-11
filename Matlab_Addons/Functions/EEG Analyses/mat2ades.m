function mat2ades(data,fileName,FS,labels,labelType) 
%% MAT2ADES write in the current folder ADES and DAT files from matrix 
% 
%   MAT2ADES(data,fileName,FS,labels,labelType)
%   
%   --------
%    INPUTS
%   --------
%     data      :       Matrix of data (nChannels * nSamples; microVolts)
%
%   fileName    :       String of the output files without extension (.ades
%                       and .dat files will have same name)
%                       NOTE: can be left empty ([]) to bring up UI
%
%      FS       :       Sampling frequency
% 
%    labels     :       Cell array with channel labels
%
%   labelType   :       'EEG' or 'MEG'
%
% By: Sophie Chen - January 2014

%% GET OUTPUT FILE NAME
if isempty(fileName)
    [fileName,pathName] = uiputfile('*',['Select save name ' ...
                                         '(no extension) and location']);
    adesFile = fullfile(pathName,[fileName '.ades']);
else
    adesFile = [fileName '.ades'];
end



fid = fopen(adesFile,'wt');
 
fprintf(fid,'%s\r\n','#ADES header file ');
fprintf(fid,'%s','samplingRate = ');
fprintf(fid,'%d\r\n',FS);
fprintf(fid,'%s','numberOfSamples = ');
fprintf(fid,'%d\r\n',size(data,2));
 
for lab = 1:length(labels)
    fprintf(fid,'%s\r\n',[labels{lab} ' = ' labelType]);
end
 
fclose(fid);
 
%% generate the DAT file
 
datFile = [fileName '.dat'];
 
fad = fopen(datFile,'wb');
fwrite(fad, data, 'float32');
fclose(fad);
end