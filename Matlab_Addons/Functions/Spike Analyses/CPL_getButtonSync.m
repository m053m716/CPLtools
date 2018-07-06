function tEvent = CPL_getButtonSync(nFrames,frameRate,tEvent)
%% CPL_GETBUTTONSYNC  Get frame number for button pushes in the OptiTrack rec
%
%  button_frame = CPL_GETBUTTONSYNC(nFrames,frameRate,tEvent)
%
%  --------
%   INPUTS
%  --------
%   nFrames    :     Number of frames in this OptiTrack recording 
%                       (GET FROM MOTIVE -> Load Track (recording)).
%
%  frameRate   :     Framerate of camera in this recording (from Motive).
%                       [Should always be 100]
%
%  tEvent      :     Struct extracted from Intan data (from Matlab).
%
%  --------
%   OUTPUT
%  --------
%  tEvent      :  Updated to contain field with:
%                 Frame number for each button press with respect to the
%                    OptiTrack recording of interest.
%
% By: Max Murphy  v1.0  05/03/2018  Original version (R2017b)
%                 v1.1  05/15/2018  Updated to automatically save certain
%                                   information in the CPL block format.

%% DEFAULT
EVENT_ID = '_tEvent.mat';
SCORING_ID = '_Scoring.dat';

%% SIMPLE SCRIPT: FIND CLOSEST APPROXIMATE TIME TO BUTTON PUSH
frameTimes = 0:(1/frameRate):(nFrames-1)/frameRate;

button_frame = nan(size(tEvent.user.shifted));

for iT = 1:numel(tEvent.user.shifted)
   [~,button_frame(iT)] = min(abs(frameTimes - tEvent.user.shifted(iT)));
end

tEvent.button = reshape(button_frame,numel(button_frame),1);
tEvent.sync.nFrames = nFrames;
tEvent.sync.frameRate = frameRate;

fname = fullfile(tEvent.block,[tEvent.name EVENT_ID]);
if exist(fname,'file')==0
   save(fname,'tEvent','-v7.3');
   doWrite = true;
else
   btn = questdlg(sprintf('%s exists already. Overwrite?',fname),...
      'Overwrite File?','Yes','No','Yes');
   if strcmp(btn,'Yes')
      doWrite = true;
      save(fname,'tEvent','-v7.3');
   else
      doWrite = false;
   end
end

if doWrite
   fname = fullfile(tEvent.block,[tEvent.name SCORING_ID]);
   writer = CPL_BehaviorWriter('Filename',fname);
   
   step(writer,tEvent.button);
   release(writer);

end


end