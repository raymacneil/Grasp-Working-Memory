%HELP for function 'MARMERSPEEDROWS'. 
%
%This function takes positional data in 1,2, or 3D and computes the
%'normal' speed. The data must have 3 columns else an empty matrix will
%be returned.
%
%@PARAMS:
%   'posData'
%   'sampleRate' (self-explanatory)
%
%   Returns a row vector.

function [A] = MarkerSpeedRows(posData, sampleRate)

A = [];
[rows cols] = size(posData);

if cols < 2 || rows < 3
    disp('Error! MARKERSPEEDROWS: ''posData'' must be at least 3x2. Returned an empty matrix.')
    return;
elseif mod(rows,3) ~= 0;
    disp('Error! MARKERSPEEDROWS: cols of ''posData'' must be a multiple of 3. Returned an empty matrix.')
    return;
end

%determine the number of markers
nMarkers = rows/3;

A = zeros(nMarkers, cols-1);

%loop through each marker
for i = 1:nMarkers

    %compute the displacements
    displacement = posData(1:3,2:end)-posData(1:3,1:end-1);
    
    %compute the root of the squared deviations of displacements
    A(i,:) = sqrt(diag(transpose(displacement)*displacement));
    
    %wipe out the positional data for the processed marker
    posData(1:3,:) = [];
end

%scale the speed by the sampleRate
A = A*sampleRate;

return