function fFwdOff = fwdReachEndVelocityThreshold(MkrVelocityData, PGAFrame, VToff, VDoff)


    VToffDefault = 75; % Default Velocity Threshold
    VDoffDefault = 10; % Default Duration Velocity Threshold Met
    
    % Define default theshold parameters if not provided
    if nargin < 3
        VToff = VToffDefault;  
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
        
    if ~isempty(VDoffFirstWin)
        fFwdOff = VToffMetWindows{VDoffFirstWin}(1) + 1; % Because it's velocity, add one frame
    else
        fFwdOff = NaN;
    end
       
    
end