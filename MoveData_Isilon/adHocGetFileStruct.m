function files_in = adHocGetFileStruct(pname)
%% ADHOCGETFILESTRUCT   Gets file structure for moving/extraction
%
%  files_in = ADHOCGETFILESTRUCT();
%  files_in = ADHOCGETFILESTRUCT(pname);
%
%  --------
%   OUTPUT
%  --------
%  files_in    :     Cell array corresponding to a single block to
%                       re-extract.
%
% By: Max Murphy  v1.0  2019-03-29  Original version (R2017a)

%%
if nargin < 1
   pname = uigetdir('P:\Extracted_Data_To_Move\Rat\MicroD',...
      'Select Extracted BLOCK folder');
end

if pname == 0
   files_in = [];
   disp('No selection made. Script canceled.');
   return;
else
   pname = strsplit(pname,filesep);
   files_in = cell(1,3);
   files_in{1} = pname{end-3};
   files_in{2} = pname{end-2};
   files_in{3} = strjoin(pname((end-1):end),'_');
end

end