%HELP for function 'MARKERSPEEDCOLS'. 
%
%This function takes positional data in 1,2, or 3D and computes the
%'normal' acceleration. The data must have 3 columns else an empty matrix will
%be returned.
%
%@PARAMS:
%   'posData'
%   'sampleRate' (self-explanatory)
%
%   Returns a column vector.

function [A] = MarkerAccelCols(posData, sampleRate)

A = [];
[rows cols] = size(posData);

if cols < 3 || rows < 2
    disp('Error! MARKERSPEEDCOLS: ''posData'' must be at least 2x3. Returned an empty matrix.')
    return;
elseif mod(cols,3) ~= 0;
    disp('Error! MARKERSPEEDCOLS: columns of ''posData'' must be a multiple of 3. Returned an empty matrix.')
    return;
end

%determine the number of markers
nMarkers = cols/3;
A = zeros(rows-2, nMarkers);
   
%compute approximate second order derivative displacements
sumSqDisp = transpose(diff(posData,2,1).*diff(posData));

%loop through the markers
for i=1:nMarkers
    A(:,i) = sqrt(sum(sumSqDisp(1:3,:)));
    
    %wipe out the processed rows for processed marker to process the next
    %rows for the next marker
    sumSqDisp(1:3,:) = [];
end

%scale the speed by the sampleRate
A = A*sampleRate;

return