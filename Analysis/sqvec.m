function [A] = sqvec(numVec)

%proceed if A is a numeric vector
if ~isvector(numVec) || ~ isnumeric(numVec)
    disp('SQVEC Error: Argument must be a numeric vector. Nan Resturned.')
    A = nans(size(numVec));
else   
    %perform element-wise multiplication
    A = numVec.*numVec;
end
return;
