function t = CheckLandmarksPlot(t, trial, fFwdOn, fPGA, fPGAZBound, fRoffVel, fRoffZMin) 

fFwdOnPGA = fFwdOn + 40;
PGAFrame = fPGA;
GAxyz = trial.GAxyz;
x = 1:length(GAxyz);
MkrIndexZ = trial.mkr5Z;
MkrThumbZ = trial.mkr6Z;
MkrIndexY = trial.mkr5Y;
% MkrIndexVel = trial.mkrIXYZ_vel;
% MkrThumbVel = trial.mkrTXYZ_vel;
GAVel = trial.GAxyz_vel; % Get the velocity of grip aperture adjustment


% title(t,str);


% while isnan(fRoffVel) && (VDoff ~= 0)  
%     
%     if ~InitVDoff
%         VDoff = VDoff - 1;
%     end
%     
%     fRoffVelIDX = fwdReachEndVelocityThreshold(MkrIndexVel, PGAFrame, VToff, VDoff);
%     fRoffVelTHB = fwdReachEndVelocityThreshold(MkrThumbVel, PGAFrame, VToff, VDoff);
%     fRoffVel = min(fRoffVelIDX,fRoffVelTHB);
%     InitVDoff = false;
% 
% end


nexttile(t,1)
plot(x,GAxyz, 'HandleVisibility', 'off');
hold on;
PaintGAClose = GAxyz;
NotGAClose = ~(GAVel < 0);
PaintGAClose(NotGAClose) = NaN;
plot(x,PaintGAClose, 'DisplayName', 'Grip Aperture (Neg Velocity)');
xline(fFwdOn, 'color', 'g', 'HandleVisibility', 'off');
plot(x(fFwdOn),GAxyz(fFwdOn), 'g*', 'HandleVisibility', 'off');
plot(nan, nan, 'g-*', 'DisplayName','Reach Onset')
xline(fFwdOnPGA, 'color', "#77AC30", 'LineStyle', '--', 'DisplayName',... 
    'Reach Onset + 40'); % Pale Green
xline(PGAFrame, 'color', "c", 'HandleVisibility', 'off'); % Cyan
plot(x(PGAFrame), GAxyz(PGAFrame), "*m", 'HandleVisibility', 'off');
plot(nan, nan, 'c-*', 'MarkerFaceColor', 'm', 'DisplayName','PGA')
xline(fRoffZMin, 'color', 'r', 'HandleVisibility', 'off');

if ~isnan(fRoffVel)
    xline(fRoffVel, 'color', 'b', 'LineStyle', '--', 'DisplayName', 'Reach Off (Vel)');
else
    fprintf('fRoff from velocity threshold could not be computed. \n')
end
xline(fPGAZBound, 'color', "#EDB120", 'LineStyle', '--', 'DisplayName', 'PGA ZMin Bound');
plot(x(fRoffZMin),GAxyz(fRoffZMin), 'r*', 'HandleVisibility', 'off');
plot(nan, nan, 'r-*', 'MarkerFaceColor', 'm', 'DisplayName','Reach Off (ZMin)')

hold off;
lgd = legend;
lgd.Layout.Tile = 'northeast';
title(lgd,'Landmarks')


nexttile(t,2)
plot(x,MkrIndexZ)
hold on
xline(fFwdOn, 'color', 'g');
plot(x(fFwdOn),MkrIndexZ(fFwdOn), 'g*');
xline(fFwdOnPGA, 'color', "#77AC30", 'LineStyle', '--'); % Pale Green
xline(PGAFrame, 'color', "c"); % Cyan
plot(x(PGAFrame), MkrIndexZ(PGAFrame), "*m");

xline(fRoffZMin, 'color', 'r');
if ~isnan(fRoffVel)
    xline(fRoffVel, 'color', 'b', 'LineStyle', '--');
else
    fprintf('fRoff from velocity threshold could not be computed. \n')
end
xline(fPGAZBound, 'color', '#EDB120', 'LineStyle', '--');
plot(x(fRoffZMin),MkrIndexZ(fRoffZMin), 'r*');



end
