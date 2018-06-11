function C = countUnits(varargin)
%% COUNTUNITS   Count the total # units included/excluded.
%
%   C = COUNTUNITS('NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%   varargin    :   (Optional) 'NAME', value input argument pairs.
%
%       ->  'DIR' // (Default: none) If not specified, a UI is provided for
%                    selecting the correct path. Otherwise, specify this as
%                    the path to the _Clusters or _Sorted folder.
%
%       ->  'DELIM' // (Default: '_') Delimiter for parsing file names.
%
%       ->  'DEBUG' // (Default: false) Set to true to export object handle
%                       with all parameters used.
%
%       -> 'SAVE'   //  (Default: false) Set to true to force save even if
%                       there is an output specified.
%
%       -> 'OUT_ID' // (Default: '_UnitInclusionData.mat') Can be changed
%                       to alter the tag that is appended to the saved
%                       file.
%
%   --------
%    OUTPUT
%   --------
%       C       :   Matlab table containing counts of detected, clustered,
%                   and included units for a given recording. If no output
%                   is specified, this is saved in the file appended by
%                   '_UnitInclusionData.mat' in the specified block.
%
% By: Max Murphy    v1.0    08/09/2017  Original version (R2017a)
%   See also: COMBRESTRICTCLUSTERS, QSD, SPIKEDETECTCLUSTER

%% DEFAULTS
defs = struct; 

% paths info
defs.CLUST_ID = 'Clusters';
defs.SPIKE_ID = 'Spikes';
defs.SORT_ID  = 'Sorted';
defs.F_ID = '*ptrain*.mat';
defs.ART_ID = 'Artifact';
defs.GOOD_ID = 'Good';
defs.DEF_DIR  = 'P:\Rat\tDCS';
defs.DELIM = '_';
defs.OUT_ID = '_UnitInclusionData.mat';

% other options
defs.DEBUG = false;
defs.SAVE = false;

%% PARSE VARARGIN
p = struct;

for iV = 1:2:numel(varargin)
    defs.(upper(varargin{iV})) = varargin{iV+1};
end

p.path.DEF_DIR = defs.DEF_DIR;
p.path.DELIM = defs.DELIM;
p.path.CLUST_ID = defs.CLUST_ID;
p.path.SPIKE_ID = defs.SPIKE_ID;
p.path.SORT_ID = defs.SORT_ID;
p.path.F_ID = defs.F_ID;
p.path.ART_ID = defs.ART_ID;
p.path.GOOD_ID = defs.GOOD_ID;
p.path.OUT_ID = defs.OUT_ID;

p.opts.DEBUG = defs.DEBUG;
p.opts.SAVE = defs.SAVE;

%% GET DIRECTORY INFO
if isfield(defs,'DIR')==0
    str = sprintf('Select %s or %s directory',...
                  p.path.CLUST_ID,...
                  p.path.SORT_ID);
    p.path.DIR = uigetdir(p.path.DEF_DIR,str);
else
    p.path.DIR = defs.DIR;
end

%% MATCH DIRECTORY TYPE
p.path.finfo = strsplit(p.path.DIR,filesep);
p.path.block = strjoin(p.path.finfo(1:end-1),filesep);
p.path.finfo = strsplit(p.path.finfo{end},p.path.DELIM);
p.path.car = strcmp(p.path.finfo{end-1},'CAR');
p.path.sd = p.path.finfo{end-(2+p.path.car)};
p.path.sc = p.path.finfo{end-(1+p.path.car)};
p.path.name = strjoin(p.path.finfo(1:(end-(3+p.path.car))),p.path.DELIM);
if p.path.car
    p.path.SPK = fullfile(p.path.block,...
         strjoin([{p.path.name},{p.path.sd}, ...
        {'CAR'},{p.path.SPIKE_ID}],p.path.DELIM));
else
    p.path.SPK = fullfile(p.path.block,...
        strjoin([{p.path.name},{p.path.sd},...
        {p.path.SPIKE_ID}],p.path.DELIM));
end

switch(p.path.finfo{end})
    case p.path.CLUST_ID
        p = countClustersUnits(p);
    case p.path.SORT_ID
        p = countSortedUnits(p);
    otherwise
        error('Invalid directory. Must end in %s or %s.',...
            p.path.CLUST_ID,p.path.SORT_ID);
end

Status = [repmat({'inc'},numel(p.data.INC),1); ...
          repmat({'clu'},numel(p.data.CLU),1); ...
          repmat({'det'},numel(p.data.DET),1)];
p.data = [p.data.INC; p.data.CLU; p.data.DET];
ntotal = numel(p.data);
Name = strsplit(p.path.name,p.path.DELIM);
Name = repmat(Name{1},ntotal,1);

File = cell(ntotal,1);
NumSpikes = nan(ntotal,1);
Duration = nan(ntotal,1);
Rate = nan(ntotal,1);
Regularity = nan(ntotal,1);

for iN = 1:ntotal
    File{iN} = fullfile(p.data(iN).folder,p.data(iN).name);
    temp = load(File{iN},'peak_train','pars');
    Duration(iN) = numel(temp.peak_train)/temp.pars.FS;
    NumSpikes(iN) = numel(find(temp.peak_train));
    Rate(iN) = NumSpikes(iN)/Duration(iN);
    Regularity(iN) = LvR(find(temp.peak_train)/temp.pars.FS);
end
C = table(Name,File,Status,NumSpikes,Duration,Rate,Regularity);

if (nargout<1 || p.opts.SAVE)
    save(fullfile(p.path.block,[p.path.name p.path.OUT_ID]),'C','-v7.3');
end

if p.opts.DEBUG
    mtb(p);
end

%% PERFORM PERFORM ONE OF TWO FUNCTIONS, DEPENDING ON SELECTION
    function p = countClustersUnits(p)
    %% COUNTCLUSTERSUNITS   Perform function if CLUSTERS folder selected.   
    p.data.INC = dir(fullfile(p.path.DIR,p.path.GOOD_ID,p.path.F_ID));
    p.data.CLU = [dir(fullfile(p.path.DIR,p.path.ART_ID,p.path.F_ID));...
                  p.data.INC];
    p.data.DET = dir(fullfile(p.path.SPK,p.path.F_ID));
    
    if p.opts.DEBUG
        mtb(p)
    end
    
    end

    function p = countSortedUnits(p)
    %% COUNTSORTEDUNITS     Perform function if SORTED folder selected.
    p.data.INC = dir(fullfile(p.path.DIR,p.path.F_ID));
    clu = strrep(p.path.DIR,p.path.SORT_ID,p.path.CLUST_ID);
    p.data.CLU = [dir(fullfile(clu,p.path.F_ID));...
                  dir(fullfile(clu,p.path.ART_ID,p.path.F_ID))];
    p.data.DET = dir(fullfile(p.path.SPK,p.path.F_ID));
    
    if p.opts.DEBUG
        mtb(p)
    end
        
    end
end

