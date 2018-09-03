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
ANIMAL_ID = 'R*';
IN_ID = '_EpocSnipInfo.mat';
EXCLUDED_EPOCS = {'Tick'};
DB_TIME = 0.25;         % HIGH time (seconds)

OUT_DIR = '_Digital';
FS = 24414.0625;
DEF_TANK = 'P:\Extracted_Data_To_Move\Rat\TDTRat';

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
      name = fullfile(B(iB).folder,B(iB).name);
      infile = fullfile(name,[B(iB).name IN_ID]);
      if exist(infile,'file')==0
         fprintf(1,'%s skipped.\n',B(iB).name);
         continue;
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
         save(fullfile(name,[B(iB).name OUT_DIR],[B(iB).name '_' ...
            etype{iE} '.mat']),'data','fs','-v7.3');
      end
         
   end   
   waitbar(iA/numel(A));
end
delete(h);
toc;

end