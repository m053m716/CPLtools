function SPC_out = SpikeCluster_SPC(features,iCh,pars)
%% SPIKECLUSTER_SPC Cluster spikes using super-paramagnetic clustering (SPC). More accurate than K-means or Bayes methods, but potentially takes longer.
%
% SPC_out = SPIKECLUSTER_SPC(peak_train,artifact,spikes,pars)
%
%   --------
%    INPUTS
%   --------
%   features    :   Features to use for clustering.
%
%    iCh        :   Channel index.
%
%    pars       :   Parameters structure.
%
%   --------
%    OUTPUT
%   --------
%    SPC_out    :   Cell with computed clusters from using SPC.
%
% Adapted from Quian Quiroga et. al 2004
% By: Max Murphy    v3.0    08/11/2017  Major changes in order to make it
%                                       flow better with adapted
%                                       functionality from recent overall
%                                       changes to spike detection. Removed
%                                       useless "handles" that was
%                                       redundant with "pars" struct.
%                   v2.3    02/03/2017  Added ability to change the mother
%                                       wavelet family.
%                   v2.2    02/02/2017  Slightly modified some command
%                                       window outputs to add clarity in
%                                       the case of no spikes detected or
%                                       low cluster counts, etc.
%                   v2.1    01/30/2017  Fixed minor bug with pars. Added
%                                       iCh input to allow parfor to create
%                                       unique filenames when running on
%                                       local machine.
%                   v2.0    01/29/2017  Changed parameter handling.

%% CHECK THAT THERE ARE ENOUGH SPIKES TO RUN CLUSTER.EXE
SPC_out = struct;
ch = num2str(iCh);
pars.nspikes = size(features,1);
if pars.nspikes < pars.MIN_SPK  % Meets criteria for min number of spikes
    SPC_out.class = zeros(pars.npoints,1);
    SPC_out.clu = nan;
    SPC_out.tree = nan;
    SPC_out.temperature = nan;
    return;
end              

%% DO CLUSTERING
pars.FNAME_IN = ['tmp_data' ch];              % Input name for cluster.exe
pars.FNAME_OUT = ['data_tmp_curr' ch '.mat']; % Read-out from cluster.exe
[class,clu,tree,pars.temperature] = DoSPC(features);

%% SAVE INDIVIDUAL "CLUSTER" FILES
SPC_out = struct;
SPC_out.class = class;
SPC_out.clu = clu;
SPC_out.tree = tree;
SPC_out.pars = pars;

end