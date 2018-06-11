function Vf = num_integ_voltage(Vo,a,b,dt,varargin)
%% NUM_INTEG_VOLTAGE  Numerically integrate membrane voltage
%
%   Vf = NUM_INTEG_VOLTAGE(Vo,dV,dt,'NAME',value,...)
%
%   --------
%    INPUTS
%   --------
%      Vo       :       Initial voltage condition
%
%      a        :       Constant term in linear equation for computing the
%                       change in voltage as a function of current voltage.
%
%      b        :       Coefficient for current voltage in linear equation
%                       that computes the change in voltage as a function
%                       of current voltage.
%
%      dt       :       Time step (seconds)
%
%   varargin    :       (Optional) 'NAME', value input argument pairs.
%
%                       -> ANY constant from DEFAULTS section.
%
%   --------
%    OUTPUT
%   --------
%      Vf       :       Converged equilibrium voltage.
%
% By: Max Murphy    v1.0    06/09/2017

%% DEFAULTS
DURATION = 1000; % Total time for simulation (seconds)

%% PARSE INPUT
for iV = 1:2:numel(varargin)
    eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% ITERATIVELY COMPUTE THE NUMERICAL INTEGRATION
num_iterations = DURATION / dt;

for ii = 1:num_iterations
    Vo = Vo + dV(Vo,a,b)*dt;
end

Vf = Vo;

%% FIRST-ORDER LINEAR EQUATION FOR CHANGE IN VOLTAGE
    function Vdiff = dV(Vcurr,a,b)
        Vdiff = a + b*Vcurr;
    end

end