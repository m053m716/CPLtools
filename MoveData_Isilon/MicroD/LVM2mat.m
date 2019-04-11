function [data,spikes] = LVM2mat(NAME)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
%% Initialize variables.
delimiter = '\t';
if nargin<=2
   startRow = 1;
   endRow = inf;
end

%% Open the text file.
fileID = fopen(NAME,'r');
fline = strsplit(fgetl(fileID),'\t');
cols = length(fline);
useCols = ~cell2mat(cellfun(@isempty,fline,'Uni',0));
frewind(fileID);

%% Format for each line of text:
formatSpec = [repmat('%f',1,cols) '%[^\n\r]'];

%% Read columns of data according to the format.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');


%% Close the text file.
fclose(fileID);

%% Create output variable
hold_data = cell2mat(dataArray(useCols));

[~,name,~] = fileparts(NAME);
dims = size(hold_data);

switch dims(2)
  
   case 2
      data = single(hold_data(:,1));
      spikes = hold_data(:,2);
      spikes(spikes ~= 0) = 1;
      spikes = sparse(spikes);
   case 4
      data = single(hold_data(:,1));
      spikes = hold_data(:,2);
      
      idx = find(~isnan(hold_data(:,4)));
      spikes(idx) = 0;
      spikes(spikes ~= 0) = 1;
      spikes = sparse(spikes);
      
      data(idx) = nan;
      
   otherwise
      
      data = [];
      spikes = [];
      warning('%s data is formatted incorrectly (%d x %d).',name,dims(1),dims(2));
end

end

