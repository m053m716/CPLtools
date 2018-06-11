function parsave(fname,varargin)
%% PARSAVE Parses variables to be saved
%
%   PARSAVE(fname,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%     fname     :       Full file name and path of output file to save.
%
%   varargin    :       'NAME', value input argument pairs. Should be sets
%                       of variable names and the corresponding variable to
%                       assign to that name in the saved file.
%
%   ex: parsave('test.mat','var1',var1,'var2',var2,...);
%
% Last Edit: 7/27/2017 -MM

%% PARSE VARARGIN
vars = struct;
for ii = 1:2:length(varargin)
    vars.(varargin{ii}) = varargin{ii+1};
end

%% SAVE DATA
save(fname,'-STRUCT','vars','-v7.3');
    

end