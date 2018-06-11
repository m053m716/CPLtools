function T = makeDataTable(X,varargin)
%% MAKEDATATABLE    Concatenate (small) TABLES and add info from filenames.
%
%   T = MAKEDATATABLE(X,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%      X        :       Input file structure that has directory
%                       information.
%
%   varargin    :       (Optional) 'NAME', value, input argument pairs.
%
%                       -> 'SUMMARY_ID' : (Default - '*_SpikeSummary.mat')
%                           ---------------------------------------------
%                           Change this variable to change the type of mat
%                           file that is evaluated from within the location
%                           specified by each X(ii).block. 
%
%                       -> 'DELIMITER' : (Default - '_')
%                           ---------------------------------------------
%                           If the file name is delimited by something
%                           other than underscore (in the current data
%                           block format, most should be delimited with
%                           underscore) then change this.
%
%                       -> 'VAR_NAME'
%                           ---------------------------------------------
%                           Depends on what you would like to extract. The
%                           i-th cell of VAR_NAME corresponds to the i-th
%                           [DELIMITER]-delimited string in the file name.
%                           In order to "skip" non-important file name
%                           delimited elements, specify that cell as NaN.
%                           Example:
%                           VAR_NAME = {'name'; nan; 'area'}
%                           [Filename: 'R15-17_1_RFA_SpikeSummary.mat']
%                           Would return R15-17 as an element of the
%                           variable 'name' and RFA as an element of the
%                           variable 'area'. These variables are then
%                           appended to the output table, T.
%
%                       -> 'LOAD_VARS'
%                           ---------------------------------------------
%                           Each cell in the cell array is a string
%                           containing (with correct capitalization) the
%                           name of the Table variables to load (and
%                           evaluate in that order). MUST BE TABLES. MUST
%                           CONTAIN SAME NUMBER OF ELEMENTS AS 'COLUMNS'.
%
%                       -> 'COLUMNS'
%                           ---------------------------------------------
%                           Each cell in the cell array is the column index
%                           of which table columns to include from the
%                           corresponding variable, listed in 'LOAD_VARS'.
%                           MUST CONTAIN SAME NUMBER OF ELEMENTS AS
%                           'LOAD_VARS'.
%   --------
%    OUTPUT
%   --------
%      T        :       Output table containing data from
%                       Simple_Spike_Analysis that has been concatenated
%                       and organized with other identifying variables.
%
% By: Max Murphy    v1.0    07/21/2017  Original version (R2017a)

%% DEFAULTS
% Current default: CCI analysis
VAR_NAME = {'name'; ...
            nan; ...
            'area'; ...
            'stype'; ...
            'group'; ...
            'period'; ...
            'pnum'};
       
% Current default: SIMPLE_SPIKE_ANALYSIS output
DELIMITER = '_';       
SUMMARY_ID = '*_SpikeSummary.mat';
LOAD_VARS = {'D'; ...
             'SPK'};
COLUMNS = {[3,4,5,6,7,8];
           [1,3]};


%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% INITIATE VARIABLES
vec = [];
for iV = 1:numel(VAR_NAME)
    if ~any(isnan(VAR_NAME{iV}))
        vec = [vec, iV]; %#ok<AGROW>
    end
end

for iV = vec
    eval([VAR_NAME{iV} '=[];']);
end

%% LOOP THROUGH AND GET SPIKE SUMMARY INFO
T = [];
for iX = 1:numel(X)
    F = dir(fullfile(X(iX).block,SUMMARY_ID));
    for iF = 1:numel(F)
        % Parse additional info from file name
        s = strsplit(F(iF).name,'_');
        for iV = vec
            eval([VAR_NAME{iV} '= s(iV);']);
        end
        
        % Add relevant info from file data table
        t = [];
        for iV = 1:numel(LOAD_VARS)
            load(fullfile(F(iF).folder,F(iF).name),LOAD_VARS{iV});
            eval(['t=[t,' LOAD_VARS{iV} '(:,COLUMNS{iV})];']);
        end
        
        if isempty(t)
            continue
        else
            n = size(t,1);
            for iV = vec
                eval([VAR_NAME{iV} '=repmat(' VAR_NAME{iV} ',n,1);']);
                eval(['t=[t, table(' VAR_NAME{iV} ')];']);
            end
            T = [T; t]; %#ok<AGROW>
        end
    end    
end

end