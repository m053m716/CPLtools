function extractTDTEpocSnip(B,varargin)
%% EXTRACTTDTEPOCSNIP   Extract TDT snips/epocs to "stream" .mat format
%
%  EXTRACTTDTEPOCSNIP(B)
%
%  --------
%   INPUTS
%  --------
%     B        :     File structure with fields ('folder' and 'name') that
%                    point to the recording BLOCK (folder). 
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Saves the data stream file from epocs/snips format.
%
% By: Max Murphy v1.0   09/06/2018  Original version (R2017b)

%% DEFAULTS
IN_ID = '_EpocSnipInfo.mat';  % Filename for Epoc/Snip extracted file
EXCLUDED_EPOCS = {'Tick';'Cond';'DayN'};    % Fields to ignore
DB_TIME = 0.25;               % HIGH time (seconds)
OUT_DIR = '_Digital';         % Tag of sub-folder for output streams
FS = 24414.0625;              % TDT sample rate

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% PARSE INPUT
name = fullfile(B.folder,B.name);
infile = fullfile(name,[B.name IN_ID]);
if exist(infile,'file')==0
   fprintf(1,'No input file found. %s skipped.\n',B.name);
   return;
end

load(infile,'block');
etype = setdiff(fieldnames(block.epocs),EXCLUDED_EPOCS);

t = 0:(1/FS):CPL_time2sec(block.info.duration);
for iE = 1:numel(etype)
   x = block.epocs.(etype{iE});
   data = zeros(size(t));
   fs = FS;
   for ii = 1:numel(x.onset)
      data((t >= x.onset(ii)) & (t < (x.onset(ii) + DB_TIME))) = 1;
   end
   save(fullfile(name,[B.name OUT_DIR],[B.name '_' ...
      etype{iE} '.mat']),'data','fs','-v7.3');
end

end