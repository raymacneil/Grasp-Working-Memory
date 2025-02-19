function fMkrZMin = fwdReachEndZMin(MkrZPositionData, PGAFrame, ZLocalPromThreshold, ZMinThreshold)

if nargin < 3
    ZLocalPromThreshold = 10;
    ZMinThreshold = 100;
elseif nargin < 4
    ZMinThreshold = 100;
end

fMkrZmins = find(islocalmin(MkrZPositionData,'MinProminence',ZLocalPromThreshold));
fmkrZminsValid = fMkrZmins(fMkrZmins >= PGAFrame & MkrZPositionData(fMkrZmins) < ZMinThreshold);

if ~isempty(fmkrZminsValid)
    fMkrZMin = fmkrZminsValid(1);
else
    fMkrZMin = NaN;  
end


end