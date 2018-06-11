function data_ART = Remove_Artifact_Periods(data,pars)
%% REMOVE_ARTIFACT_PERIODS  Remove pre-defined artifact periods.
%
%   data_ART = REMOVE_ARTIFACT_PERIODS(data,pars)
%
%   --------
%    INPUTS
%   --------
%     data      :       1 x N vector of sample data
%
%     pars      :       Parameter structure from SPIKEDETECTCLUSTER.
%                       Contains the field 'ARTIFACT' which is a 2 x K
%                       matrix of sample indexes, with the top row
%                       containing the start and bottom row containing the
%                       stop index for epochs to be blanked.
%
%   --------
%    OUTPUT
%   --------
%   data_ART    :       data, with the pre-specified epochs in
%                       pars.ARTIFACT blanked (set to zero).
%
% By: Max Murphy    v1.0    08/01/2017  Original version (R2017a)

%% LOOP AND CREATE BLANKING INDEX
iblank = [];
for k = 1:size(pars.ARTIFACT,2)
    iblank = [iblank, pars.ARTIFACT(1,k):pars.ARTIFACT(2,k)];
end

%% SET ARTIFACT PERIODS TO ZERO
data_ART = data;
data_ART(iblank) = 0;

end