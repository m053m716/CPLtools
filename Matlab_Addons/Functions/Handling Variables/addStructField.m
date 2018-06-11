function s = addStructField(s,varargin)
%% ADDSTRUCTFIELD   Add field(s) to an existing struct.
%
%   s = ADDSTRUCTFIELD(s,field_1,field_2,...field_K)
%
%   --------
%    INPUTS
%   --------
%      s        :   N x 1 struct array that you want to append fields to.
%
%    field_i    :   A variable that you want to add as field in struct s.
%                   Because s is in array format, you can't do this easily
%                   because The Mathworks wants everyone to use tables
%                   instead of structs or something, I don't know.
%
%   --------
%    OUTPUT
%   --------
%      s        :   Same as input struct array, but with appended fields.
%
% By: Max Murphy    v1.0    08/15/2017  Original version (R2017a)

%% GET EXISTING FIELDS
orig = fieldnames(s);
for iF = 1:numel(orig)
    eval([orig{iF} '={s.(orig{iF})};']);
    eval([orig{iF} '= reshape(' orig{iF} ',numel(' orig{iF} '),1);']);
end

%% GET ALL FIELDS
N = numel(s);
allfields = orig;
for iV = 1:numel(varargin)
    f = inputname(iV+1);
    if abs(numel(varargin{iV})-N)<eps
        allfields = [allfields; f];  %#ok<AGROW>
        eval([f '=varargin{iV};']);
        eval([f '= reshape(' f ',numel(' f '),1);']); % Get proper dim.
        eval(['temp=' f ';']);
        eval([f ' = cell(N,1);']);
        for iN = 1:N
            eval([f '{iN}=temp(iN);']);
        end
    elseif abs(size(varargin{iV},1)-N)<eps
        allfields = [allfields; f];  %#ok<AGROW>
        eval([f '=varargin{iV};']);
        eval(['temp=' f ';']);
        eval([f ' = cell(N,1);']);
        for iN = 1:N
            eval([f '{iN}=temp(iN,:);']);
        end
    elseif abs(size(varargin{iV},2)-N)<eps
        allfields = [allfields; f]; %#ok<AGROW>
        eval([f '=varargin{iV};']);
        eval(['temp=' f ';']);
        eval([f ' = cell(N,1);']);
        for iN = 1:N
            eval([f '{iN}=temp(:,iN).'';']);
        end
    end
end

%% MAKE STRUCT WITH THESE FIELDS
str = ['''' allfields{1} ''',' allfields{1}];
for iF = 2:numel(allfields)
    str = strjoin({str,...
                  ['''' allfields{iF} ''',' allfields{iF}]}...
                  ,','); 
end
eval(['s=struct(' str ');']);

end