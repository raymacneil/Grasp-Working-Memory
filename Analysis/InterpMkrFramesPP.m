% Dependency: GetValidFrames.m


function [InterpData, TrackInterpFrames] = InterpMkrFramesPP(MkrArray,nDims,MkrValidFrames,Time)
  

nMkrs = size(MkrValidFrames,2);
TrackInterpFrames = false(size(MkrArray,1), nMkrs);
MkrNaNTrackIndices = 1:nDims:nMkrs*nDims;
ToInfill = 1:nMkrs*nDims;
InterpData = MkrArray;


for ii = ToInfill

    if any(ii == MkrNaNTrackIndices)
        putIdx = find(MkrNaNTrackIndices == ii);
        ValidFrames = MkrValidFrames{3,putIdx};
        infillFrames = isnan(MkrArray(ValidFrames, ii));
        TrackInterpFrames(ValidFrames,putIdx) = infillFrames; 
    end
    
  % Fit pieceewise polynomial splines to missing data knots
  TempTime = (Time(ValidFrames));
  TempData = double(MkrArray(ValidFrames,ii));
  warning('off', 'SPLINES:CHCKXYWP:NaNs');
  ppData = csaps(TempTime, TempData, 1);
  warning('on', 'SPLINES:CHCKXYWP:NaNs');
  ppValues = fnval(ppData, TempTime);
  InterpData(ValidFrames,ii) = ppValues;

end


end