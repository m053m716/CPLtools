function [updated_block,next_block] = CPL_update(block,current_block_number,field)
%% CPL_UPDATE  Update "block" structure field that has been completed
%   
%  [updated_block,next_block] =
%  CPL_UPDATE(block,current_block_number,field);
%
%  Simply a way to stay organized as going through data processing and
%  cleaning.
%
%  --------
%   INPUTS
%  --------
%  block             :     Block structure that contains:
%                          -> 'folder' (i.e. the recording tank)
%                          -> 'name' (i.e. the recording block)
%                          -> 'field1...fieldN' (status fields for
%                                                different steps)
%
%  current_block     :     Current block number.
%
%  field             :     (String) name of field in "block" to update.
%  
%
%  --------
%   OUTPUT
%  --------
%  updated_block     :     Updated version of block with 'field' of
%                          current_block set to true.
%
%  next_block        :     The next block, based on status of remaining
%                          members of 'field'.
%
% By: Max Murphy  v1.0  01/26/2018     Original version (R2017b)

%% ENSURE FIELD EXISTS
if ~isfield(block,field)
   error('%s is not a field of BLOCK.',field);
end

%% SET FIELD FLAG TO TRUE
block(current_block_number).(field) = true;
updated_block = block;

%% GET NEXT BLOCK RANDOMLY
vec = find(~[block.(field)]);
next_block = RandSelect(vec,1);


end

