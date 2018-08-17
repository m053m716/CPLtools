function screenChannels(F,varargin)
%% SCREENCHANNELS    Loop and screen filtered traces for a recording set
%
%  SCREENCHANNELS(F)
%  SCREENCHANNELS(F,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     F        :     Struct obtained by calling 'dir' function on a
%                    directory that contains a set of recording blocks of
%                    interest. Should contain all the recording blocks that
%                    you want to remove the same probe number and channel
%                    number from.
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Pauses on figures of channels before closing them, so you can get an
%  idea of which channels should be removed from a given dataset. Figures
%  are saved with 'TAG' optional parameter appended to them, in the
%  recording BLOCK folder.
%
% By: Max Murphy  v1.0  08/17/2018  Original version (R2017a)

%% DEFAULTS
PLOT_TYPE = 'Filtered'; % ('RawData' // 'Filtered' // 'FiltCAR')
PAUSE_TIMER = 2; % Seconds

LEN = 0.25;
OFFSET = 200;
TAG = 'Channel_Screening';


%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%%
for iF = 1:numel(F)
   DIR = fullfile(F(iF).folder,F(iF).name,[F(iF).name '_' PLOT_TYPE]);
   try
      plotChannels('DIR',DIR,'OFFSET',OFFSET,'LEN',LEN,'TAG',TAG,...
         'CHECK_FOR_SPIKES',false);
      pause(PAUSE_TIMER);
      delete(gcf);
   catch
      disp(['Unable to plot channels for ' F(iF).name]);
      delete(gcf);
   end
end

end