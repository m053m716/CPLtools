function check_RHS_serial_in(serial_data,varargin)
%% CHECK_RHS_SERIAL_IN  Debug serial transmission from CounterBox to Intan
%
%  CHECK_RHS_SERIAL_IN(serial_data,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%  serial_data    :     Digital input "serial" from Intan RHS board, from
%                       experiments where CounterBox is used (device that
%                       can transmit up to 8 digital inputs in serial
%                       format to Intan, for multiplexing in manual inputs
%                       to a single digital channel).
%
%  varargin       :     (Optional) 'NAME', value pairs [listed in DEFAULT
%                                  section of code]
%
%  --------
%   OUTPUT
%  --------
%  Graphs out serial trials for sequential button presses with the proposed
%  transmitted value and actual decoded received value. The subplots have
%  the start bit colored in blue, the stop bit in magenta, and the parity
%  bit highlighted in green if it matches the serial data parity value, and
%  red if there is a mismatch.
%
% By: Max Murphy  v1.0  02/02/2018  Original version (R2017b)

%% DEFAULTS
WORD_LEN = 14;
N_REPEATS = 3;
N_DATA_BITS = 9;
N_START_BITS = 1;

N_ROUNDS = 2;
N_VALUES = 8;

FS = 30000;
BLANKING = 0.8;

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

%% GET BLANKING PERIOD LENGTH
blnk = ceil(FS * (BLANKING * 1e-3));

%% FIND START BITS TO IDENTIFY PUTATIVE "WORDS"
x = find(serial_data < 1); % Get words anywhere < 1

y = nan(size(x));
for iX = 1:numel(x)                  % Go through words sequentially,
   if ~any((y - x(iX)) > - blnk)     % making sure 0 isn't part of tx_data
      y(iX) = x(iX);
   end
end
y(isnan(y)) = [];

%% CREATE FIGURE AND PLOT

for iR = 1:N_REPEATS
   z = nan(size(y));
   for iZ = 1:numel(z)
      w = serial_data((y(iZ)+N_START_BITS):(y(iZ)+N_DATA_BITS));
      wvec = ((iR-1)*(N_DATA_BITS/N_REPEATS+1)+1): ...
             (iR*(N_DATA_BITS/N_REPEATS+1)-1);
      z(iZ) = bin2dec(num2str(w(wvec), ...
                      repmat('%u',1,N_DATA_BITS/N_REPEATS)));
   end

   figure('Name',['Serial Transmission Decoder (' num2str(iR) ')'], ...
   'Color','w',...
   'Units','Normalized',...
   'Position',[0.1 0.1 0.8 0.8]);

   for iZ = 1:numel(z)
      subplot(N_ROUNDS,N_VALUES,iZ);
      w = serial_data((y(iZ)-1):(y(iZ)+WORD_LEN));
      stem(-1:WORD_LEN,w,'filled','Marker','s','Color','k','LineWidth',2);
      xlabel('Sample','FontName','Arial');
      ylabel('Logic Signal','FontName','Arial');
      set(gca,'YTick',[0,1]); set(gca,'YTickLabel',{'LOW';'HIGH'});
      hold on;
      fill([-0.5 0.5 0.5 -0.5],[0 0 1 1],'b', ...
         'FaceColor','b','EdgeColor','none','FaceAlpha',0.3);
      
      fill([WORD_LEN-1 WORD_LEN WORD_LEN WORD_LEN-1]-0.5,...
           [0 0 1 1],'m', ...
         'FaceColor','m','EdgeColor','none','FaceAlpha',0.3);
      
      parity_addr = 2+N_START_BITS+iR*((N_DATA_BITS/N_REPEATS)+1);
      if ~(rem(sum(w(wvec+2)),2)==w(parity_addr))
         fill([parity_addr-2 parity_addr-1 parity_addr-1 parity_addr-2]-0.5,...
              [0 0 1 1],'g', ...
              'FaceColor','g','EdgeColor','none','FaceAlpha',0.5);
      else
         fill([parity_addr-2 parity_addr-1 parity_addr-1 parity_addr-2]-0.5,...
              [0 0 1 1],'r', ...
              'FaceColor','r','EdgeColor','none','FaceAlpha',0.4);
      end
      title(['Tx: ' num2str(rem(iZ-1,N_VALUES)) ' ' ...
             'Rx: ' num2str(z(iZ))], ...
             'FontName','Arial','FontSize',16);
      xlim([-2 WORD_LEN+1]); 
      ylim([-0.25 1.25]);
   end
end