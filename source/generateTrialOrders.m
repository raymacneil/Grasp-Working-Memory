function [outputArg1,outputArg2] = generateTrialOrders(inputArg1,inputArg2)
%GENERATETRIALORDERS Summary of this function goes here
%   Detailed explanation goes here
% constants
barAngles = [-10, -5, 0, 5, 10];
induceAngles = [-12 12 0];
numBlocks = 3;
dim2bind = 1;

% from these constants, define ‘higher-level’ parameters
BlockSize = length(barAngles) * length(induceAngles);
numExpTrials = BlockSize * numBlocks;
numTrnTrials = BlockSize / numBlocks;

% create a ‘ShuffleBin’ matrix that can be used to construct
% the range of indices comprising each N-sized block of trials 
ShuffleBins = [1:BlockSize:numExpTrials;...
    BlockSize:BlockSize:numExpTrials]';
 
% a nice one-liner to create the non-randomized trial sequence
TrialSchedA = repmat(fillmissing([repmat(barAngles,... 
    1, length(induceAngles)); sort(repmat(induceAngles, 1,...
    length(barAngles)))], 'previous', dim2bind), 1, numBlocks);

% preallocate a temp array to perform block-wise trial shuffling
TrialSchedExpTemp = zeros(2, BlockSize, numBlocks);

% shuffle the columns for each block while binding the rows
for ii = 1:numBlocks
    TrialSchedExpTemp(:,:,ii) = Shuffle(TrialSchedA(:,ShuffleBins(ii,...
                                        1):ShuffleBins(ii,2)), dim2bind); 
end

TrialSchedExp = reshape(TrialSchedExpTemp, [2,numExpTrials]);
TrialSchedTrain = TrialSchedExp(:,randperm(BlockSize, numTrnTrials));

end

