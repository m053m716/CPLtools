function F = parseBadExtractions(path)
%% PARSEBADEXTRACTIONS Returns an array of blocks that didn't extract correctly
%
%  F = PARSEBADEXTRACTIONS;
%  F = PARSEBADEXTRACTIONS(path); % path to Animal Folder location
%
% By: Max Murphy  v1.0  2019-05-24

%%
if nargin < 1
   path = 'P:\Extracted_Data_To_Move\Rat\MicroD';
end

F = [];
A = dir(fullfile(path,'R*'));
tic;
for iA = 1:numel(A)
   B = dir(fullfile(A(iA).folder,A(iA).name,'B*'));
   for iB = 1:numel(B)
      fname = fullfile(B(iB).folder,B(iB).name,...
         [B(iB).name '_RawData'],[B(iB).name '_Raw_P1_Ch_000.mat']);
      
      if exist(fname,'file')==0
         F = [F; B(iB)]; %#ok<*AGROW>
      end
      
   end
end
toc;

end

