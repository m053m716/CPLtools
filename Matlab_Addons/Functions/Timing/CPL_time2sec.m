function nSeconds = CPL_time2sec(timeString)
%% CPL_TIME2SEC   Convert a time string or char into a double of seconds
%
%  nSeconds = CPL_TIME2SEC(timeString);
%
%  --------
%   INPUTS
%  --------
%  timeString     :     String or char in format 'hh:mm:ss'
%
%  --------
%   OUTPUT
%  --------
%  nSeconds       :     (Double) Number of seconds for a given duration
%                                time string or character.
%
% By: Max Murphy  v1.0  06/29/2018  Original version (R2017b)

%% PARSE STRING
t = strsplit(timeString,':');

switch numel(t)
   case 1
      hh = 0;
      mm = 0;
      ss = str2double(t{1});
   case 2
      hh = 0;
      mm = str2double(t{1});
      ss = str2double(t{2});
   case 3
      hh = str2double(t{1});
      mm = str2double(t{2});
      ss = str2double(t{3});
      
   otherwise
      error('Syntax not recognized for timeString (%s).', timeString);
end
   
nSeconds = ss + 60*mm + 3600 * hh;

end