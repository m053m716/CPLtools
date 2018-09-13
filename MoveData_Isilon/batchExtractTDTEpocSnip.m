function batchExtractTDTEpocSnip(tankPath,varargin)
%% BATCHEXTRACTTDTEPOCSNIP    Batch extract all TDT epocs in TANK
%
%  BATCHEXTRACTTDTEPOCSNIP(tankPath);
%  BATCHEXTRACTTDTEPOCSNIP(tankPath,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  tankPath    :  (Default: 'P:\Extracted_Data_To_Move\Rat\TDTRat')
%                 Directory that contains animal folders, each of which
%                 contain blocks. This will run a loop that extracts
%                 pertinent digital stream information from epoc or snips
%                 files.
%
%  varargin    :  (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Saves more files in the _Digital sub-folder of each block for which the
%  extraction is possible.
%
% By: Max Murphy  v1.0   08/30/2018  Original version (R2017b)

%% DEFAULTS
% Batch parameters
ANIMAL_ID = 'R*';
DEF_TANK = 'P:\Extracted_Data_To_Move\Rat\TDTRat';

% For extractTDTEpocSnip
IN_ID = '_EpocSnipInfo.mat';
EXCLUDED_EPOCS = {'Tick'};
DB_TIME = 0.25;         % HIGH time (seconds)
OUT_DIR = '_Digital';
FS = 24414.0625;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if nargin < 1
   tankPath = DEF_TANK;
end


%% GET ALL ANIMAL NAMES
A = dir(fullfile(tankPath,ANIMAL_ID));
tic;
h = waitbar(0,'Please wait, extracting epoc info...');
for iA = 1:numel(A)
   B = dir(fullfile(A(iA).folder,A(iA).name,[A(iA).name '*']));
   for iB = 1:numel(B)
      extractTDTEpocSnip(B(iB),...
         'IN_ID',IN_ID,...
         'EXCLUDED_EPOCS',EXCLUDED_EPOCS,...
         'DB_TIME',DB_TIME,...
         'OUT_DIR',OUT_DIR,...
         'FS',FS,...
         'DEF_TANK',DEF_TANK);         
   end   
   waitbar(iA/numel(A));
end
delete(h);
toc;

end