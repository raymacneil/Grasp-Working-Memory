function [InterpPPData, TrackInterpFrames] = MarkerInterpolate
  



if any(ToFill(ll) == TrackNanFillIndices)
    putIdx = find(ToFill(ll) == TrackNanFillIndices);
    infillFrames = isnan(Trial(SampStartValid:SampEndValid,...
        ToFill(ll)));
    Metrics(SampStartValid:SampEndValid,putIdx) = infillFrames; %#ok<FNDSB>
end
                   
  % Fit pieceewise polynomial splines to missing data knots
  TempTime = (Time(SampStartValid:SampEndValid));
  TempData = double(Trial(SampStartValid:SampEndValid,ToFill(ll)));
  warning('off', 'SPLINES:CHCKXYWP:NaNs');
  ppData = csaps(TempTime, TempData, 1);
  warning('on', 'SPLINES:CHCKXYWP:NaNs');
  ppValues = fnval(ppData, TempTime);
  Trial(SampStartValid:SampEndValid,ToFill(ll)) = ppValues;




end