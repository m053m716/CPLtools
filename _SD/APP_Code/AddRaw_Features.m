function [features,spikes] = AddRaw_Features(features,rawData,ts,pars)
%% ADDRAW_FEATURES   Append features based on raw waveform amplitude
%
%   features = ADDRAW_FEATURES(features,rawData,ts,pars)
%   [features,spikes] = ADDRAW_FEATURES(features,rawData,ts,pars)
%
%   --------
%    INPUTS
%   --------
%   features    :       N x K matrix of spike waveform featuers. N is the
%                       number of spikes, K is the number of features that
%                       each spike "snippet" has been decomposed to.
%
%   rawData     :       Raw channel data corresponding to spikes channel
%                       that was used to compute features.
%
%      ts       :       Spike times (samples)
%
%     pars      :       Parameters struct for spike detection.
%
%   --------
%    OUTPUT
%   --------
%   features    :       N x (K + k) matrix of spike waveform features. N is
%                       the number of spikes, K is the number of features
%                       that each spike "snippet" has been decomposed to,
%                       and k is the number of added features from the
%                       rawData that are appended to the feature matrix.
%
%    spikes     :       N x (M * numChannels) matrix of raw waveforms
%                       centered around the spikes.
%
% Added by: Max Murphy 13.0  12/07/2018   Per suggestion of SB, in order
%                                         to see if there are features of
%                                         interest for clustering spikes
%                                         using the raw waveform.

%% GET "SPIKES" ARRAY FOR RAWDATA AS WELL
spikes = [];
for ii = 1:numel(rawData)
   [~,x] = Build_Spike_Array(rawData{ii},ts,pars);
   if length(x) > 1
      %eliminates borders that were introduced for interpolation
      x(:,end-1:end)=[];
      x(:,1:2)=[];
   end
   
   spikes = [spikes,x]; %#ok<AGROW>
end

% Add "false" as do NOT want to interpolate the very long matrix:
rawFeatures = wave_features(spikes,pars,false);
rawFeatures = [rawFeatures, mean(spikes,2)];
rawFeatures = (rawFeatures-mean(rawFeatures))./std(rawFeatures);


features = [features, rawFeatures];

end