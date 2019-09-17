clear; clc;
% File associated with TRACKVIDEOSCORING.M
UPDATE_FNAME = fullfile('C:\MyRepos\shared\rc-proj\videoAnalyses','RC-BehaviorData-Update.mat');

% Get the blocks and corresponding indices to extract
load(UPDATE_FNAME,'block','bIdx','prevExtracted_bIdx');
vec = (prevExtracted_bIdx):(bIdx-1);
if numel(vec) > 0
   qBatch('getRC_ts',block(vec));
end

% Update for the next batch to be extracted
prevExtracted_bIdx = bIdx;
save(UPDATE_FNAME,'prevExtracted_bIdx','-append');
