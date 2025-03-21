% Code to get Sam Started
% INPUTS 
% ffpath (CHAR): full filepath for the desired .mat file containing the
% AllMetrics, expinfo, tfsdat, and tparams data structures. If no input is
% supplied, the uiget function is called to activates a GUI for file
% selection.

function out = fwdReachEndCoords(ffpath4matFile)

if nargin < 1
   [matFile, fileDir] = uigetfile('*.mat', 'Select MAT-file derived from pipeline4WM.m');
   ffpath4matFile = fullfile(fileDir,matFile);
end

% Load selected MATLAB file with output from the pipeline4WM preprocessing
try
    targetVars = {'AllMetrics', 'tfsdat'};
    load(ffpath4matFile, targetVars{:})
catch
    error('The selected MAT-file does not appear to contain the AllMetrics and/or tfsdat variables')
end


% N.B. tfsdat and AllMetrics are 3-dimensional data structures called cells
% Think of spread sheets being stack on each other. The first dimension is
% the row, the second dimension is the column, and third dimension is the
% spreadsheet. In programming, we use the term 'panel' or 'page' when talking 
% about the 3rd of a matrix or similar data structure. 


% For the tfsdat and AllMetrics cells, the frst and second panels contain
% the data for participants in the real grasp (RG) condition. The first 
% panel is RG sinlge task, while the second panel is RG dual task. The
% third and fourth panels correspond to participant data from the pantomime
% grasp (PG) condition. The third panel is PG single task, while the fourth
% panel is PG dual task. In summary, for tfsdat and AllMetrics we have:
% Panel 1: RGs, Single Task
% Panel 2: RGs, Dual Task
% Panel 3: PGs, Single Task
% Panel 4: PGs, Dual Task

rgPanels = [1,2];
pgPanels = [3,4];
grspFns = {'RG'; 'PG'};
numTasks = 2;
nonEmptyColsRG = ~cellfun('isempty', tfsdat(1,:,1)); %#ok<*IDISVAR,*NODEF>
nonEmptyColsPG = ~cellfun('isempty', tfsdat(1,:,3));

[tfs, metrics, fwdEndCoords] = deal(struct(grspFns{1},{{}},grspFns{2},{{}}));
tfs.RG = tfsdat(:, nonEmptyColsRG, rgPanels);
tfs.PG = tfsdat(:, nonEmptyColsPG, pgPanels);
metrics.RG = AllMetrics(:,nonEmptyColsRG, rgPanels); 
metrics.PG = AllMetrics(:,nonEmptyColsPG, pgPanels); 
fwdEndCoords.RG = cell(size(metrics.RG,1), size(metrics.RG,2), size(metrics.RG,3));
fwdEndCoords.PG = cell(size(metrics.PG,1), size(metrics.PG,2), size(metrics.PG,3));


%% 1. Preallocate Structure with Tables for Storing the fOffAdjusted Coordinate Data

% Col dimensions for table preallocation
numPositionalDims = 3;
numMarkers = 3;
numColsFwdEndCoordTable = numPositionalDims * numMarkers;
% First, we loop at the Grasp level
for ii = 1:numel(grspFns)
    grspFieldName = grspFns{ii};
    IDs = metrics.(grspFieldName)(1,:,1);
    fwdEndCoords.(grspFieldName)(1,:,:) = metrics.(grspFieldName)(1,:,:);
    
    % Next, we loop at ID level
    for jj = 1:numel(IDs)
        IDjj = IDs{jj};
    
    
        % And, finally, we loop at the task (single vs. dual) level
        for kk = 1:numTasks

            % Re: line below. This actually doesn't differ by jj, but
            % demonstrating best practices (dynamic and flexible coding)
            idCellColIndex = strcmp(IDjj,metrics.(grspFieldName)(1,:,kk)); 
            numRowsFwdEndCoordTable = size(metrics.(grspFieldName){2,idCellColIndex,kk},1);
            % Double check it matches number of trials in tfsPG, if you see
            isequal(numRowsFwdEndCoordTable, find(~cellfun('isempty', tfs.(grspFieldName)(2:end,idCellColIndex,kk)), 1, 'last'))
            
            fwdEndCoordTable = cell2table(cell(numRowsFwdEndCoordTable, numColsFwdEndCoordTable),'VariableNames',...
                    {'Mkr4X_fRoff','Mkr4Y_fRoff','Mkr4Z_fRoff',... % Wrist / Knuckle
                     'Mkr5X_fRoff','Mkr5Y_fRoff','Mkr5Z_fRoff',... % Index Finger
                     'Mkr6X_fRoff','Mkr6Y_fRoff','Mkr6Z_fRoff'});  % Thumb

            fwdEndCoords.(grspFieldName){2,idCellColIndex,kk} = fwdEndCoordTable;
        end % Task Level (Single, Dual) Looop
        
    end % ID Level Loop (IDjj)
    
end % Grasp Type (RG, PG) Loop 


%% 2. Use fOff_Adjusted frames in metrics to get corresponding coordinate data from tfs
% Will need to loop at the grasp level (ii), ID level (jj), task level (kk), 
% and trial level (ll).

% First, we loop at the Grasp level
for ii = 1:numel(grspFns)
    grspFieldName = grspFns{ii};
    IDs = metrics.(grspFieldName)(1,:,1);
       
    % Loop at ID level
    for jj = 1:numel(IDs)
        IDjj = IDs{jj};
        
        % Loop at the task level 
        for kk = 1:numTasks
            idCellColIndex = strcmp(IDjj,metrics.(grspFieldName)(1,:,kk)); 
            % Think about ther logic, complete the next steps...
            metricsIJK = metrics.(grspFieldName)(2,idCellColIndex,kk);
            metricsIJK = metricsIJK{:};
            tfsIJK = tfs.(grspFieldName)(:,idCellColIndex,kk);
            IndexMapping = GetIndexMapping(metricsIJK, tfsIJK);
            numTrials = size(metricsIJK,1);
            tempCoordT = fwdEndCoords.(grspFieldName){2,idCellColIndex,kk};

            for ll = 1:numTrials
            % Loop through the trials of MetricsIJK, pull out the fOff
            % value, then use that to pull out the position data in tfsIJKL
                fRoff = metricsIJK{ll, 'fRoffVTorZMin'};
                TFsll = IndexMapping(ll);
                tfsIJKL = tfsIJK{TFsll};
                GetMkrPosVars = regexp(tfsIJKL.Properties.VariableNames,... 
                    'mkr\d[X-Z]', 'match');
                GetMkrPosVars = GetMkrPosVars(~cellfun('isempty', GetMkrPosVars));
                MkrPosVars = [GetMkrPosVars{:}];
                tempCoordT{ll,:} = num2cell(tfsIJKL{fRoff,MkrPosVars});               
                
            end % numTrials
            
            fwdEndCoords.(grspFieldName){2,idCellColIndex,kk} =  tempCoordT;

        end %numTasks (i.e. single, dual)
        
    end %numel(IDs) for Grasp ii (RG or PG)
    
end % grasp level loop (RG, PG)

%% 3. Concatenate our new tables in fwdEndCoords with those in AllMetrics with those in 

RG = [fwdEndCoords.RG(:,:,1); fwdEndCoords.RG(2,:,2)];
RG = reshape(RG,[],1);
PG = [fwdEndCoords.PG(:,:,1); fwdEndCoords.PG(2,:,2)];
PG = reshape(PG,[],1);
RGPG = [RG(~cellfun(@ischar,RG)); PG(~cellfun(@ischar,PG))];
RGPG = vertcat(RGPG{:});

% Use some combination of clever indexing, the permute and reshape
% functions to creat one giant table that stacks all of them together and
% prints out a big CSV like the ones you see in thise shared folder

% INSERT CODE HERE
% INSERT CODE HERE
% INSERT CODE HERE

out = ImABigBoyNowMetricsTable;

end

% Helper function to ensure proper index mapping between metrics and tfsdat
function IndexMapping = GetIndexMapping(metricsIJK, tfsIJK)

tfdatEndIdx = find(~cellfun('isempty', tfsIJK),1,'last');
tfdatTempTrialInfo = cell(tfdatEndIdx-1,1);
tfsTargColNames = {'block', 'trial', 'TrialCount', 'RepeatFlag'};
mtsTargColNames = {'Block', 'Trial_id', 'TrialCount_tfsdat', 'TrialRepeat'};
IndexMapping = NaN(size(metricsIJK,1),1);

for iiH = 2:(tfdatEndIdx)
    temp = tfsIJK{iiH};
    tfdatTempTrialInfo(iiH-1) = {temp{1, tfsTargColNames}}; %#ok<CCAT1>        
end

for jjH = 1:size(metricsIJK,1)
    TrialInfoJJ = metricsIJK{jjH, mtsTargColNames};
    IndexMapping(jjH) = find(cellfun(@(x) isequal(x, TrialInfoJJ), tfdatTempTrialInfo));   
end

IndexMapping = IndexMapping + 1;

end
