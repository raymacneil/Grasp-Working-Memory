function [fGAOpenOffset, wGAOpenOffset] = GAOpenOffset(GAVel,fRon,VToffPGA,VDoffPGA)
DefaultVToffPGA = 0;
DefaultVDoffPGA = 16;
if nargin < 3
    VToffPGA = DefaultVToffPGA;
    VDoffPGA = DefaultVDoffPGA;
elseif nargin < 4
    VDoffPGA = DefaultVDoffPGA;
end
       
GAClosingFrames = find(GAVel < VToffPGA); % Get frames of closing grip aperture, based on negative velocity
GAClosingFramesGrouped = cumsum([true; diff(GAClosingFrames)~=1]); % Identify and group the consecutive frames where grip aperture is closing
GAClosingFrameWindows = splitapply(@(x) {x}, GAClosingFrames, GAClosingFramesGrouped); % Split into cells based on parsing of consecutive GA closing frames
% Get the minnium frame of each window and test to see if it is greater
% the the frame of reach onset AND ensure the closure is matained for
% the specified duration threshold.
ValidSearch = (cellfun(@min, GAClosingFrameWindows) > fRon) &...
    (cellfun('size', GAClosingFrameWindows, 1) >= VDoffPGA); % Identify cells where criteria are satisfied
GAClosureFirstWinIdx = find(ValidSearch,1,'first');
GAClosureFirstWin = GAClosingFrameWindows{GAClosureFirstWinIdx};
GAClosureFirstFrame = GAClosureFirstWin(1); 
fGAOpenOffset = GAClosureFirstFrame;
wGAOpenOffset = GAClosureFirstWin;

end