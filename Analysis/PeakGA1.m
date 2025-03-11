function fPGA = PeakGA1(trial, VTon, VDon, GACloseThresh)
    
VTonDefault = 50;
VDonDefault = 60;
%     VToffDefault = 75;
%     VDoffDefault = 10;
GACloseThreshDefault = 25;
%     GANotOpenVelThreshold = 25;
%     FwdOn2PGA_MinDist = 40;

% Define default parameters if undefined
if nargin < 2
    VTon = VTonDefault; VDon = VDonDefault;
    GACloseThresh = GACloseThreshDefault;
elseif nargin < 3
    VDon = VDonDefault;
    GACloseThresh = GACloseThreshDefault;
elseif nargin < 4
    GACloseThresh = GACloseThreshDefault;
end
% Defined the frame of reach onset based on the default or
% provided velocity (VTon) and velocity duration (VDon) thresholds.
fFwdOn = fwdReachStart(trial, VTon, VDon);

%     GAVel = [nan; diff(trial.GAxyz)]; % Get the velocity of grip aperture adjustment
GAVel = trial.GAxyz_vel;
GAClosingFrames = find(GAVel < 0); % Get frames of closing grip aperture, based on negative velocity
GAClosingFramesGrouped = cumsum([true; diff(GAClosingFrames)~=1]); % Identify and group the consecutive frames where grip aperture is closing
GAClosingFrameWindows = splitapply(@(x) {x}, GAClosingFrames, GAClosingFramesGrouped); % Split into cells based on parsing of consecutive GA closing frames
% Get the minnium frame of each window and test to see if it is greater
% the the frame of reach onset AND ensure the closure is matained for
% the specified duration threshold.
ValidSearch = (cellfun(@min, GAClosingFrameWindows) > fFwdOn) &...
    (cellfun('size', GAClosingFrameWindows, 1) >= GACloseThresh); % Identify cells where criteria are satisfied
GAClosureFirstWin = find(ValidSearch,1,'first');
GAClosureFirstFrame = GAClosingFrameWindows{GAClosureFirstWin}(1); % Because it's velocity, add one frame

[~,fPGA] = max(trial.GAxyz(fFwdOn:GAClosureFirstFrame));
fPGA = fPGA + fFwdOn - 1;
    
    

end

