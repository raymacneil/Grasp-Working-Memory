% Updated by Raymond MacNeil, 2025-02-05
% If input is full trial, will return earliest frame of reach onset between
% thumb and index. If input is only index or thumb velocity, will return frame 
% of reach onset for the input velocity

function fFwdOn = fwdReachStart(trial, VTon, VDon)

    VTonDefault = 50;
    VDonDefault = 60;
    
    % Define default parameters if undefined
    if nargin < 2
        VTon = VTonDefault; VDon = VDonDefault; 
    elseif nargin < 3
        VDon = VDonDefault; 
    end
    
    try
        if isa(trial,'table')

            % fFwdOnI, Onset frame of the forward reach for index
            IdxMkrVelocityData = trial.mkrIXYZ_vel;
            ThbMkrVelocityData = trial.mkrTXYZ_vel;
            fFwdOnI = GetFrameOfReachOnset(IdxMkrVelocityData,VTon,VDon); % Index finger
            fFwdOnT = GetFrameOfReachOnset(ThbMkrVelocityData,VTon,VDon); % Thumb
            fFwdOn = min(fFwdOnI,fFwdOnT);
            
        else

            fFwdOn = GetFrameOfReachOnset(trial,VTon,VDon);
        end
    catch
        warning('Failed to find reach onset; returning fFwdOn = 1.\n');
        fFwdOn = 1;
    end
end



function fFwdOn = GetFrameOfReachOnset(MkrVelocityData,VTon,VDon) 

VTonMet = find(MkrVelocityData > VTon);
grp = cumsum([true; diff(VTonMet)~=1]);
VTonMetWindows = splitapply(@(x) {x}, VTonMet, grp);
VDonFirstWin = find(((cellfun('size', VTonMetWindows, 1) >= VDon)),1,'first');
fFwdOn = VTonMetWindows{VDonFirstWin}(1) + 1; % Because it's velocity, add one frame


end
