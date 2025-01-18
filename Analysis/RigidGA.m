function PGAadj = RigidGA(GAxyz, GAxyz_vel, fMinThreshold, fRon)

VTon = 1;
fThreshold = 50;
% minThreshold = 10;
% GAxyz = temp.GAxyz;
% GAxyz_vel = temp.GAxyz_vel;
% fRon = T.fRon(ii);


PreReachGAxyz = GAxyz(1:fRon);
PreReachGAxyz_vel = GAxyz_vel(1:fRon);

fVTonNotMet = find(and(PreReachGAxyz_vel > (-VTon), PreReachGAxyz_vel < VTon));
fGrp = cumsum([true; diff(fVTonNotMet)~=1]);
fVTonNotMetWindows = splitapply(@(x) {x}, fVTonNotMet, fGrp);

while fThreshold >= fMinThreshold 
    fThresholdFirstWin = find(((cellfun('size', fVTonNotMetWindows, 1) >= fThreshold)),1,'first');
    if ~isempty(fThresholdFirstWin)
        break
    end
    fThreshold = fThreshold - 1;
end

if ~isempty(fThresholdFirstWin)
    fRigidGARef = fVTonNotMetWindows{fThresholdFirstWin};         
    fRigidGARef = [fRigidGARef(1)-1; fRigidGARef];
    PGAadj = mean(PreReachGAxyz(fRigidGARef)) * -1;
else
    PGAadj = NaN;
end

end