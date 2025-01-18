function TestTryCatch()

% define constants
A = 2;  B = 4;  C = 7;  D = 16;  E = 32;


% preallocate variables
matrixA = NaN(A,A); 
matrixB = NaN(B,B);
matrixC = NaN(C,C); 
matrixD = NaN(D,D); 
matrixE = NaN(E,E);
flag = string(); 

try

matrixA(:,:) = magic(2);
matrixB(:,:) = magic(2^2);
matrixC(:,:) = magic(2^3);
matrixD(:,:) = magic(2^4);
matrixE(:,:) = magic(2^5);

     
catch
    flag = "Matrix Error";
end 

celldisp({matrixA, matrixB, matrixC, matrixD, matrixE, flag});

return 