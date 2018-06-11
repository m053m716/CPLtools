function prb_template = import_klusta_prb(fname,varargin)
%IMPORT_KLUSTA_PRB  Read parameters from defaults prb file
%
%  prb_template = import_klusta_prb(fname,'NAME',value,...);
%
% By: Max Murphy  v1.0  01/03/2018  Original version (R2017b)

%% DEFAULTS
DELIM = {''};
FORMATSPEC = '%s%[^\n\r]';
STARTROW = 0;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% Open the text file.
fileID = fopen(fname,'r');

%% Read columns of data according to the format.
textscan(fileID, '%[^\n\r]', STARTROW, ...
   'ReturnOnError', false);
dataArray = textscan(fileID, FORMATSPEC, inf,...
   'Delimiter', DELIM, ...
   'TextType', 'string', ...
   'ReturnOnError', false, ...
   'EndOfLine', '\r\n');

%% Close the text file.
fclose(fileID);

%% Create output variable
prb_template = [dataArray{1:end-1}];


end
