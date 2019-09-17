function batch_standard_extract(F)
%% BATCH_STANDARD_EXTRACT  Extract spikes each block in file struct array F
%
%  % example:
%
%  F = dir('P:\Extracted_Data_To_Move\Rat\Intan\R19-165\R19-165*');
%  F = [F; dir('P:\Extracted_Data_To_Move\Rat\Intan\R19-166\R19-166*')];
%  batch_standard_extract(F);
%
%  --------
%   INPUTS
%  --------
%     F     :     Struct array that is returned from MATLAB built-in 'dir'
%                    command. Each 'name' entry should correspond to a
%                    BLOCK folder.
%
% By: Max Murphy  v1.0  2019-09-05  Original version (R2017a) 

%%
maintic = tic;
for iF = 1:numel(F)
   qSD('DIR',fullfile(F(iF).folder,F(iF).name),'TIC',maintic);
end
toc(maintic);
end