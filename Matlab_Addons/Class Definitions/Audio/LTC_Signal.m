classdef LTC_Signal < handle
%% LTC_SIGNAL  Linear timecode signal object

   properties
      samples         % Observed signal
      samplerate      % Observed signal sampling rate
      bits            % Bits decoded from signal
      bitrate         % Average rate of bit translation
      bitnumber       % Number of each bit in frame
      bitsamples      % Samples in each bit
      frames          % Translated frames (from bits)
      framerate = 30; % Determines how bits get translated
   end
   
   methods
      function obj = LTC_Signal(x,fs)
         %% LTC_SIGNAL  Linear timecode signal object
         
         obj.samples = x;
         obj.samplerate = fs;
         
         % increase sampling rate:
         x = resample(double(x),2,1); 
         
         % clip signal:
         x(x>0.5) = 1;
         x(x<-0.5) = -1;
         
         % get "high/low" durations from signal:
         k = [];
         n = 1;
         s = 1;
         for iX = 2:numel(x)
            if abs(x(iX)-x(iX-1))<eps
               n = n + 1;
            else
               k = [k; n, s];
               s = iX;
               n = 1;
            end
         end
         k = k(k(:,1)>1,:); % Remove "transition" samples
         obj.bitsamples = k;
         
         % "translate" based on distribution
         splitpoint =(max(k(:,1))+min(k(:,1)))/2;
         
         b = [];
         iB = 1;
         while iB <= size(k,1)
            if k(iB,1) > splitpoint
               b = [b; 0];
            else
               iB = iB + 1;
               b = [b; 1];
            end
            iB = iB + 1;
         end
         obj.bits = b;
         
         % get frame "shift" from asynchronous onset
         y = conv(obj.bits - 0.5,[1 0 ones(1,12) 0 0],'same');
         [val,ind] = max(y);
         if val < 4
            error('No sync signal detected');
         end
        
         offset = ind + 8; % Account for length/2 of sync sequence
         nFrames = floor((numel(obj.bits)-offset)/80);
         nRem = rem((numel(obj.bits)-offset),80);
         obj.bitnumber = [(80-offset+1):80,repmat(1:80,1,nFrames),1:nRem];
         
         if offset > 0
            nFrames = nFrames + 1;
         end
         
         if nRem > 0
            nFrames = nFrames + 1;
         end
         
         obj.frames = cell(nFrames,1);
         obj.frames{1}.FrameNumber = 0;
         obj.frames{1}.Seconds = 0;
         obj.frames{1}.Minutes = 0;
         obj.frames{1}.Hours = 0;
         
         iframe = 1;
         ii = 1;
         while ii <= numel(obj.bitnumber)
            if ii > 1 && (abs(obj.bitnumber(ii)-1)<eps)
               iframe = iframe + 1; 
               obj.frames{iframe}.FrameNumber = 0;
               obj.frames{iframe}.Seconds = 0;
               obj.frames{iframe}.Minutes = 0;
               obj.frames{iframe}.Hours = 0;
            end
            switch obj.bitnumber(ii)
               case 1
                  obj.frames{iframe}.FrameNumber = obj.bits(ii) + ...
                     2 * obj.bits(ii+1) + 4 * obj.bits(ii + 2) ...
                     + 8 * obj.bits(ii + 3);
                  ii = ii + 4;
               case 2
                  obj.frames{iframe}.FrameNumber = 2 * obj.bits(ii) + ...
                     4 * obj.bits(ii + 1) + 8 * obj.bits(ii + 2);
                  ii = ii + 3;
               case 3
                  obj.frames{iframe}.FrameNumber = 4 * obj.bits(ii) + ...
                     8 * obj.bits(ii + 1);
                  ii = ii + 2;
               case 4
                  obj.frames{iframe}.FrameNumber = 8 * obj.bits(ii);
                  ii = ii + 1;
               case 5
                  ii = ii + 1;
               case 6
                  ii = ii + 1;
               case 7
                  ii = ii + 1;
               case 8
                  ii = ii + 1;
               case 9
                  obj.frames{iframe}.FrameNumber = ...
                     obj.frames{iframe}.FrameNumber + ...
                     10 * obj.bits(ii) + ...
                     20 * obj.bits(ii+1);
                  ii = ii + 2;
               case 10
                  obj.frames{iframe}.FrameNumber = ...
                     obj.frames{iframe}.FrameNumber + ...
                     20 * obj.bits(ii);
                  ii = ii + 1;
               case 11
                  ii = ii + 1;
               case 12
                  ii = ii + 1;
               case 13
                  ii = ii + 1;
               case 14
                  ii = ii + 1;
               case 15
                  ii = ii + 1;
               case 16
                  ii = ii + 1;
               case 17
                  obj.frames{iframe}.Seconds = obj.bits(ii) + ...
                     2 * obj.bits(ii+1) + 4 * obj.bits(ii + 2) ...
                     + 8 * obj.bits(ii + 3);
                  ii = ii + 4;
               case 18
                  obj.frames{iframe}.Seconds = 2* obj.bits(ii) + ...
                     4 * obj.bits(ii+1) + 8 * obj.bits(ii + 2);
                  ii = ii + 3;
               case 19
                  obj.frames{iframe}.Seconds = 4* obj.bits(ii) + ...
                     8 * obj.bits(ii+1);
                  ii = ii + 2;
               case 20
                  obj.frames{iframe}.Seconds = 8 * obj.bits(ii);
                  ii = ii + 1;
               case 21
                  ii = ii + 1;
               case 22
                  ii = ii + 1;
               case 23
                  ii = ii + 1;
               case 24
                  ii = ii + 1;
               case 25
                  obj.frames{iframe}.Seconds = obj.frames{iframe}.Seconds...
                     + 10 * obj.bits(ii) + 20 * obj.bits(ii+1) + ...
                     40 * obj.bits(ii+2);
                  ii = ii + 3;
               case 26
                  obj.frames{iframe}.Seconds = obj.frames{iframe}.Seconds...
                     + 20 * obj.bits(ii) + 40 * obj.bits(ii+1);
                  ii = ii + 2;
               case 27
                  obj.frames{iframe}.Seconds = obj.frames{iframe}.Seconds...
                     + 40 * obj.bits(ii);
                  ii = ii + 1;
               case 28
                  ii = ii + 1;
               case 29
                  ii = ii + 1;
               case 30
                  ii = ii + 1;
               case 31
                  ii = ii + 1;
               case 32
                  ii = ii + 1;
               case 33
                  obj.frames{iframe}.Minutes = obj.bits(ii) + ...
                     2 * obj.bits(ii+1) + 4 * obj.bits(ii + 2) ...
                     + 8 * obj.bits(ii + 3);
                  ii = ii + 4;
               case 34
                  obj.frames{iframe}.Minutes = 2* obj.bits(ii) + ...
                     4 * obj.bits(ii+1) + 8 * obj.bits(ii + 2);
                  ii = ii + 3;
               case 35
                  obj.frames{iframe}.Minutes = 4* obj.bits(ii) + ...
                     8 * obj.bits(ii+1);
                  ii = ii + 2;
               case 36
                  obj.frames{iframe}.Minutes = 8 * obj.bits(ii);
                  ii = ii + 1;
               case 37
                  ii = ii + 1;
               case 38
                  ii = ii + 1;
               case 39
                  ii = ii + 1;
               case 40
                  ii = ii + 1;
               case 41
                  obj.frames{iframe}.Minutes = obj.frames{iframe}.Minutes...
                     + 10 * obj.bits(ii) + 20 * obj.bits(ii+1) + ...
                     40 * obj.bits(ii+2);
                  ii = ii + 3;
               case 42
                  obj.frames{iframe}.Minutes = obj.frames{iframe}.Minutes...
                     + 20 * obj.bits(ii) + 40 * obj.bits(ii+1);
                  ii = ii + 2;
               case 43
                  obj.frames{iframe}.Minutes = obj.frames{iframe}.Minutes...
                     + 40 * obj.bits(ii);
                  ii = ii + 1;
               case 44
                  ii = ii + 1;
               case 45
                  ii = ii + 1;
               case 46
                  ii = ii + 1;
               case 47
                  ii = ii + 1;
               case 48
                  ii = ii + 1;
               case 49
                  obj.frames{iframe}.Hours = obj.bits(ii) + ...
                     2 * obj.bits(ii+1) + 4 * obj.bits(ii + 2) ...
                     + 8 * obj.bits(ii + 3);
                  ii = ii + 4;
               case 50
                  obj.frames{iframe}.Hours = 2* obj.bits(ii) + ...
                     4 * obj.bits(ii+1) + 8 * obj.bits(ii + 2);
                  ii = ii + 3;
               case 51
                  obj.frames{iframe}.Hours = 4* obj.bits(ii) + ...
                     8 * obj.bits(ii+1);
                  ii = ii + 2;
               case 52
                  obj.frames{iframe}.Hours = 8 * obj.bits(ii);
                  ii = ii + 1;
               case 53
                  ii = ii + 1;
               case 54
                  ii = ii + 1;
               case 55
                  ii = ii + 1;
               case 56
                  ii = ii + 1;
               case 57
                  obj.frames{iframe}.Hours = obj.frames{iframe}.Hours...
                     + 10 * obj.bits(ii) + 20 * obj.bits(ii+1);
                  ii = ii + 2;
               case 58
                  obj.frames{iframe}.Hours = obj.frames{iframe}.Hours...
                     + 20 * obj.bits(ii);
                  ii = ii + 1;
               case 59
                  ii = ii + 1;
               case 60
                  ii = ii + 1;
               case 61
                  ii = ii + 1;
               case 62
                  ii = ii + 1;
               case 63
                  ii = ii + 1;
               case 64
                  ii = ii + 1;
               otherwise   
                  ii = ii + 1;
            end
         end
      end
      
   end   
   
end