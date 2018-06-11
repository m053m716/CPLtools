classdef FETdb < handle
%% FETDB Database object for Fixed Evolution Time computation
% Adapted from code by Taehyeun Park, The Cooper Union, EE'15
   properties (Access = 'public')
      pars              % Parameters
      box               % Database "box" for efficient searching
      data              % Input data
      name = 'fetout';  % Name of text file (without .txt)
      mle = nan;        % Maximum Lyapunov Exponent estimate (output)
   end
   
   methods (Access = 'public')
      function db = FETdb(x)
         db.init(x);
         db.build;
      end
      
      function Update(db,varargin)
         buildflag = false;
         for iV = 1:2:numel(varargin)
            arg = varargin{iV};
            val = varargin{iV+1};


            if ~isnumeric(val)
               warning('Value must be numeric.');
               continue
            end

            if val<=0
               warning('Value must be positive.');
               continue
            end

            if abs(val-round(val))>eps
               warning('Value must be an integer.');
               continue
            end

            if (strcmpi(arg,'m')||strcmpi(arg,'ndim'))
               db.pars.bas.tau = val;
               fprintf(1,'Rebuilding database with %s as %d...\n',arg,val);
               buildflag = true;
            elseif strcmpi(arg,'tau')
               db.pars.bas.m = val;
               fprintf(1,'Rebuilding database with %s as %d...\n',arg,val);
               buildflag = true;
            elseif (strcmpi(arg,'res')||strcmpi(arg,'resolution'))
               db.box.res = val;
               fprintf(1,'Rebuilding database with %s as %d...\n',arg,val);
               buildflag = true;
            elseif (strcmpi(arg,'max')||strcmpi(arg,'maxbox'))
               db.box.max = val;
               fprintf(1,'Rebuilding database with %s as %d...\n',arg,val);
               buildflag = true;
            elseif strcmpi(arg,'dt')
               fprintf(1,'Changed %s to %d from %d. Please rerun fet(db).\n',...
                  arg,val,db.pars.fet.dt);
               db.pars.fet.dt = val;
            elseif strcmpi(arg,'evolve')
               fprintf(1,'Changed %s to %d from %d. Please rerun fet(db).\n',...
                  arg,val,db.pars.fet.dt);
               db.pars.fet.evolve = val;
            elseif strcmpi(arg,'dismin')
               fprintf(1,'Changed %s to %d from %d. Please rerun fet(db).\n',...
                  arg,val,db.pars.fet.dt);
               db.pars.fet.dismin = val;
            elseif strcmpi(arg,'dismax')
               fprintf(1,'Changed %s to %d from %d. Please rerun fet(db).\n',...
                  arg,val,db.pars.fet.dt);
               db.pars.fet.dismax = val;
            elseif strcmpi(arg,'thmax')
               fprintf(1,'Changed %s to %d from %d. Please rerun fet(db).\n',...
                  arg,val,db.pars.fet.dt);
               db.pars.fet.thmax = val;
            end
         end
         
         if buildflag
            db.build;
         end
         
      end
      
      function [out,SUM] = Fet(db)
         % Computes Lyapunov exponent of given data and parameters, generates output
         % textfile, exact replica of Fortran 77 version of fet
         % Taehyeun Park, The Cooper Union, EE'15
         
         out = [];
         
         dismax = db.pars.fet.dismax;
         dismin = db.pars.fet.dismin;
         thmax = db.pars.fet.thmax;
         evolve = db.pars.fet.evolve;
         dt = db.pars.fet.dt;
         
         ndim = db.pars.bas.m;
         ires = db.box.res;
         tau = db.pars.bas.tau;
         datcnt = db.data.n;
         datmin = db.data.min;
         boxlen = db.box.n;
         
         datptr = db.box.datptr;
         nxtbox = db.box.nxtbox;
         where = db.box.where;
         nxtdat = db.box.nxtdat;
         x = db.data.x;
         
         delay = 0:tau:(ndim-1)*tau;
         datuse = datcnt-(ndim-1)*tau-evolve;
         savmax = dismax;
         
         
         oldpnt = 1;
         newpnt = 1;
         its = 0;
         SUM = 0;
         
         fileID = fopen([db.name '.txt'], 'w');
         
         goto50 = 1;
         while goto50 == 1
            goto50 = 0;
            [bstpnt, bstdis, thbest] = db.search(0, ndim, ires, datmin, boxlen, nxtbox, where, ...
               datptr, nxtdat, x, delay, oldpnt, newpnt, datuse, dismin, dismax,...
               thmax, evolve);
            
            while bstpnt == 0
               dismax = dismax * 2;
               [bstpnt, bstdis, thbest] = db.search(0, ndim, ires, datmin, boxlen, nxtbox, where, ...
                  datptr, nxtdat, x, delay, oldpnt, newpnt, datuse, dismin, dismax,...
                  thmax, evolve);
            end
            
            dismax = savmax;
            newpnt = bstpnt;
            disold = bstdis;
            iang = -1;
            
            goto60 = 1;
            while goto60 == 1
               goto60 = 0;
               
               oldpnt = oldpnt + evolve;
               newpnt = newpnt + evolve;
               
               if oldpnt >= datuse
                  return
               end
               
               if newpnt >= datuse
                  oldpnt = oldpnt - evolve;
                  goto50 = 1;
                  break
               end
               
               p1 = x(oldpnt + delay);
               p2 = x(newpnt + delay);
               disnew = sqrt(sum((p2 - p1).^2));
               
               its = its + 1;
               
               SUM = SUM + log(disnew/disold);
               zlyap = SUM/(its*evolve*dt*log(2));
               out = [out; its*evolve, disold, disnew, zlyap, (oldpnt-evolve), (newpnt-evolve)];
               
               if iang == -1
                  fprintf(fileID, '%-d\t\t\t%-8.4f\t\t%-8.4f\t\t%-8.4f\n', out(end,1:4)');
               else
                  fprintf(fileID, '%-d\t\t\t%-8.4f\t\t%-8.4f\t\t%-8.4f\t\t%-d\n', [out(end,1:4), iang]');
               end
               
               if disnew <= dismax
                  disold = disnew;
                  iang = -1;
                  goto60 = 1;
                  continue
               end
               
               [bstpnt, bstdis, thbest] = db.search(1, ndim, ires, datmin, boxlen, nxtbox, where, ...
                  datptr, nxtdat, x, delay, oldpnt, newpnt, datuse, dismin, dismax,...
                  thmax, evolve);
               
               if bstpnt ~= 0
                  newpnt = bstpnt;
                  disold = bstdis;
                  iang = floor(thbest);
                  goto60 = 1;
                  continue
               else
                  goto50 = 1;
                  break;
               end
            end
         end
      end
      
      function MakePlot(db,out,loc)
      % Plots 2D or 3D attractor evolution by evolution, 4th parameter is the
      % location of legend
      % Taehyeun Park, The Cooper Union, EE'15
         
         datcnt = db.data.n;
         ndim = db.pars.bas.m;
         tau = db.pars.bas.tau;
         dataplot = [];
         freerun = 0;
         
         delay = 0:tau:(ndim-1)*tau;
         x = db.data.x;
         
         for ii = 1:(datcnt-(ndim-1)*tau)
            dataplot = [dataplot; x(ii+delay)];
         end
         
         figure, bar(out(:,1),out(:,3)), hold on;
         db.mle = max(dataplot(:)) - min(dataplot(:));
         plot([0, out(end,1)], [db.mle, db.mle], 'r', 'LineWidth', 1.5), hold off;
         set(gca,'YTick', [0, db.mle])
         axis([0, out(end,1), 0, 1.1*db.mle])
         title('d_f of evolutions scaled to the maximum linear extent of the attractor')
         
         if ndim == 2
            figure('Position', [100, 100, 800, 500]);
            plot(dataplot(:,1), dataplot(:,2), '.', 'MarkerSize', 3), hold on;
            disp('To see the next evolution, press enter')
            disp('To clear the screen and then see the next evolution, type c and press enter')
            disp('To proceed without stopping, type r and press enter')
            disp('To terminate plot generating, type g and press enter')
            
            for ii = 1:size(out,1)
               if freerun == 0
                  RESET = input('Next evolution?  ', 's');
                  if strcmp(RESET, 'c')
                     disp('Screen cleared')
                     hold off;
                     clf;
                     plot(dataplot(:,1), dataplot(:,2), '.', 'MarkerSize', 3), hold on;
                  elseif strcmp(RESET, 'r')
                     disp('Evolving without stopping...')
                     disp('Press ctrl+c to terminate')
                     freerun = 1;
                  elseif strcmp(RESET, 'g')
                     disp('Plot generating stopped')
                     return;
                  else
                     if ii > 1
                        delete(ann)
                     end
                  end
               end
               
               tmpold = out(ii,5);
               oldpnt = tmpold + evolve;
               tmpnew = out(ii,6);
               newpnt = tmpnew + evolve;
               
               plot(x(tmpold:oldpnt), x((tmpold+tau):(oldpnt+tau)), 'r', 'LineWidth', 1);
               plot(x(tmpnew:newpnt), x((tmpnew+tau):(newpnt+tau)), 'g', 'LineWidth', 1);
               for aa = 0:evolve
                  plot([x(tmpold+aa), x(tmpnew+aa)], [x(tmpold+aa+tau), x(tmpnew+aa+tau)], 'LineWidth', 1)
               end
               
               
               ann = legend(['Iteration: ', num2str(out(ii,1)), '/', num2str(out(end,1)), char(10)...
                  'd_i:', num2str(out(ii,2)), char(10)...
                  'd_f:', num2str(out(ii,3)), char(10)...
                  'Current Estimate:' num2str(out(ii,4))], ...
                  'location', loc);
               if freerun == 1
                  drawnow
               end
            end
            
         elseif ndim == 3
            figure('Position', [100, 100, 800, 500]);
            plot3(dataplot(:,1), dataplot(:,2), dataplot(:,3), '.', 'MarkerSize', 3), hold on;
            disp('To see the next evolution, press enter')
            disp('To clear the screen and then see the next evolution, type c and press enter')
            disp('To proceed without stopping, type r and press enter')
            disp('To terminate plot generating, type g and press enter')
            
            for ii = 1:size(out,1)
               if freerun == 0
                  RESET = input('Next evolution?  ', 's');
                  if strcmp(RESET, 'c')
                     disp('Screen cleared')
                     hold off;
                     clf;
                     plot3(dataplot(:,1), dataplot(:,2), dataplot(:,3), '.', 'MarkerSize', 3), hold on;
                  elseif strcmp(RESET, 'r')
                     disp('Evolving without stopping...')
                     disp('Press ctrl+c to terminate')
                     freerun = 1;
                  elseif strcmp(RESET, 'g')
                     disp('Plot generating stopped')
                     return;
                  else
                     if ii > 1
                        delete(ann)
                     end
                  end
               end
               
               tmpold = out(ii,5);
               oldpnt = tmpold + db.pars.fet.evolve;
               tmpnew = out(ii,6);
               newpnt = tmpnew + db.pars.fet.evolve;
               
               plot3(x(tmpold:oldpnt), x((tmpold+tau):(oldpnt+tau)), x((tmpold+(2*tau)):(oldpnt+(2*tau))), 'r', 'LineWidth', 1);
               plot3(x(tmpnew:newpnt), x((tmpnew+tau):(newpnt+tau)), x((tmpnew+(2*tau)):(newpnt+(2*tau))), 'g', 'LineWidth', 1);
               for aa = 0:db.pars.fet.evolve
                  plot3([x(tmpold+aa), x(tmpnew+aa)], [x(tmpold+aa+tau), x(tmpnew+aa+tau)], [x(tmpold+aa+(2*tau)), x(tmpnew+aa+(2*tau))], 'LineWidth', 1)
               end
               
               
               ann = legend(['Iteration: ', num2str(out(ii,1)), '/', num2str(out(end,1)), char(10)...
                  'd_i:', num2str(out(ii,2)), char(10)...
                  'd_f:', num2str(out(ii,3)), char(10)...
                  'Current Estimate:' num2str(out(ii,4))], ...
                  'location', loc);
               if freerun == 1
                  drawnow
               end
            end
         end
      end
   end
   
   methods (Access = 'private')
      function init(db,x)
         if (numel(size(x))>2 || min(size(x))>1)
            error('x (input) must be a vector.');
         else
            x = reshape(x,1,numel(x));
            fprintf(1,'Building database...\n');
         end
         db.pars.bas.m = 5;
         db.pars.bas.tau = 100;
         
         db.box.max = 1e6;
         db.box.res = 100;
         
         db.data.x = x;
         db.data.min = min(x);
         db.data.max = max(x);
         pad = 0.01 *(db.data.max - db.data.min);
         
         db.data.min = db.data.min - 0.01 * pad;
         db.data.max = db.data.max + 0.01 * pad;
         
         db.data.n = numel(x);
         
         db.pars.fet.dt = 1;
         db.pars.fet.evolve = 20;
         db.pars.fet.dismin = 0.001;
         db.pars.fet.dismax = 1;
         db.pars.fet.thmax = 30;
      end
      
      function build(db)
         db.box.nxtbox = zeros(db.box.max,db.pars.bas.m);
         db.box.where = zeros(db.box.max,db.pars.bas.m);
         db.box.datptr = zeros(1,db.box.max);
         db.box.nxtdat = zeros(1,db.data.n);
         
         db.box.n = (db.data.max-db.data.min)/db.box.res;
         db.box.count = 1;
         
         delay = 0:db.pars.bas.tau:((db.pars.bas.m-1)*db.pars.bas.tau);
         for ii = 1:(db.data.n-(db.pars.bas.m-1)*db.pars.bas.tau)
            target = floor((db.data.x(ii+delay)-db.data.min)...
               /db.box.n);
            runner = 1;
            chaser = 0;
            
            jj = 1;
            while jj <= db.pars.bas.m
               tmp = db.box.where(runner,jj)-target(jj);
               if tmp < 0
                  chaser = runner;
                  runner = db.box.nxtbox(runner,jj);
                  if runner~=0
                     continue
                  end
               end
               if tmp ~= 0
                  db.box.count = db.box.count + 1;
                  
                  if db.box.count == db.box.max
                     error('Grid overflow, increase box maximum.');
                  end
                  
                  for kk = 1:db.pars.bas.m
                     db.box.where(db.box.count,kk)=db.box.where(chaser,kk);
                  end
                  db.box.where(db.box.count,jj) = target(jj);
                  db.box.nxtbox(chaser,jj) = db.box.count;
                  db.box.nxtbox(db.box.count,jj) = runner;
                  runner = db.box.count;
               end
               jj = jj + 1;
            end
            db.box.nxtdat(ii) = db.box.datptr(runner);
            db.box.datptr(runner) = ii;
         end
         used = sum(db.box.datptr(1:db.box.count)~=0);
         fprintf(1,'Created: %d\n', db.box.count);
         fprintf(1,'Used: %d\n', used);
         
         db.box.datptr = db.box.datptr(1:db.box.count);
         db.box.nxtbox = db.box.nxtbox(1:db.box.count,1:db.pars.bas.m);
         db.box.where = db.box.where(1:db.box.count,1:db.pars.bas.m);
         db.box.nxtdat = db.box.nxtdat(1:db.data.n);         
      end
      
      function [bstpnt,bstdis,thbest] = search(db,iflag,ndim,ires,datmin,...
            boxlen,nxtbox,where,datptr,nxtdat,data,delay,oldpnt,newpnt,...
            datuse,dismin,dismax,thmax,evolve)
         % Searches for the most viable point for fet.m
         % Taehyeun Park, The Cooper Union, EE'15
         
         target = zeros(1,ndim);
         oldcrd = zeros(1,ndim);
         zewcrd = zeros(1,ndim);
         
         oldcrd(1:ndim) = data(oldpnt+delay);
         zewcrd(1:ndim) = data(newpnt+delay);
         igcrds = floor((oldcrd - datmin)./boxlen);
         oldist = sqrt(sum((oldcrd - zewcrd).^2));
         
         irange = round(dismin/boxlen);
         if irange == 0
            irange = 1;
         end
         
         thbest = thmax;
         bstdis = dismax;
         bstpnt = 0;
         
         goto30 = 1;
         while goto30 == 1
            goto30 = 0;
            for icnt = 0:((2*irange+1)^ndim)-1
               goto140 = 0;
               icounter = icnt;
               for ii = 1:ndim
                  ipower = (2*irange+1)^(ndim-ii);
                  ioff = floor(icounter./ipower);
                  icounter = icounter - ioff*ipower;
                  target(ii) = igcrds(ii) - irange + ioff;
                  
                  if target(ii) < 0
                     goto140 = 1;
                     break;
                  end
                  if target(ii) > ires-1
                     goto140 = 1;
                     break
                  end
               end
               
               if goto140 == 1
                  continue
               end
               
               if irange ~= 1
                  iskip = 1;
                  for ii = 1:ndim
                     if abs(round(target(ii) - igcrds(ii))) == irange
                        iskip = 0;
                     end
                  end
                  if iskip == 1
                     continue
                  end
               end
               
               runner = 1;
               for ii = 1:ndim
                  goto80 = 0;
                  goto70 = 1;
                  while goto70 == 1
                     goto70 = 0;
                     if where(runner,ii) == target(ii)
                        goto80 = 1;
                        break
                     end
                     runner = nxtbox(runner, ii);
                     if runner ~= 0
                        goto70 = 1;
                     end
                  end
                  
                  if goto80 == 1
                     continue
                  end
                  goto140 = 1;
                  break
               end
               
               if goto140 == 1
                  continue
               end
               
               if runner == 0
                  continue
               end
               runner = datptr(runner);
               if runner == 0
                  continue
               end
               goto90 = 1;
               while goto90 == 1
                  goto90 = 0;
                  while 1
                     if abs(round(runner - oldpnt)) < evolve
                        break
                     end
                     if abs(round(runner - datuse)) < (2*evolve)
                        break
                     end
                     
                     bstcrd = data(runner + delay);
                     
                     abc1 = oldcrd(1:ndim) - bstcrd(1:ndim);
                     abc2 = oldcrd(1:ndim) - zewcrd(1:ndim);
                     tdist = sum(abc1.*abc1);
                     tdist = sqrt(tdist);
                     dot = sum(abc1.*abc2);
                     
                     if tdist < dismin
                        break
                     end
                     if tdist >= bstdis
                        break
                     end
                     if tdist == 0
                        break
                     end
                     goto120 = 0;
                     if iflag == 0
                        goto120 = 1;
                     end
                     if goto120 == 0
                        ctheta = min(abs(dot/(tdist*oldist)),1);
                        theta = 57.3*acos(ctheta);
                        if theta >= thbest
                           break
                        end
                        thbest = theta;
                     end
                     bstdis = tdist;
                     bstpnt = runner;
                     break;
                  end
                  runner = nxtdat(runner);
                  
                  if runner ~= 0
                     goto90 = 1;
                  end
               end
            end
            irange = irange + 1;
            if irange <= (0.5 + round((dismax/boxlen)))
               goto30 = 1;
               continue;
            end
            return
         end
      end
   end
end