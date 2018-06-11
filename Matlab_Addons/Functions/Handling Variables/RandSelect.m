function [out,skip] = RandSelect(in,num,varargin)
%% Randomly selects specified subset of indices from "in"
%
%  out = RANDSELECT(in,num)
%  [out,skip] = RANDSELECT(in,num)
%  [out,skip] = RANDSELECT(__,'NAME',value,...)
%
%  --------
%   INPUTS
%  --------
%    in     :     Vector of indices to draw randomly from for selection.
%
%   num     :     Number of elements of "in" to select randomly.
%
%  varargin :     (Optional) 'NAME', value input argument pairs
%                 -> 'N' // numel("in") (def) 
%
%                 -> 'SWITCH_THRESH' // 5 (def)
%                    [ if N > "num" * SWITCH_THRESH uses one method; 
%                      if < , a different way is faster. If running 
%                      slowly, try adjusting this. ]
%
%  --------
%   OUTPUT
%  --------
%    out    :     Random subset from "in"
%
%   skip    :     Optional, return this in cases where you don't want to
%                 use a data set with less than "num" values.
%
% By: Max Murphy  v2.0  10/24/2017  Matlab R2017a (Updated formatting,
%                                   improved efficiency using a simple
%                                   switch to update the algorithm)

%% DEFAULTS
N = numel(in);
SWITCH_THRESH = 5;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% CHECK TO BE SURE THAT num WOULD BE A RANDOM SUBSET FROM n ENTRIES
if num>N
    warning('Not a random subset.')
    skip = true;
    out = in;
    return;
else
   skip = false;
end

%% ASSIGN RANDOM OUTPUT
if N > SWITCH_THRESH * num       % If more, make random "construct" vector
   vec = randi(N,1,num);
   vec = unique(vec);
   while numel(vec) < num
      n = num - numel(vec);
      vec = [vec, randi(N,1,n)]; %#ok<AGROW>
      vec = unique(vec);
   end
   out = sort(in(vec),'ascend'); % Return in set order
else                             % If less, make random "removal" vector
   num_remove = N - num;
   vec = randi(N,1,num_remove);
   vec = unique(vec);
   while numel(vec) < num_remove
      n = num_remove - numel(vec);
      vec = [vec, randi(N,1,n)]; %#ok<AGROW>
      vec = unique(vec);
   end
   in(vec) = [];
   out = sort(in,'ascend'); % Return in set order
end

end