
function [PGAFrame, ZMinReachBound] = PeakGA2(trial, VTonFwd, VDonFwd, VToffPGA, VDoffPGA, ZMinPThresh) %#ok<*INUSD>

ZMinPromThresholdDefault = 10;
VTonFwdDefault = 50;
VDonFwdDefault = 60;
% VTonFwdPGA = 200;
% VDonFwdPGA = 25;
VToffPGADefault = 0;
VDoffPGADefault = 16;
FwdOnAdjustFrames = 40;

% Define default parameters if undefined
if nargin < 2
    VTonFwd = VTonFwdDefault; VDonFwd = VDonFwdDefault;
    VToffPGA = VToffPGADefault; VDoffPGA = VDoffPGADefault;
    ZMinPThresh = ZMinPromThresholdDefault;
elseif nargin < 3
    VDonFwd = VDonFwdDefault;
    VToffPGA = VToffPGADefault; VDoffPGA = VDoffPGADefault;
    ZMinPThresh = ZMinPromThresholdDefault;
elseif nargin < 4
    VToffPGA = VToffPGADefault; VDoffPGA = VDoffPGADefault;
    ZMinPThresh = ZMinPromThresholdDefault;
elseif nargin < 5
    VDoffPGA = VDoffPGADefault;
    ZMinPThresh = ZMinPromThresholdDefault;
elseif nargin < 6
    ZMinPThresh = ZMinPromThresholdDefault;
end
% Defined the frame of reach onset based on the default or
% provided velocity (VTon) and velocity duration (VDon) thresholds.
fFwdOn = fwdReachStart(trial, VTonFwd, VDonFwd);
fFwdOnPGA = fFwdOn + FwdOnAdjustFrames;
%     GAVel = [nan; diff(trial.GAxyz)]; % Get the velocity of grip aperture adjustment
GAxyz = trial.GAxyz;
% x = 1:length(GAxyz);
% MkrThumbZ = trial.mkr6Z;
% MkrIndexVel = trial.mkrIXYZ_vel;
% MkrThumbVel = trial.mkrTXYZ_vel;
MkrIndexZ = trial.mkr5Z;
GAVel = trial.GAxyz_vel; % Get the velocity of grip aperture adjustment
try
[GAClosureFirstFrame, GAClosureFirstWin] = GAOpenOffset(GAVel,fFwdOn,VToffPGA,VDoffPGA); %#ok<ASGLU>
catch
end


mkrIZMins = find(islocalmin(MkrIndexZ,'MinProminence',ZMinPThresh));
mkrIZMinsValid = mkrIZMins(mkrIZMins > fFwdOnPGA & MkrIndexZ(mkrIZMins) < 100);
if ~isempty(mkrIZMinsValid)
    ZMinReachBound = mkrIZMinsValid(1);
else
    ZMinReachBound = NaN;
end



try
    [~,PGAFrame] = max(GAxyz(fFwdOn:ZMinReachBound));
    PGAFrame = PGAFrame + fFwdOn - 1;
catch
    [~,PGAFrame] = max(GAxyz(fFwdOn:end));
    PGAFrame = PGAFrame + fFwdOn - 1;
end
% VToff = 75;
% VDoff = 1;
% ZLocalPromThreshold = 10;
% ZMinThreshold = 100;
% 
% fRoffVel = NaN;
% 
% 
% 
% 
% 
% 
% 
% InitVToff = true;
% while isnan(fRoffVel) && (VToff < 100)  
%     
%     if ~InitVToff
%         VToff = VToff + 1;
%     end
%     
%     fRoffVelIDX = fwdReachEndVelocityThreshold(MkrIndexVel, PGAFrame, VToff, VDoff);
%     fRoffVelTHB = fwdReachEndVelocityThreshold(MkrThumbVel, PGAFrame, VToff, VDoff);
%     fRoffVel = min(fRoffVelIDX,fRoffVelTHB);
%     InitVToff = false;
% 
% end
% 
% fRoffZMinIDX = fwdReachEndZMin(MkrIndexZ, PGAFrame, ZLocalPromThreshold, ZMinThreshold);
% fRoffZMinTHB = fwdReachEndZMin(MkrThumbZ, PGAFrame, ZLocalPromThreshold, ZMinThreshold);
% fRoffZMin = min(fRoffZMinIDX,fRoffZMinTHB);
% 
% 
% tiledlayout(2,1)
% nexttile
% plot(x,GAxyz);
% hold on;
% PaintGAClose = GAxyz;
% NotGAClose = ~(GAVel < 0);
% PaintGAClose(NotGAClose) = NaN;
% plot(x,PaintGAClose,x(GAClosureFirstWin),GAxyz(GAClosureFirstWin))
% xline(fFwdOn, 'color', 'g');
% plot(x(fFwdOn),GAxyz(fFwdOn), 'g*');
% xline(fFwdOn2, 'color', "#EDB120"); % Orange
% xline(fFwdOnPGA, 'color', "#77AC30", 'LineStyle', '--'); % Green
% xline(PGAFrame, 'color', "m"); % Cyan
% plot(x(PGAFrame), GAxyz(PGAFrame), "*c");
% xline(ZMinReachBound, 'color', 'r');
% if ~isnan(fRoffVel)
%     xline(fRoffVel, 'color', 'b', 'LineStyle', '--');
% else
%     fprintf('fRoff from velocity threshold could not be computed. \n')
% end
% plot(x(fRoffZMin),GAxyz(fRoffZMin), 'b*');
% plot(x(fRoffZMin),GAxyz(fRoffZMin), 'b*');
% 
% 
% nexttile
% plot(x,MkrIndexZ,x(mkrIZMinsValid),MkrIndexZ(mkrIZMinsValid),'c*')
% hold on
% xline(fFwdOn, 'color', 'g');
% plot(x(fFwdOn),GAxyz(fFwdOn), 'g*');
% xline(fFwdOnPGA, 'color', "#77AC30", 'LineStyle', '--'); % Green
% xline(PGAFrame, 'color', "m"); % Magenta
% xline(ZMinReachBound, 'color', 'r');
% xline(VelReachBound, 'color', 'y');
% if ~isnan(fRoffVel)
%     xline(fRoffVel, 'color', 'b', 'LineStyle', '--');
% else
%     fprintf('fRoff from velocity threshold could not be computed. \n')
% end
% plot(x(fRoffZMin),MkrIndexZ(fRoffZMin)+25, 'b*');




% fRoff = min(fRoffVel,fRoffZMin);
% figTrajectory = Get3DTrajectoryPlot(trial, fFwdOn, fRoff, fRoffVel, fRoffZMin, PGAFrame);


% PGAFrame = PGAFrame; %#ok<ASGSL>


% if (PGAFrameAlt < fFwdOnPGA) && (PGAFrameThresh < fFwdOnPGA)
%     fprintf('Frame ALT Method One! \n')
%     if length(PGAPeaksValid) > 1
%         PGAFrame = PGAPeaksValid(2);
%     else
%         PGAFrame = max(PGAFrameThresh,PGAFrameAlt);
%     end
% elseif (PGAFrameAlt < fFwdOnPGA) || (PGAFrameThresh < fFwdOnPGA)
%     fprintf('Frame ALT Method Two! \n')
%     PGAFrame = max(PGAFrameThresh,PGAFrameAlt);
% else
%     fprintf('Frame ALT Method Three! \n')
%     PGAFrame = min(PGAFrameThresh,PGAFrameAlt);
% end
%     
% 
% 
% if PGAFrame > ReachBound
%     fprintf('PGA Frame Greater Than Reach Bound! \n')
%     [~,PGAFrame] = max(trial.GAxyz(fFwdOn:ReachBound));
%     PGAFrame = PGAFrame + fFwdOn - 1;
% end
%%
end

