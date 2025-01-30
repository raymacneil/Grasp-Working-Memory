%%%%%%%%%%%%% DEPRECATED AS OF JAN 29, 2025 %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% USE fwdReachEndZMin.m INSTEAD %%%%%%%%%%%%%%%%%

function [fFwdOff, markerFlag] = fwdReachEnd2(trial, VTon, VToff, VDon, VDoff)
    VTonDefault = 50;
    VToffDefault = 75;
    VDonDefault = 60;
    VDoffDefault = 10;
    
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


    PGAFrame = PeakGA2(trial, VTon, VToff, VDon, VDoff);

    
    
    %% fFwdOff From Velocity Threshold
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % FROM INDEX FINGER DATA %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    VToffMet = find(trial.mkrIXYZ_vel < VToff);
    grp = cumsum([true; diff(VToffMet) ~= 1]);
    VToffMetWindows = splitapply(@(x) {x}, VToffMet, grp);
    
    
    if isempty(VToffMet)
        VDoffFirstWin = VToffMet;
    else
        ValidSearch = (cellfun(@min, VToffMetWindows) > PGAFrame) &... 
            (cellfun('size', VToffMetWindows, 1) >= VDoff);  
        VDoffFirstWin = find(ValidSearch,1,'first');
    end
        
    if ~isempty(VDoffFirstWin)
        fFwdOffI = VToffMetWindows{VDoffFirstWin}(1) + 1; % Because it's velocity, add one frame
    else
        fFwdOffI = NaN;
    end
    
    %%%%%%%%%%%%%%%%%%%
    % FROM THUMB DATA %
    %%%%%%%%%%%%%%%%%%%
    
    VToffMet = find(trial.mkrTXYZ_vel < VToff);
    grp = cumsum([true; diff(VToffMet) ~= 1]);
    VToffMetWindows = splitapply(@(x) {x}, VToffMet, grp);   
    
    if isempty(VToffMet)
        VDoffFirstWin = VToffMet;
    else
        ValidSearch = (cellfun(@min, VToffMetWindows) > PGAFrame) &... 
            (cellfun('size', VToffMetWindows, 1) >= VDoff);  
        VDoffFirstWin = find(ValidSearch,1,'first');
    end
    
    if ~isempty(VDoffFirstWin)
        fFwdOffT = VToffMetWindows{VDoffFirstWin}(1) + 1; % Because it's velocity, add one frame
    else
        fFwdOffT = NaN;
    end
    
    %% fFwdOff From Z-Minimum
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    % FROM INDEX FINGER DATA %
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    mkrIZmins = find(islocalmin(trial.mkr5Z,'MinProminence',20));
    mkrIZminsValid = mkrIZmins(mkrIZmins >= PGAFrame & trial.mkr5Z(mkrIZmins) < 100);
    if isempty(mkrIZminsValid)
        mkrIZmin = NaN;
    else
        mkrIZmin = mkrIZminsValid(1);
    end
    
    %%%%%%%%%%%%%%%%%%%
    % FROM THUMB DATA %
    %%%%%%%%%%%%%%%%%%%
    mkrTZmins = find(islocalmin(trial.mkr6Z,'MinProminence',20));
    mkrTZminsValid = mkrTZmins(mkrTZmins >= PGAFrame & trial.mkr6Z(mkrTZmins) < 100);
    if isempty(mkrTZminsValid)
        mkrTZmin = NaN;
    else
        mkrTZmin = mkrTZminsValid(1);
    end
    
    %mkrZavg = round(mean([mkrTZmin,mkrIZmin]));
    %fFwdOff = min([fFwdOffI,fFwdOffT,mkrZavg]);

    [fFwdOff, digitIdx] = min([fFwdOffI,fFwdOffT,mkrIZmin,mkrTZmin]);
    
    % Determine which marker's Z-minimum frame number is being returned.
    % Doubles as a check for whether threshold values were used or if Z-min
    % info was used
    if digitIdx == 4
        markerFlag = 6;
    elseif digitIdx == 3
        markerFlag = 5;
    else
        markerFlag = nan;
    end

end


