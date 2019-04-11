function adHocExtract_MicroD(pname)
%% ADHOCEXTRACT_MICROD   Ad hoc code to extract MicroD data
%
%  ADHOCEXTRACT_MICROD();
%  ADHOCEXTRACT_MICROD(pname);
%
%  pname : Char or cell array of char to path of PROCESSED data block.
%
% By: Max Murphy  v1.0  2019-03-29  Original version (R2017a)

%% GET INPUTS
if nargin > 0
   if iscell(pname)
      for ii = 1:numel(pname)
         adHocExtract_MicroD(pname{ii});
      end
      return;
   end
else
   p = uigetdir('P:\Extracted_Data_To_Move\Rat\MicroD',...
      'Choose ANIMAL folder for selection of blocks');
   
   if p == 0
      disp('No ANIMAL chosen. Script aborted.');
      return;
   end
   
   F = dir(p);
   F = F(3:end); % Remove '.' and '..'
   
   ani = strsplit(p,filesep);
   ani = ani{end};
   strPrompt = sprintf('Select files to extract (%s):',ani);

   ind = listdlg('PromptString',strPrompt,...
               'SelectionMode','multiple',...
               'ListString',{F.name}.');
            
   if isempty(ind)
      disp('No BLOCKS selected. Script aborted.');
      return;
   end
   pname = cell(numel(ind),1);
   for ii = 1:numel(ind)
      pname{ii} = fullfile(F(ind(ii)).folder,F(ind(ii)).name);
   end
   
   adHocExtract_MicroD(pname);
   return;
end


%%
addpath('MicroD');
files_in = adHocGetFileStruct(pname);
MicroDExtraction(files_in);


end