%HELP for function 'GA'.
%
%This function returns the euclidean distance between two markers each of
%which is represented in 3D cartesian coordinates (x, y, and z).
%
%@PARAMS:   
%
%   'posData'   the positional data in 3D cartesian coordinates. Must be a 
%               a matrix (rows = sample frames, and columns = cartesian planes
%               x, y, and z grouped together for a given marker)  

function [A] = GA(posData)

[rows cols] = size(posData);
A = zeros(rows, 1);

%'data' must have 6 columns to proceed
if(cols == 6)
    A = sqrt(diag((posData(:,1:3)-posData(:,4:6))*transpose(posData(:,1:3)-posData(:,4:6))));
    %x2_x1_sq = sqvec(posData(:,4) - posData(:,1));
    %y2_y1_sq = sqvec(posData(:,5) - posData(:,2));
    %z2_z1_sq = sqvec(posData(:,6) - posData(:,3));
    %A = sqrt(x2_x1_sq  + y2_y1_sq + z2_z1_sq);
    
%otherwise, return an empty matrix
else
    disp('Error! GA: data must have 6 columns. Returned an empty matrix!!!')
    A = [];
end

return;