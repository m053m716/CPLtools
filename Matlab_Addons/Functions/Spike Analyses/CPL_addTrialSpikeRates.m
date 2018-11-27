function snips = CPL_addTrialSpikeRates(snips,rates,behaviorData,varargin)
%% CPL_ADDTRIALSPIKERATES  Add trial-aligned spike rates to "snips" table
%
%  snips = CPL_ADDTRIALSPIKERATES(snips,rates);
%  snips = CPL_ADDTRIALSPIKERATES(snips,rates,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%   snips      :     Table from CPL_GETTRIALWAVEFORMS that has various
%                    filtered waveforms relative to trial alignment.
%
%   rates      :     Cell array from CPL_PLOTSPIKERATE that has each
%                    element as a different channel from a given recording.
%                    Should have same number of rows as snips.
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%    snips     :     Same as input table, but now has a variable "Rate"
%                    appended, which is taken from spike rate around
%                    behavior.
%
% By: Max Murphy  v1.0  11/26/2018  Original version (R2017b)

%% DEFAULTS
E_PRE =  500; % ms
E_POST = 250; % ms

FS_DEC = 200; % Hz

%% PARSE VARARGIN

Rate = CPL_alignLinearSpikeRate(rates,behaviorData,'E_PRE',E_PRE,...
   'E_POST',E_POST,...
   'FS_DEC',FS_DEC);


end