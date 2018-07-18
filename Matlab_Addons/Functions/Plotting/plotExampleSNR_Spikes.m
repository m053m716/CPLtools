function plotExampleSNR_Spikes(RMS_values,spikes,varargin)
%% PLOTEXAMPLESNR_SPIKES   Superimpose known spikes on different RMS noise
%
%  PLOTEXAMPLESNR_SPIKES(RMS_values,spikes);
%  PLOTEXAMPLESNR_SPIKES(RMS_values,spikes,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  RMS_values     :     Vector containing N RMS values to plot/compare.
%
%  spikes         :     Matrix with K rows corresponding to M samples from
%                       K observed spikes.
%
%  varargin       :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Exemplar plots of different RMS noise with real spikes superimposed.
%
% By: Max Murphy  v1.0  07/17/2018  Original version (R2017a)

%% DEFAULTS
T = 0:1000; % Time (ms)
XLABEL = 'Time (ms)';
YLABEL = 'Amplitude (\muV)';
YLIM = [-500 500];
XLIM = [min(T) max(T)];

FIGNAME = 'Exemplar SNR plots';
FIGPOS = [0.1 0.1 0.8 0.8];
FIGCOL = 'w';

LINECOL = 'k';
LINEWIDTH = 2.0;

TITLEFONT = 'Arial';
TITLESIZE = 16;

LABELFONT = 'Arial';
LABELSIZE = 14;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% PARSE SIZES FROM INPUT
K = size(spikes,1);
M = size(spikes,2);
N = numel(RMS_values);
nT = numel(T);

%% GET SUB-PLOT HEADERS
txt = cell(N,1);
for iN = 1:N
   txt{iN} = ['RMS ' num2str(RMS_values(iN)) '\muV'];
end

%% GENERATE WHITE NOISE VECTORS
z = cell(N,1);
for iN = 1:N
   z{iN} = randn(1,nT) * RMS_values(iN);
end

%% GET INDEXES FOR SUPERIMPOSING SPIKES
ts = randperm(nT-M,K);

%% ADD IN SPIKES
for iN = 1:N
   for iK = 1:K
      vec = (ts(iK)-M+1):ts(iK);
      z{iN}(vec) = z{iN}(vec) + spikes(iK,:);
   end
end

%% PLOT EVERYTHING
figure('Name',FIGNAME,...
       'Color',FIGCOL,...
       'Units','Normalized',...
       'Position',FIGPOS);
    
for iN = 1:N
   subplot(N,1,iN);
   plot(T,z{iN},'Color',LINECOL,'LineWidth',LINEWIDTH);
   title(txt{iN},'FontName',TITLEFONT,'FontSize',TITLESIZE);
   xlim(XLIM);
   ylim(YLIM);
   xlabel(XLABEL,'FontName',LABELFONT,'FontSize',LABELSIZE);
   ylabel(YLABEL,'FontName',LABELFONT,'FontSize',LABELSIZE);
end


end