function S = BandPower(L,varargin)
%% BANDPOWER Gets power for LFP bands extracted using SIMPLE_LFP_ANALYSIS
%
%   S = BANDPOWER(L,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%      L        :       Table from SIMPLE_LFP_ANALYSIS
%
%   --------
%    OUTPUT
%   --------
%      S        :       Table containing band power info for all extracted
%                       raw data channels for a given block.
%
% By: Max Murphy    v1.0    06/14/2017  Original version (R2017a)
%   See also: SIMPLE_LFP_ANALYSIS

%% DEFAULTS
BAND_INDEX = [2,3];         % Indices that tell the actual bandpass range

%% PARSE INPUT
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% EXTRACT DUPLICATE VARIABLES FOR OUTPUT TABLE
nBands = size(L,1);
nChans = size(L.f{1},1);

Band = L.Band;
FS = L.FS;
FS_DEC = L.FS_DEC;

%% EXTRACT RELEVANT INFORMATION
BandRange = cell(nBands,1);
f = cell(nBands,1);
s = cell(nBands,1);
Pavg = cell(nBands,1);
fprintf(1,'\tComputing relevant band power info for %s',L.Block{1});
for iB = 1:nBands
    fprintf(1,' . ');
    BandRange{iB} = L.BandPars{iB}(BAND_INDEX);
    
    f{iB} = L.f{iB}(L.f{iB}(1,:) >= BandRange{iB}(1) &...
                    L.f{iB}(1,:) <= BandRange{iB}(2));
    s{iB} = cell(nChans,1);
    Pavg{iB} = nan(nChans,1);
    
    for iCh = 1:nChans                           
        s{iB}{iCh,1} = L.s{iB}{iCh}(L.f{iB}(iCh,:) >= BandRange{iB}(1) &...
                                    L.f{iB}(iCh,:) <= BandRange{iB}(2),:);

        Pavg{iB}(iCh,1) = mean(mean(abs(s{iB}{iCh,1})));

    end
end
fprintf(1,'complete.\n');

%% ASSIGN OUTPUT
S = table(Band,Pavg,f,FS,FS_DEC,BandRange);

end