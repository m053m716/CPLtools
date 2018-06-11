function cpl2klusta(varargin)
%% CPL2KLUSTA  Convert CAR data to klusta format for detection/clustering
%
%  CPL2KLUSTA('NAME',value,...)
%
%  --------
%   INPUTS
%  --------
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%  Creates a new folder in the CPL "BLOCK" that contains
%
%  -> 'BLOCK.dat' [raw data file in binary format (see klusta docs)
%       <https://github.com/klusta-team/kwiklib/wiki/Kwik-format> ]
%
%  -> 'BLOCK.prm' ["parameters" file for spike detection (see klusta docs)
%       <https://github.com/klusta-team/kwiklib/wiki/Kwik-format> ]
%
% By: Max Murphy  v1.0  01/03/2018  Original version (R2017b)

%% DEFAULTS
DIR = nan;
DEF_DIR = 'P:\Rat';
CAR_DIR = '_FilteredCAR';
CAR_ID = 'FiltCAR';

KLUSTA_DIR = '_Klusta';
KLUSTA_ID = 'Klusta';

AUTO_CHANNEL_DETECT = false;
N_CHANNELS = 16;
DTYPE = 'int16';

PRB_FILE = '2x8_shanks';
MIN_CH = [1, 1]; % Minimum channel # in files- channel "1" is 0-indexed

GAIN = 100; % This is a factor of 10 more than the .prm file for reasons
NROW = 8;
NCOL = 2;
AP = 2000;
ML = 500;

SHANKS = [1, 16; ...
          2, 15; ...
          3, 14; ...
          4, 13; ...
          5, 12; ...
          6, 11; ...
          7, 10; ...
          8, 9];

%% PARSE VARARGIN
for iV = 1:2:numel(varargin)
   eval([upper(varargin{iV}) '=varargin{iV+1};']);
end

ap = round(linspace(0,AP,NROW));
ml = round(linspace(0,ML,NCOL));

%% GET DIRECTORY INFO
if isnan(DIR)
   DIR = uigetdir(DEF_DIR,'Select recording BLOCK folder');
   if DIR == 0
      error('No selection made. Script aborted.');
   end
end

% Get name of recording (last element of BLOCK path)
name = strsplit(DIR,filesep);
name = name{numel(name)};

% Make base directory for klusta outputs
klu_dir = fullfile(DIR,[name KLUSTA_DIR]);
if exist(klu_dir,'dir')==0
   mkdir(klu_dir);
end

%% EXTRACT DATA AND REFORMAT


% Get all files in the FiltCAR folder
F = dir(fullfile(DIR,[name CAR_DIR],['*' CAR_ID '*.mat']));

% Get probe ("shank" per klusta format) and channel # for each data file
pnum = repmat('Z',numel(F),1);
chnum = repmat('Z',numel(F),3);
for iF = 1:numel(F)
   p_ind = regexp(F(iF).name,'[_][P]\d');
   ch_ind = regexp(F(iF).name,'[_][C][h][_]\d');
   ch_stop = regexp(F(iF).name,'[.][m][a][t]');
   
   pnum(iF) = F(iF).name(p_ind + 2);
   chnum(iF,:) = F(iF).name((ch_ind+4):(ch_stop-1));
end
[P,~,p_ind] = unique(pnum);

% Extract data for each probe into a cell element as a matrix
ns = nan(numel(P),1);
ch = cell(numel(P),1);
for iP = 1:numel(P)
   f = F(p_ind==iP);
   ch{iP} = str2double(cellstr(chnum(p_ind==iP,:)));
   
   % Load first channel to pre-allocate large matrix
   in = load(fullfile(f(1).folder,f(1).name),'data','fs');
   fs = in.fs;
   ns = numel(in.data);
   if AUTO_CHANNEL_DETECT || ((range(ch{iP})+1) > N_CHANNELS)
      N_CHANNELS = range(ch{iP})+1;
      X = zeros(N_CHANNELS,ns);
   else
      X = zeros(N_CHANNELS,ns);
   end
   X(ch{iP}(1),:) = in.data;
   
   % Load rest of channels
   for iF = 2:numel(f)
      in = load(fullfile(f(iF).folder,f(iF).name),'data');
      X(ch{iP}(iF),:) = in.data;
   end
   
   % Write data to a unique binary file
   pdir = fullfile(klu_dir,['P' P(iP)]);
   if exist(pdir,'dir')==0
      mkdir(pdir);
   end
   fname = fullfile(pdir,[name '_' KLUSTA_ID '_P' P(iP) '.dat']);
   fid = fopen(fname,'w');
   fwrite(fid,round(X*GAIN),DTYPE);
   fclose(fid);
end

%% GET TEMPLATE INFO
% Get template for klusta parameters file (PRM)
kp_template = import_klusta_pars;

% Get template for klusta probe file (PRB)
p = mfilename('fullpath');
p = strsplit(p,filesep);
p = strjoin(p(1:(end-1)),filesep);
prb = fullfile(p,'probes',[PRB_FILE '.prb']);
prb_template = import_klusta_prb(prb);

%% WRITE KLUSTA PRM AND PRB FILES

% Write these files uniquely for each probe in recording
for iP = 1:numel(P)
   exp = [name '_' KLUSTA_ID '_P' P(iP)];
   pdir = fullfile(klu_dir,['P' P(iP)]);
   fname = fullfile(pdir,[exp '.prm']);
   fid = fopen(fname,'w');
   fname = strrep(fname,'.prm','.prb');
   for iLine = 1:numel(kp_template)
      switch iLine
         case 1
            fwrite(fid,sprintf([char(kp_template(iLine)) '\n'],fname(1:(end-4))));
         case 2
            fwrite(fid,sprintf([char(kp_template(iLine)) '\n'],fname));
         case 5
            fwrite(fid,sprintf([char(kp_template(iLine)) '\n'],GAIN/10));
         case 6
            fwrite(fid,sprintf([char(kp_template(iLine)) '\n'],fs));
         case 7
            fwrite(fid,sprintf([char(kp_template(iLine)) '\n'],N_CHANNELS));
         case 8
            fwrite(fid,sprintf([char(kp_template(iLine)) '\n'],DTYPE));
         otherwise
            fwrite(fid,sprintf([char(kp_template(iLine)) '\n']));
      end
   end
   fclose(fid);
   
   switch PRB_FILE
      case '2x8_tdt'
         % Get list of channels
         ch_list = '[';
         ch{iP} = ch{iP} - MIN_CH(iP); % List always starts at 0
         for iCh = 1:numel(ch{iP})
            ch_list = [ch_list, num2str(ch{iP}(iCh)), ',']; %#ok<AGROW>
         end
         ch_list = [ch_list(1:end-1) ']'];
         fid = fopen(fname,'w');
         for iLine = 1:numel(prb_template)
            if iLine == 6
               fwrite(fid,sprintf([char(prb_template(iLine)) '\n'],ch_list));
            else
               fwrite(fid,sprintf([char(prb_template(iLine)) '\n']));
            end
         end
         fclose(fid);
         
      otherwise
         fid = fopen(fname,'w');
         fwrite(fid,sprintf([char(prb_template(1)) '\n']));
         for iCh = MIN_CH(iP):(MIN_CH(iP) + N_CHANNELS-1)
            for iLine = 2:(numel(prb_template)-1)
               switch iLine
                  case 3
                     fwrite(fid,sprintf([char(prb_template(iLine)) '\n'],...
                        iCh - MIN_CH(iP)));
                     
                  case 6
                     if ismember(iCh,ch{iP})
                        fwrite(fid,sprintf([char(prb_template(iLine)) '\n'],...
                           iCh - MIN_CH(iP)));
                     else
                        fwrite(fid,sprintf([char(prb_template(iLine)) '\n'],...
                           ''));
                     end
                  case 11
                     fwrite(fid,sprintf([char(prb_template(iLine)) '\n'],...
                        iCh - MIN_CH(iP),...
                        ap(any(SHANKS==iCh,2)),...
                        ml(any(SHANKS==iCh,1))));
                  case (numel(prb_template)-1)
                     if iCh < numel(ch{iP})
                        fwrite(fid,sprintf([char(prb_template(iLine)) ', \n']));
                     else
                        fwrite(fid,sprintf([char(prb_template(iLine)) '\n']));
                     end
                  otherwise
                     fwrite(fid,sprintf([char(prb_template(iLine)) '\n']));
               end
            end            
         end
         fwrite(fid,sprintf([char(prb_template(numel(prb_template))) '\n']));
         fclose(fid);
   end
end


end