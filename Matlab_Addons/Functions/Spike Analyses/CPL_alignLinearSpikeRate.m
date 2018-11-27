function [Rate,T,tvec] = CPL_alignLinearSpikeRate(rates,behaviorData,varargin)
%% CPL_ALIGNLINEARSPIKERATE   Align rates from linear estimator to behavior
%
%  Rate = CPL_ALIGNLINEARSPIKERATE(rates,behaviorData);
%  Rate = CPL_ALIGNLINEARSPIKERATE(rates,behaviorData,'NAME',value,...);
%  [Rate,T,tvec] = CPL_ALIGNLINEARSPIKERATE(___);
%
% By: Max Murphy  v1.0  11/26/2018  Original version (R2017b)


%% DEFAULTS
N_PRE = 3000; % ms (normalize period)
N_POST = 2000; % ms (normalize period)

E_PRE  = 500; % ms
E_POST = 250; % ms
FS_DEC = 200; % Hz
ALIGN = 'Grasp';

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

if ~iscell(ALIGN) % Make sure ALIGN is a cell
   ALIGN = {ALIGN};
end

%%
t = 0:(1/FS_DEC):((numel(rates{1})-1)/FS_DEC);

nTrials = size(behaviorData,1);
nSamples = numel(rates{1});

Rate = cell(size(rates,1),1);

tvec = (round(-E_PRE/1000*FS_DEC)/FS_DEC):...
       (1/FS_DEC):...
       (round(E_POST/1000*FS_DEC)/FS_DEC); % round to make sure even multiples of sampling rate
    
tNvec = (round(-N_PRE/1000*FS_DEC)/FS_DEC):...
       (1/FS_DEC):...
       (round(N_POST/1000*FS_DEC)/FS_DEC); % round to make sure even multiples of sampling rate

T = cell(1,numel(ALIGN));
for iA = 1:numel(ALIGN)
   ivec = repmat(round(tvec * FS_DEC),nTrials,1) + ...
      round(behaviorData.(ALIGN{iA})*FS_DEC);
   
   iNvec = repmat(round(tNvec * FS_DEC),nTrials,1) + ...
      round(behaviorData.(ALIGN{iA})*FS_DEC);
   
   iRemove = any(ivec < 1 ,2) | ...
      any(ivec > nSamples,2) | ...
      any(iNvec < 1 ,2) | ...
      any(iNvec > nSamples,2);
   
   ivec(iRemove,:) = [];
   iNvec(iRemove,:) = [];
   
   for iR = 1:size(rates,1)
      Rate{iR} = (abs(sqrt(rates{iR}(ivec))) - mean(mean(abs(sqrt(rates{iR}(iNvec)))))) ...
         / std(mean(abs(sqrt(rates{iR}(iNvec)))));
   end  
   T{1,iA} = ivec ./ FS_DEC;
end





end
