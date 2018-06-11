function [inspk,K] = wave_features(spikes,pars)
%% WAVE_FEATURES Calculates the spike features
%
%   [inspk,K] = WAVE_FEATURES(spikes,pars)
%
%   --------
%    INPUTS
%   --------
%    spikes     :       N x M matrix of putative spike waveforms. N is the
%                       number of spikes, M is the number of samples in
%                       each spike "snippet."
%
%     pars      :       Parameters structure from SPIKEDETECTCLUSTER.
%
%   --------
%    OUTPUT
%   --------
%     inspk     :       N x K matrix of spike features to be input to the
%                       SPC algorithm. N is the number of spikes, K is the
%                       user-defined number of features (which depends on
%                       the feature-extraction algorithm selected).
%
%      K        :       Number of features extrated.
%
% Modified by: Max Murphy v2.0  08/03/2017 Added 'ica' and 'mix' options,
%                                          added K as an output for
%                                          convenience.
%                         v1.1  04/07/2017 Changed PRINCOMP to PCA (LINE
%                                          61). Cleaned up syntax and
%                                          removed unused variables. Added
%                                          documentation.

%% GET VARIABLES
N =size(spikes,1);   % # spikes
M =size(spikes,2);   % # samples per spike

%% CALCULATES FEATURES
switch pars.FEAT
    case 'wav' % Currently the best option [8/11/2017 - MM]
        K = pars.NINPUT;  
        cc=zeros(N,M);
        for i=1:N  % Wavelet decomposition (been using 3 scales, 'bior1.3')
            [c,~]=wavedec(spikes(i,:), ...
                          pars.NSCALES, ...
                          pars.WAVELET);
            cc(i,1:M)=c(1:M);
        end

        % SORT BY LOWEST KURTOSIS
        aux = []; 
        for ii = 1:M
            if sum(abs(cc(:,ii))<eps)<0.1*size(cc,1)
                aux = [aux, cc(:,ii)];
            end
        end
        
        R = corrcov(cov(aux)); % Get correlation matrix
        ikeep = true(1,size(R,1));
        for ii = 1:size(R,1)
            for ij = ii+1:size(R,2)
                ikeep(ii) = abs(R(ii,ij))<0.9; % Remove highly-correlated 
                if ~ikeep(ii)                  % features.
                    break
                end
            end
        end
        aux = aux(:,ikeep);   
        
        % Make sure that with removal, there are enough features (so it
        % doesn't break the code).
        if size(aux,2) >= K
            [~, ind_kur] = sort(kurtosis(aux),'ascend');
            coeff = ind_kur(1:K);
            cc = aux;
        else
            [~,ind_kur] = sort(kurtosis(cc),'ascend');
            coeff = ind_kur(1:K);
        end
        
    case 'pca' % Top K PCA features 
        [~,cc] = pca(spikes);
        coeff=1:pars.NINPUT;
        
    case 'ica' % Kurtosis-based ICA method
        K = 3;
        Z = fastICA(spikes.',K);
        cc = Z.';
        coeff = 1:K;
        
    case 'mix' % Combine peak-width, p2pamp, ICAs
        K = 4;
        spikes_interp = interp1((0:(size(spikes,2)-1))/pars.FS, ...
               spikes.', ...
               linspace(0,(size(spikes,2)-1)/pars.FS, ...
               pars.N_INTERP_SAMPLES));
           
        spikes_interp = spikes_interp.';
        
        [amax,imax] = max(spikes_interp,[],2);
        [amin,imin] = min(spikes_interp,[],2);
        Z = fastICA(spikes_interp.',2);
        cc = [amax - amin,imax-imin,Z.'];
        coeff = 1:K;
end

%% CREATES INPUT MATRIX FOR SPC
inspk=zeros(N,K);
for i=1:N
    for j=1:K
        inspk(i,j)=cc(i,coeff(j));
    end
end

end

