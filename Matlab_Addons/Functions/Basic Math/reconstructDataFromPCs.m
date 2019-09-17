function data = reconstructDataFromPCs(coeff,score,mu)
%% RECONSTRUCTDATAFROMPCS  Rebuild original data from PCA results

data = score*coeff.' + repmat(mu,size(score,1),1);



end