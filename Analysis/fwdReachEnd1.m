function fFwdOff = fwdReachEnd1(trial, PGAFrame, VTon, VToff, VDon, VDoff)
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

    %PGAFrame = PeakGA(trial, VTon, VToff, VDon, VDoff);

    if isa(trial,'table')
        %PGAFrame = PeakGA(trial, VTon, VToff, VDon, VDoff);
        VToffMet = find(trial.mkrIXYZ_vel < VToff);
        grp = cumsum([true; diff(VToffMet) ~= 1]);
        VToffMetWindows = splitapply(@(x) {x}, VToffMet, grp);
        if isempty(VToffMetWindows)
            VDoffFirstWin = VToffMet;
        else
            ValidSearch = (cellfun(@min, VToffMetWindows) > PGAFrame) &... 
            (cellfun('size', VToffMetWindows, 1) >= VDoff);  
            VDoffFirstWin = find(ValidSearch,1,'first');
        end
        if isempty(VDoffFirstWin)
            fFwdOffI = NaN;
        else
            fFwdOffI = VToffMetWindows{VDoffFirstWin}(1) + 1; % Because it's velocity, add one frame
        end
    
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
        if isempty(VDoffFirstWin)
            fFwdOffT = NaN;
        else
            fFwdOffT = VToffMetWindows{VDoffFirstWin}(1) + 1; % Because it's velocity, add one frame
        end
        
        fFwdOff = min(fFwdOffI,fFwdOffT);

    else
        %PGAFrame = PeakGA(trial, VTon, VToff, VDon, VDoff);
        VToffMet = find(trial < VToff);
        grp = cumsum([true; diff(VToffMet) ~= 1]);
        VToffMetWindows = splitapply(@(x) {x}, VToffMet, grp);
        if isempty(VToffMet)
            VDoffFirstWin = VToffMet;
        else
            ValidSearch = (cellfun(@min, VToffMetWindows) > PGAFrame) &... 
                (cellfun('size', VToffMetWindows, 1) >= VDoff);  
            VDoffFirstWin = find(ValidSearch,1,'first');
        end
        if isempty(VDoffFirstWin)
            %fprintf("Could not find an interval that meets reach end threshold.\n");
            fFwdOff = NaN;
        else
            fFwdOff = VToffMetWindows{VDoffFirstWin}(1) + 1;
        end
    end
end





