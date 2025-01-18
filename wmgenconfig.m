% Raymond MacNeil, Vision Lab, 2024
% Generates configuration files for the grasping and working memory study.
% INPUTS:
function [dual_task, single_task, baseline_wm_task] = wmgenconfig(config_id, wm_modality, nbacks, nbackrev)

if nargin < 1
    error('Must assign the configuration files an ID tag!')
elseif nargin < 2
    fprintf('Modality not specified. Defaulting to ''digits''... \n')
    wm_modality = "digits";
elseif nargin < 3
    fprintf('N-backs not specified. Defaulting to ''[1 2]''... \n')
    nbacks = [1 2];
end

if nbackrev
    nbacks = sort(nbacks,'descend');
end

string(wm_modality);
pathID =  ismember(["digits"; "motor"], wm_modality);
config_paths = {'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\Config_Files\Digits';...
        'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\Config_Files\Motor'};

if ~any(pathID)
    error('Invalid input for argument wm_modality. Must be ''digits'' or ''motor''.')
else
    config_path = config_paths{pathID};
end

addpath('C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\source')
stimNames = GetStimNames();
stimNames = stimNames(~contains(stimNames(:,1),'Two-2-5-'),1);
numUniqueDigits = 3;
numStims = numel(stimNames);
r1 = (1:numUniqueDigits:numStims)';
r2 = (numUniqueDigits:numUniqueDigits:numStims)';
stimCombsIdx = combinations(r1(1):r2(1), r1(2):r2(2), r1(3):r2(3));
barLengths = [40, 50, 60];

numPracticeBlocks = numel(nbacks);
numPTPB = 6; % number of practice trials per block
numETPB = 9; % number of experimental trials per block
numTotalPractice = numPTPB * numPracticeBlocks + sum(nbacks); 
FullBlockSetStim = cellstr(repelem('NA',(numStims * 3 * numel(nbacks) + ... 
    sum(nbacks .* 3) + numTotalPractice), 1));

num_prc_first_half = numPTPB + nbacks(1);
num_exp_first_half = numETPB + nbacks(1); 
num_prc_second_half = numPTPB + nbacks(2); 
num_exp_second_half = numETPB + nbacks(2);

% Generate block number column vector
bns = num2cell( [repelem( 0, num_prc_first_half, 1); reshape(repelem([1 2 3],...
    num_exp_first_half, 1), [], 1); repelem(4, num_prc_second_half, 1);... 
    reshape(repelem([5 6 7], num_exp_second_half, 1), [], 1 ) ] );

% Generate trial number column vector
tns = [(1:num_prc_first_half)'; repmat((1:num_exp_first_half)', 3, 1);... 
    (1:num_prc_second_half)'; repmat((1:num_exp_second_half)', 3, 1)];

% Practice block identifier
ispractice = [repelem(1,num_prc_first_half,1); zeros(num_exp_first_half * 3, 1);... 
    repelem(1, num_prc_second_half, 1); zeros(num_exp_second_half * 3, 1)];
barangle = num2cell(zeros(numel(tns),1));

% Generate a bar length vector with randomized presentation
ridx1 = randi(3,1,1);
leftover = find(~ismember(1:3, ridx1));
ridx2 = leftover(randi(2,1,1));

bar_length_first_practice = barLengths(ridx1);
bar_length_second_practice = barLengths(ridx2);

barlength = num2cell( [repelem(bar_length_first_practice, num_prc_first_half, 1);... 
    reshape( repelem( Shuffle(barLengths), num_exp_first_half, 1),[],1);... 
    repelem( bar_length_second_practice, num_prc_second_half, 1);... 
    reshape( repelem( Shuffle(barLengths), num_exp_second_half, 1),[], 1)] );


visfb = num2cell(repelem(1,numel(tns),1));
visfbt = num2cell(repelem(749,numel(tns),1));
wmInitTime = num2cell(repelem(83.3, numel(tns),1));
wmPos = num2cell(repelem(4, numel(tns),1));
wmStimFrames = num2cell(repelem(24, numel(tns),1));
wmMod = cellstr(repelem(wm_modality,numel(tns),1));


wmNback = [repelem(NaN, nbacks(1),1); repelem(nbacks(1), numPTPB, 1);... 
    repmat([repelem(NaN, nbacks(1),1); repelem(nbacks(1), numETPB, 1)], 3, 1);...
    [repelem(NaN, nbacks(2), 1); repelem(nbacks(2), numPTPB, 1)];... 
    repmat([repelem(NaN, nbacks(2),1); repelem(nbacks(2), numETPB, 1)], 3, 1)];
wmDual = num2cell(ones(numel(tns),1));

% nback1End = find(wmNback == 1,1, 'last');
% nback2End = find(wmNback == 2,1, 'last');
% wmNbackReverse = num2cell([wmNback((nback1End+1):nback2End); wmNback(1:nback1End)]);

cfgMatrix = [bns num2cell(ispractice) num2cell(tns) barangle barlength visfb... 
    visfbt wmInitTime FullBlockSetStim wmPos wmStimFrames wmMod num2cell(wmNback) wmDual];
BlockSetStim = NaN(numStims,3);
StimSet = cell(1,2);

for ii = 1:2

    while (nnz(isnan(BlockSetStim)) > 1) ||...
            sum(all(diff(BlockSetStim))) ~= numUniqueDigits
        
        for jj = 1:size(BlockSetStim,2)
            
            combsUnique = false;
            
            while ~combsUnique
                randRowIdx = randsample(1:size(stimCombsIdx,1),numUniqueDigits);
                selection = reshape(stimCombsIdx(randRowIdx,:)',...
                    numel(randRowIdx)*numUniqueDigits,1);
                combsUnique = (numel(unique(selection))) == numStims;
            end
            
            BlockSetStim(:,jj) = Shuffle(selection);
            
        end
                
    end

BlockSetStim = reshape(BlockSetStim, numel(BlockSetStim), 1);
wmStimSet = stimNames(BlockSetStim);
StimSet{ii} = wmStimSet;
BlockSetStim = NaN(numStims,3);


end

numIdxExp = find(~ispractice);
filler = logical([repmat([zeros(numETPB,1); ones(nbacks(1),1)],3,1);... 
    repmat([zeros(numETPB,1); ones(nbacks(2),1)],3,1)]);
Indices = numIdxExp(~filler);
blkEndIndices = numIdxExp(filler);
FullBlockSetStim(Indices) = [cellstr(StimSet{1}); cellstr(StimSet{2})];
PracticeStim = randsample(stimNames, nnz(ispractice), true);
numIdxPractice = find(ispractice);
FullBlockSetStim(numIdxPractice) = cellstr(PracticeStim); %#ok<FNDSB>
BlockEndStim = randsample(stimNames, nnz(and(~ispractice, isnan(wmNback))));
FullBlockSetStim(blkEndIndices) = cellstr(BlockEndStim);
cfgMatrix(:,9) = FullBlockSetStim;
out = cell2table(cfgMatrix, 'VariableNames', {'block_num', 'is_practice_block',...
    'trial_num', 'bar_angle', 'bar_length', 'vis_feedback', 'vis_feedback_time',...
    'wm_init_time', 'wm_stimulus', 'wm_position', 'wm_stim_frames', 'wm_modality',...
    'wm_nback','wm_task_is_dual'});

% Create copies of configuration file for each of the task types;
dual_task = out;
single_task = out;
baseline_wm_task = out;


FullFilePathDual = fullfile(config_path, horzcat(config_id, '_tconfig_grasp_wm_',...
    char(wm_modality), '_dual.csv'));
FullFilePathSingle = fullfile(config_path, horzcat(config_id, '_tconfig_grasp_wm_',...
    char(wm_modality), '_single.csv'));
FullFilePathBaselineWM = fullfile(config_path, horzcat(config_id, '_tconfig_grasp_wm_',...
    char(wm_modality), '_baseline.csv'));


% Modify parameters accordingly for single, dual, and baseline conditions

% Single task
uneeded_prac_blk_single = logical(single_task.is_practice_block) & single_task.block_num > 0;
single_task = single_task(~uneeded_prac_blk_single,:);
blk_idx_modify = logical(cumsum([false; diff(single_task.block_num) > 1]));
single_task.block_num(blk_idx_modify) = single_task.block_num(blk_idx_modify) - 1;
single_task.wm_modality = cellstr(repelem("NA", height(single_task), 1));
single_task.wm_nback = NaN(height(single_task),1);
single_task.wm_task_is_dual = zeros(height(single_task),1);
single_task = single_task(~(single_task.is_practice_block == 1 & single_task.trial_num > 6),:); 

% Baseline task
baseline_wm_task.wm_task_is_dual = zeros(height(baseline_wm_task),1);

% Write to disk if selected identifier tag not already in use
if ~exist(FullFilePathDual, 'file') && ~exist(FullFilePathSingle, 'file') &&...
        ~exist(FullFilePathBaselineWM, 'file')
    writetable(dual_task, FullFilePathDual);
    writetable(single_task, FullFilePathSingle);
    writetable(baseline_wm_task, FullFilePathBaselineWM);
else
    error('Failed to write configuration files. The identifier tag ''%s'' has already been assigned.',...
        config_id)
end

if exist(FullFilePathDual, 'file') && exist(FullFilePathSingle, 'file') &&...
        exist(FullFilePathBaselineWM, 'file')
    fprintf('Sucesfully generated configuration files with the id tag ''%s'' and of modality ''%s'' \n\n',...
        config_id, wm_modality)
end

end

