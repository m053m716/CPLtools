function t = ElapsedTime(InputTic)
%% ELAPSEDTIME  Give time elapsed in hours, minutes, and seconds.
%
%   t = ELAPSEDTIME(InputTic)
%
%   --------
%    INPUTS
%   --------
%   InputTic        :       Input tic time value.
%
%   --------
%    OUTPUT
%   --------
%      t            :       Output struct containing the fields
%                           -hrs    : Number of hours elapsed
%                           -mins   : Number of minutes elapsed
%                           -secs   : Number of seconds elapsed
%                           -timestamp: The datetime of when function was
%                                       called.
%
%   Also reads out the time in hours, minutes, and seconds that has elapsed
%   since InputTic (displayed in command window).
%
% By: Max Murphy    v1.2    02/27/2017  Fixed bug that was not displaying
%                                       minutes correctly. Added
%                                       "timestamp" field to output.
%                   v1.1    01/30/2017  Fixed singular detection using
%                                       round and tolerance for matching,
%                                       rather than an exact match with
%                                       floating precision values.
%                   v1.0    01/29/2017  Original Version

%% Get elapsed time
nSec = toc(InputTic);
t = sec2time(nSec);

%% Read elapsed time in hours, minutes, seconds to command window
fprintf(1, '-----------------------------\n');
fprintf(1, '%4.0f hour%s,\n', t.hrs, plural(t.hrs));
fprintf(1, '%4.0f minute%s,\n', t.mins, plural(t.mins));
fprintf(1, '%4.1f second%s.\n', t.secs, plural(t.secs));
fprintf(1, '-----------------------------\n');

   function s = plural(n)
      %% PLURAL Utility function to optionally pluralize words.
      %
      %   s = plural(n)
      % DEFAULTS
      TOL = eps;
      % DETERMINE IF SINGULAR RETURN '' ELSE RETURN 'S'
      if (abs(round(n)-1) < TOL)
         s = '';
      else
         s = 's';
      end
   end

   function t = sec2time(nSeconds)
      %% SEC2TIME   Convert a time string or char into a double of seconds
      %
      %  t= TIME2SEC(nSeconds);
      %
      %  --------
      %   INPUTS
      %  --------
      %  nSeconds       :     (Double) Number of seconds for a given duration
      %                                time string or character.
      %
      %  --------
      %   OUTPUT
      %  --------
      %     t           :     (Optional) Output struct with fields containing
      %                             information in numeric format.
      %
      % By: Max Murphy  v1.0  06/29/2018  Original version (R2017b)
      
      %% DEFAULTS
      SEC_PER_HR = 3600;
      SEC_PER_MIN = 60;
      
      TS_FORMAT = 'uuuu-MM-dd_HHmmss';
      
      t = struct;
      x = nSeconds;
      t.hrs             = floor(x/SEC_PER_HR);
      x = nSeconds - SEC_PER_HR*t.hrs;
      t.mins            = floor(x/SEC_PER_MIN);
      y = x - SEC_PER_MIN*t.mins;
      t.secs            = y;
      
      %% Get time of "occurrence"
      timestamp = datetime;
      timestamp.Format = TS_FORMAT;
      t.timestamp = timestamp;
      
      timeString = sprintf('%02g:%02g:%02.4g',t.hrs,t.mins,t.secs);
      
   end

end