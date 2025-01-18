


% If input is full trial, will return earliest frame of reach onset between
% thumb and index. If input is only index or thumb velocity, will return frame 
% of reach onset for the input velocity

function fFwdOn = fwdReachStart(trial, VTon, VToff, VDon, VDoff)

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
    try
        if isa(trial,'table')

            % fFwdOnI, Onset frame of the forward reach for index
            VTonMet = find(trial.mkrIXYZ_vel > VTon);
            grp = cumsum([true; diff(VTonMet)~=1]);
            VTonMetWindows = splitapply(@(x) {x}, VTonMet, grp);
            VDonFirstWin = find(((cellfun('size', VTonMetWindows, 1) >= VDon)),1,'first');
            fFwdOnI = VTonMetWindows{VDonFirstWin}(1) + 1; % Because it's velocity, add one frame

            % fFwdOnT, Onset frame of the forward reach for thumb
            VTonMet = find(trial.mkrTXYZ_vel > VTon);
            grp = cumsum([true; diff(VTonMet)~=1]);
            VTonMetWindows = splitapply(@(x) {x}, VTonMet, grp);
            VDonFirstWin = find(((cellfun('size', VTonMetWindows, 1) >= VDon)),1,'first');
            fFwdOnT = VTonMetWindows{VDonFirstWin}(1) + 1; % Because it's velocity, add one frame
            
      
            

            fFwdOn = min(fFwdOnI,fFwdOnT);
        else
            VTonMet = find(trial > VTon);
            grp = cumsum([true; diff(VTonMet)~=1]);
            VTonMetWindows = splitapply(@(x) {x}, VTonMet, grp);
            VDonFirstWin = find(((cellfun('size', VTonMetWindows, 1) >= VDon)),1,'first');
            fFwdOn = VTonMetWindows{VDonFirstWin}(1) + 1;
        end
    catch
        warning('Failed to find reach onset; returning fFwdOn = 1.\n');
        fFwdOn = 1;
    end
end
