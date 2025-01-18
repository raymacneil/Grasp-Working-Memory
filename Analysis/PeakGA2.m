
function PGAFrame = PeakGA2(trial, VTon, VToff, VDon, VDoff)
    
    VTonDefault = 50;
    VToffDefault = 75;
    VDonDefault = 60;
    VDoffDefault = 10;
    GAVThresh = 16;
    FwdOn2PGA_MinDist = 40;
    
    % Define default parameters if undefined
    if nargin < 3
        VTon = VTonDefault; VToff = VToffDefault; 
        VDon = VDonDefault; VDoff = VDoffDefault;   
    elseif nargin < 4
        VToff = VToffDefault; 
        VDon = VDonDefault; VDoff = VDoffDefault;  
    elseif nargin < 5
        VDon = VDonDefault; VDoff = VDoffDefault; 
    elseif nargin < 6
        VDoff = VDoffDefault;    
    end

    fFwdOn = fwdReachStart(trial, VTon, VToff, VDon, VDoff);
    
    GAVel = [nan; diff(trial.GAxyz)];
    GAVTonMet = find(GAVel < 0);
    GAgrp = cumsum([true; diff(GAVTonMet)~=1]);
    GAVTonMetWindows = splitapply(@(x) {x}, GAVTonMet, GAgrp);
    ValidSearch = (cellfun(@min, GAVTonMetWindows) > fFwdOn) &... 
        (cellfun('size', GAVTonMetWindows, 1) >= GAVThresh);
    GAVDoffFirstWin = find(ValidSearch,1,'first');
    GAVDoff = GAVTonMetWindows{GAVDoffFirstWin}(1) + 1; % Because it's velocity, add one frame
    
    [~,PGAFrameThresh] = max(trial.GAxyz(fFwdOn:GAVDoff));
    PGAFrameThresh = PGAFrameThresh + fFwdOn - 1;

    % Alternative attempt to find PGA
    PGAPeaks = find(islocalmax(trial.GAxyz,'MinSeparation',100,'MinProminence',0.8));
    PGAPeaksValid = PGAPeaks(PGAPeaks > fFwdOn);
    if isempty(PGAPeaksValid)
        PGAFrameAlt = NaN;
    else
        PGAFrameAlt = PGAPeaksValid(1);
    end



    if (PGAFrameAlt - fFwdOn < FwdOn2PGA_MinDist) && (PGAFrameThresh - fFwdOn < FwdOn2PGA_MinDist)
        if length(PGAPeaksValid) > 1
            PGAFrame = PGAPeaksValid(2);
        else
            PGAFrame = max(PGAFrameThresh,PGAFrameAlt);
        end
    elseif (PGAFrameAlt - fFwdOn < FwdOn2PGA_MinDist) || (PGAFrameThresh - fFwdOn < FwdOn2PGA_MinDist)
        PGAFrame = max(PGAFrameThresh,PGAFrameAlt);
    else
        PGAFrame = min(PGAFrameThresh,PGAFrameAlt);
    end
    
    %% Work in progress...
    % Check whether PGA found is past presumable end of reach
    mkrIZMins = find(islocalmin(trial.mkr5Z,'MinProminence',20));
    mkrIZMinsValid = mkrIZMins(mkrIZMins > fFwdOn + FwdOn2PGA_MinDist & trial.mkr5Z(mkrIZMins) < 100);
    if ~isempty(mkrIZMinsValid)
        ReachBound = mkrIZMinsValid(1);
    else
        ReachBound = NaN;
    end

    if PGAFrame > ReachBound
        [~,PGAFrame] = max(trial.GAxyz(fFwdOn:ReachBound));
        PGAFrame = PGAFrame + fFwdOn - 1;
    end
    %%
end

