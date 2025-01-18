function [MkrValidFrames] = GetValidFrames(MkrArray, nDims)
   
%   Dims = 'xyz';  
%   MkrArray = randi(100,100,9);
%   Base = ~logical(randi(1,100,9));
%   Base([1:6,80:83],1:3) = true;
%   Base(72:77,4:6) = true;
%   Base([1:3,33:37,95:100],7:9) = true;
%   MkrArray(Base) = NaN;  
 
  
  
% Determine the number of markers in the position data array
  numMkrs = size(MkrArray,2) / nDims;
 
% Disrupted marker visibility affects all dimensions, so arbitrarily chose 
% the first dimension, e.g., x, for determining the range of valid frames
  MkrValidFrames = cell(3,numMkrs);
  
for idxScan = 1:nDims:(numMkrs*nDims)
               
      CellColIdx = (idxScan + (nDims - 1)) / 3;
      % Simplified infill
      if isnan(MkrArray(1,idxScan))

         MkrValidFrames{1,CellColIdx} = find(~isnan(MkrArray(:,idxScan)),...
              1, 'first');
      else
          
         MkrValidFrames{1,CellColIdx} = 1;
      
      end
      
      if isnan(MkrArray(end,idxScan))
      
          MkrValidFrames{2,CellColIdx} = find(~isnan(MkrArray(:,idxScan)), 1,...
              'last');
      else
          
          MkrValidFrames{2,CellColIdx} = size(MkrArray,1);
      
      end
      
      MkrValidFrames{3,CellColIdx} = MkrValidFrames{1,CellColIdx}:MkrValidFrames{2,CellColIdx};
      
end




end
