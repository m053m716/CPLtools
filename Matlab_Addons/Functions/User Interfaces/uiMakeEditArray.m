function editArray = uiMakeEditArray(container,y,varargin)
%% UIMAKEEDITARRAY  Make array of edit boxes that corresponds to set of labels
%
%  editArray = UIMAKEEDITARRAY(container,y,);
%  editArray = UIMAKEEDITARRAY(container,y,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  container   :     Graphics container object (uipanel) to hold the array.
%
%     y        :     Vector of vertical positions normalized between 0 
%                    (bottom) and 1 (top).
%
%   varargin   :     (Optional) 'NAME', value input argument pairs that
%                             modify the uicontrol.
%
%  --------
%   OUTPUT
%  --------
%  editArray   :     k x 1 cell array of edit style uicontrols.
%
% By: Max Murphy  v1.0  08/30/2018   Original version (R2017b)

%% CONSTRUCT GRAPHICS ARRAY
editArray = cell(numel(y),1);

for ii = 1:numel(y)
   editArray{ii,1} = uicontrol(container,'Style','edit',...
      'Units','Normalized',...
      'Position',[0.5 y(ii) 0.475 0.15],...
      'FontName','Arial',...
      'FontSize',14,...
      'Enable','off',...
      'String','N/A',...
      'UserData',ii);
   
   % If extra arguments specified, modify them here
   for iV = 1:2:numel(varargin)
      if isproperty(editArray{ii},varargin{iV})
         set(editArray{ii},varargin{iV},varargin{iV+1});
      end
   end
   
end

end