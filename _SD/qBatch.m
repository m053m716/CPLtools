%% QBATCH   Script space for doing batch runs

%% CLEAR WORKSPACE AND LOAD FILE STRUCT TO SORT
clear; clc;
load('P:\Rat\BilateralReach\Data\info.mat','block');

%% DEFAULTS
E_PRE = 2.000;
E_POST = 1.000;
FS = 24414.0625;

%% LOOP ON STRUCT AND QUEUE SPIKE DETECTION
TIC = tic;
for ii = 1:numel(block)
   try
      load(fullfile('C:\MyRepos\_M\180212 RC LFADS Multiunit\aligned',...
         [block(ii).name '_aligned.mat']),'grasp');
      b = fullfile(block(ii).folder,block(ii).name);
      info = load(fullfile(b,[block(ii).name '_EpocSnipInfo.mat']),'block');
      tFinal = CPL_time2sec(info.block.info.duration);
   catch
      fprintf(1,'\n\tBlock: %s not loaded.\n',block(ii).name);
      continue;
   end
   
   
   % This part just tries to remove epochs that are not around behavior of
   % interest; this way spike detection and more importantly CLUSTERING is
   % only done on the spikes of interest:
   ts = sort([grasp.s, grasp.f],'ascend');
   
   ts((ts - E_PRE) <= 0) = [];
   ts((ts + E_POST) >= tFinal) = [];
      
   
   t_art = [1; ts(1)-E_PRE];
   for iT = 2:numel(ts)
      t_add = [(ts(iT-1)+E_POST); (ts(iT)-E_PRE)];
      t_art = [t_art, t_add]; %#ok<AGROW>
   end
   t_add = [(ts(end)+E_POST); tFinal];
   t_art = [t_art, t_add]; %#ok<AGROW>
   
   t_art = round(t_art * FS);
   
   % And submit the job for spike detection:
   qSD('DIR',b,'ARTIFACT',t_art,'TIC',TIC,'DELETE_OLD_PATH',true);
   
end
toc;