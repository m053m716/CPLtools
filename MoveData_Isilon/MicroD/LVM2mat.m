function [data,spikes] = LVM2mat(fname)
%% LVM2MAT  Converts from LabView format to Matlab format
%   
%  [data,spikes] = LVM2MAT(fname);
%
%  --------
%   INPUTS
%  --------
%    fname     :     Full filename of binary LVM file.
%
%  --------
%   OUTPUT
%  --------
%    data      :     Array of raw data (time-series).
%
%   spikes     :     Vector indicating presence of spike peaks at a given
%                       sample.
%

%% Initialize variables.
delimiter = '\t';
if nargin<=2
   startRow = 1;
   endRow = inf;
end

%% Open the text file.
fileID = fopen(fname,'r');
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

[~,name,~] = fileparts(fname);
dims = size(hold_data);

% switch dims(2)
%   
%    case 2
%       data = (single(hold_data(:,1))-0.75)*1e3; % Scale to uV
%       spikes = hold_data(:,2);
%       spikes(spikes ~= 0) = 1;
%       spikes = sparse(spikes);
%    case 4
%       data = single(hold_data(:,1));
%       spikes = hold_data(:,2);
%       
%       idx = find(~isnan(hold_data(:,4)));
%       spikes(idx) = 0;
%       spikes(spikes ~= 0) = 1;
%       spikes = sparse(spikes);
%       
%       data(idx) = nan;
%       
%    otherwise
%       
%       data = [];
%       spikes = [];
%       warning('%s data is formatted incorrectly (%d x %d).',name,dims(1),dims(2));
% end

header = cell2mat(cellfun(@str2double,fline(useCols),'UniformOutput',false));
dataIdx = find((abs(header)>eps)& ...
   (abs(header-0.5)>eps) & ...
   (abs(header-1.5)>eps),1,'first');

data = (single(hold_data(:,1))-0.75)*1e3; % Scale to uV
spikes = hold_data(:,2);
spikes(isnan(spikes)) = 0;
spikes(spikes ~= 0) = 1;
spikes = sparse(spikes);

end

