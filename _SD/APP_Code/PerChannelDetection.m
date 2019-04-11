function [spikedata,fs] = PerChannelDetection(p,ch,pars,paths,rawSites)
%% PERCHANNELDETECTION  Perform spike detection for each channel individually.
%
%   spikedata = PERCHANNELDETECTION(p,ch,pars,paths)
%
%   --------
%    INPUTS
%   --------
%       p           :       ID (integer) of probe.   
%
%      ch           :       ID (integer) of filtered and re-referenced
%                           single-channel stream to load.
%
%     pars          :       Parameters structure.
%
%    paths          :       Structure containing file path name info.
%
%   rawSites        :       All channels to include for "raw" spikes.
%
%   --------
%    OUTPUT
%   --------
%   spikedata       :       Struct containing 'spikes,' 'artifact,' and
%                           'peak_train' fields as described by
%                           SPIKEDETECTIONARRAY.
%
%     fs            :       Sampling frequency.
%
% See also: SPIKEDETECTIONARRAY, SPIKEDETECTCLUSTER
%   By: Max Murphy  v2.1    08/11/2017  Made naming more efficient. Removed
%                                       "extracted" input flag.
%                   v2.0    08/03/2017  Added peak prominence (pp) and peak
%                                       width (pw) as output to the save
%                                       files.
%                   v1.1    02/01/2017  Added flag for new format and
%                                       update pars.FS if the data is in
%                                       the new format.
%                   v1.0    01/30/2017  Original Version

%% LOAD FILTERED AND RE-REFERENCED MAT FILE
if nargin < 5
   rawSites = ch;
end
fs = nan;
fname = sprintf('%s%sP%d_Ch_%03d.mat',paths.N,pars.FILT_DATA,p,ch);
load(fullfile(paths.SL,paths.FF,fname));
pars.FS = fs;
if isnan(pars.FS)
    error('No sampling rate found in %s',fname);
end

%% PERFORM SCALING (IF NECESSARY)
if ~pars.PRESCALED
    data = data*1e6; %#ok<NODEF> % Convert to micro-volts
end

%% PERFORM SPIKE DETECTION
switch pars.FEAT
   case 'raw'
      rawData = cell(numel(rawSites),1);
      for ii = 1:numel(rawSites)
         fname = sprintf('%s%sP%d_Ch_%03d.mat',paths.N,pars.RAW_DATA,p,rawSites(ii));
         in = load(fullfile(paths.SL,paths.RF,fname));
         rawData{ii} = in.data;
      end
      
      [spikedata,pars] = SpikeDetectionArray(data,pars,rawData); 
   otherwise
      [spikedata,pars] = SpikeDetectionArray(data,pars); 
end


%% SAVE SPIKE DETECTION DATA FOR THIS CHANNEL
newname = sprintf('%s%sP%d_Ch_%03d.mat',paths.N,pars.SPIKE_DATA,p,ch);
parsavedata(fullfile(paths.SL,paths.PF,newname), ...
    'spikes', spikedata.spikes, ...
    'rawspikes',spikedata.rawspikes,...
    'artifact', spikedata.artifact, ...
    'peak_train',  spikedata.peak_train, ...
    'features', spikedata.features, ...
    'pw', spikedata.pw, ...
    'pp', spikedata.pp, ...
    'pars', pars)

end