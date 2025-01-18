function FiltMkrArray = OptkLowPassDigital(MkrArray, SampRate, Cutoff, Order, MkrValidFrames, nDims)
% SampRate = 200;
% Order = 2;
% Cutoff = 12;

[B,A] = butter(Order,Cutoff/(SampRate/2));
FiltMkrArray = NaN(size(MkrArray));
MkrVFrms = repelem(MkrValidFrames(3,:),1,nDims);

for ii = 1:size(MkrArray,2)
    
    MkrCol = MkrArray(MkrVFrms{ii},ii);
    FiltMkrArray(MkrVFrms{ii},ii) = filtfilt(B,A,double(MkrCol));
    
end

   

end