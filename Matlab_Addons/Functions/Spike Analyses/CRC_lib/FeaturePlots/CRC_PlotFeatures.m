function CRC_PlotFeatures(obj)
%% CRC_PLOTFEATURES  Plot cluster features in CRC UI in 3D and 2D.

% Loop through each subset of 3 features
ch = obj.Data.UI.ch;
aux = obj.Data.spk.feat{ch};

% Get TIME binning vector for plotting features vs time (mins)
if issparse(obj.Data.spk.peak_train)
   imax = numel(obj.Data.spk.peak_train{ch});
   iTs = find(obj.Data.spk.peak_train{ch});
else
   imax = max(obj.Data.spk.peak_train{ch});
   iTs = obj.Data.spk.peak_train{ch};
end
tmax = imax/obj.Data.spk.fs(ch)/60;
ts = iTs./obj.Data.spk.fs(ch)./60;
   
cla(obj.Features3D);
cla(obj.Features2D);

% Get pair of features to plot
feat_ind = obj.Data.featcomb(obj.Data.feat.this,:);
rsel = false(size(obj.Data.spk.include.cur{ch}));

rsel(randi(numel(rsel),1,...
   min(obj.Data.NFEAT_PLOT_POINTS,numel(rsel))))=true;


for iC = 1:obj.Data.NCLUS_MAX
   if obj.Data.spk.nfeat(ch) < max(feat_ind)
      continue
   end
   
   if obj.VisibleFeatures{iC}.UserData
      if obj.Data.NFEAT_PLOT_POINTS <= sum(rsel & ...
            obj.Data.cl.num.class.cur{ch}==iC)
         fi = obj.Data.cl.num.class.cur{ch}==iC & ...
            obj.Data.spk.include.cur{ch} & ...
            rsel;
      else
         fi = obj.Data.cl.num.class.cur{ch}==iC & ...
            obj.Data.spk.include.cur{ch};
      end
   else
      fi = false(size(obj.Data.cl.num.class.cur{ch}));
   end
   
   X = aux(fi, feat_ind);
   if sum(fi) > obj.Data.MINSPIKES
      if iC > 1
         scatter3(obj.Features3D, ...
            aux(fi,feat_ind(1)), ...
            aux(fi,feat_ind(2)), ...
            ts(fi), ...
            5, 'filled',... % (size; filled markers)
            'MarkerFaceColor',obj.Data.COLS{iC},...
            'MarkerEdgeColor','none', ...
            'Marker','o',...
            'UserData',[obj.Data.cl.num.assign.cur{ch}(iC),iC]);

         scatter(obj.Features2D,...
            aux(fi,feat_ind(1)),...
            aux(fi,feat_ind(2)),...
            5, 'filled',...
            'MarkerFaceColor',obj.Data.COLS{iC},...
            'MarkerEdgeColor','none',...
            'Marker','o');
      else
         scatter3(obj.Features3D, ...
            aux(fi,feat_ind(1)), ...
            aux(fi,feat_ind(2)), ...
            ts(fi), ...
            5, 'filled',... % (size; filled markers)
            'MarkerFaceColor',[0.15 0.15 0.15],...
            'MarkerEdgeColor','none', ...
            'Marker','o',...
            'UserData',[obj.Data.cl.num.assign.cur{ch}(iC),iC]);

         scatter(obj.Features2D,...
            aux(fi,feat_ind(1)),...
            aux(fi,feat_ind(2)),...
            5, 'filled',...
            'MarkerFaceColor',[0.15 0.15 0.15],...
            'MarkerEdgeColor','none',...
            'Marker','o');
      end
   end
   
   % Add cluster cylinder if "tick" is enabled
   if (~isinf(obj.Data.cl.num.rad{ch}(iC)) && ...
         sum(obj.Data.cl.num.class.in{ch}==iC)>...
         obj.Data.MINSPIKES)
      [X,Y,Z] = CRC_DrawCylinder(obj,ch,iC,feat_ind(1),...
         feat_ind(2),...
         obj.Data.NPOINTS/32);
      
      if iC > 1
         fill3(obj.Features3D, ...
            X,Y,Z,obj.Data.COLS{iC},...
            'FaceColor',obj.Data.COLS{iC},...
            'EdgeColor','none',...
            'FaceAlpha',0.2);
      else
         fill3(obj.Features3D, ...
            X,Y,Z,obj.Data.COLS{iC},...
            'FaceColor',[0.15 0.15 0.15],...
            'EdgeColor','none',...
            'FaceAlpha',0.2);
      end
      
%       
%       [X,Y] = CRC_DrawCircle(obj,ch,iC,feat_ind(1),...
%          feat_ind(2),...
%          obj.Data.NPOINTS/32);
%       
%       fill(obj.Features2D, ...
%          X,Y,obj.Data.COLS{iC},...
%          'FaceColor',obj.Data.COLS{iC},...
%          'EdgeColor','none',...
%          'FaceAlpha',0.2);
   end
end

CRC_CountExclusions(obj,ch);
CRC_ResetFeatureAxes(obj);

end