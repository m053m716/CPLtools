%% EXTRACTINTAN_SD  Script for extracting and then doing SD on an animal

%% CHANGE HERE
RAT_NAME = 'R19-85';

%% RUN
adHocExtract_Intan('DEF_DIR',fullfile('R:\Rat\Intan',RAT_NAME));
F = dir(['P:\Extracted_Data_To_Move\Rat\Intan\' RAT_NAME filesep RAT_NAME '*']);
cd('C:\MyRepos\shared\CPLtools\_SD');
for iF = 1:numel(F)
   qSD('DIR',fullfile(F(iF).folder,F(iF).name),...
      'CLUSTER_LIST',{'CPLMJS','CPLMJS2','CPLMJS3'},...
      'DO_AUTO_CLUSTERING',false);
end