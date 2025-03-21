%%%%%%%%%%%%% DEPRECATED AS OF JAN 29, 2025 %%%%%%%%%%%%%%%%
%%%%%%%%%%%%% USE fwdReachEndVelocityThreshold %%%%%%%%%%%%%

function fFwdOff = fwdReachEnd1(MkrVelocityData, PGAFrame, VToff, VDoff)

    VToffDefault = 75;
    VDoffDefault = 10;
    
    % Define default parameters if undefined
    if nargin < 3
        VToff = VToffDefault;  %#ok<*NASGU>
        VDoff = VDoffDefault;   
    elseif nargin < 4
        VDoff = VDoffDefault;  
    end



    VToffMet = find(MkrVelocityData < VToff);
    Windows = cumsum([true; diff(VToffMet) ~= 1]);
    VToffMetWindows = splitapply(@(x) {x}, VToffMet, Windows);
    
    if isempty(VToffMet)
        VDoffFirstWin = VToffMet;
    else
        ValidSearch = (cellfun(@min, VToffMetWindows) > PGAFrame) &...
            (cellfun('size', VToffMetWindows, 1) >= VDoff);
        VDoffFirstWin = find(ValidSearch,1,'first');
    end
    
    if isempty(VDoffFirstWin)
        fFwdOff = NaN;
    else
        fFwdOff = VToffMetWindows{VDoffFirstWin}(1) + 1; % Because it's velocity, add one frame
    end

        
    
end


