% Grasping Analysis Pipeline
% 
% Developed by:
% Ray MacNeil, Vision Lab, UBC
% Edwin Huras, Physics Program, Vision Lab Summer Employee
% 2021-2025
% LAST UPDATED: December 2024, Ray MacNeil
function [tfsdat, tparams, expinfo] = batchimp4WM(marks, dims, selectIDs)
% function [tfsdat, tparams, expinfo] = batchimp(grasp, marks, dims, selectIDs)
% 
% INPUTS:
% marks <DBL> A vector reprenting any value(s) of 1-6. 
% Determines for which markers (1-6) time-series data will be
% imported. Markers 1-3: Reference; Marker 4: Index1
% Marker 5: Index2; Marker 6: Thumb
% dims <CHR> Any permutation (of any size) of 'xyz'. Specifies the
% dimensions associated with the markers for data import.
% selectIDs <BOOL> A boolean that determines whether participant folders
% should be selected manually or found/imported in bulk
%
% OUTPUTS:
% tfsdat <CELL ARRAY> Contains time-series data of OptoTrak data
% tparams <STRUCT> Represents the trial summary data, e.g., trial order
% expinfo <CELL ARRAY> Summarizes some information stored by tparams, such as the
% number of trials, number of missing trials, number of trials per block, etc.

%% Exception handling for INPUT
if ~exist('selectIDs', 'var') || isempty(selectIDs)
    selectIDs = true;
end

if ~exist('marks', 'var') || isempty(marks)
    marks = 1:6;
end

if ~exist('dims', 'var') || isempty(dims)
    dims = 'xyz';
end


%% Setup File Path
dirBack = pwd;
if IsOSX
    slashChar = '/';
else
    slashChar = '\';
end
% datadir = uigetdir;
%datadir = '~/Nextcloud/ubc_grasp_wm/Data';
datadir = 'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\Data';

if ~exist(datadir, 'dir')
    fprintf('The default directory cannot be found!\n');
    response = true;
    
    while response   
        new_data_dir = input('Specify a new directory? [y/n] ', 's'); 
        new_data_dir = string(new_data_dir);
        if any(new_data_dir == ["y", "Y"]) 
           break
        elseif any(new_data_dir == ["n", "N"])
           return 
        end
    end
    
    datadir = input('Carefully enter the full path of data directory: ', 's'); 
          
end
        
        
            
% Throw error if Demographics_grasp_wm.csv is missing
dirContents = strip(string(ls(datadir)));
dirContents = dirContents(~startsWith(dirContents, '.'));
dirFiles = dirContents(contains(dirContents,'.'));

if ~any(contains(dirFiles, 'Demographics_grasp_wm.csv'))
    error(sprintf(['Selected directory does not contain the file: graspwm_dems_overview.csv \n',...
        'This file must be located in the specified diectory for batchimpWM.m to run. \n',... 
        'Please ensure that this file is located in the selected directory and ',...
        'try again. \n'])) %#ok<SPERR>
end

fName = fullfile(datadir, 'Demographics_grasp_wm.csv'); 


%% Determine Relevant IDs for Data Import
if selectIDs
    dataFolders = uigetdir2(datadir);
    if isempty(dataFolders)
        fprintf("No folder selected. Exiting...\n")
        return
    end

    % This regex doesn't work on Mac apparently, so I'm using a different
    % method to pull IDs
    % IDs = cellfun(@(x) regexp(x, '(?<=Data\\)\w*', 'match'),... 
    %     dataFolders, 'UniformOutput', false);
    % IDs = vertcat(IDs{:});
    % IDs = cellfun(@(x) x(end-6:end), dataFolders,...
    %     'UniformOutput', false);
    % 
    % This works on newer MATLAB versions
    %[~,IDs] = fileparts(dataFolders(:));
    [~,IDs] = cellfun(@(x) fileparts(x),dataFolders','UniformOutput',false);

    cd(datadir)
    fid = fopen(fName, 'r');
    fSpec = {'%s', '%*s', '%s', '%*s', '%*f', '%*d', '%*d', '%*s', '%*s', '\r\n'};
    GetIDs = textscan(fid, [fSpec{:}], 'HeaderLines', 1, 'Delimiter', ',');
    fclose(fid);
    
    % Find which IDs are NG vs PG based on demographics csv info
    NaturalGetIDs = GetIDs{1}(contains(GetIDs{:,2}, 'NaturalGrasp'));
    PantoGetIDs = GetIDs{1}(contains(GetIDs{:,2}, 'Pantomime'));

    NaturalGetIDs = intersect(unique(NaturalGetIDs),IDs);
    PantoGetIDs = intersect(unique(PantoGetIDs),IDs);
    IDs = [NaturalGetIDs;PantoGetIDs];
else
    cd(datadir)
    fid = fopen(fName, 'r');
    fSpec = {'%s', '%s', '%s', '%*s', '%*f', '%*s', '%*s', '%*s', '\r\n'};
    GetIDs = textscan(fid, [fSpec{:}], 'HeaderLines', 1, 'Delimiter', ',');
    fclose(fid);
    % Order of fields read in: ParticipantID,Experiment,Task
    ID_idx = 1;
    Exp_idx = 2;
    Task_idx = 3;
    
    % Filter for only Digits (this will need to be updated when Motor data
    % comes in)
    Digits_idx = contains(GetIDs{:,Exp_idx}, 'Digits');
    GetIDs = [GetIDs{:}];
    GetIDs = GetIDs(Digits_idx,:);
    
    % Find which IDs are NG vs PG based on demographics csv info
    NaturalGetIDs = GetIDs(contains(GetIDs(:,Task_idx), 'NaturalGrasp'),ID_idx);
    
    GetIDs = GetIDs(:,ID_idx);
    GetIDs = unique(GetIDs(:),'stable');
    dirInfo = struct2cell(dir(datadir));
    dirInfo = dirInfo(1,:)';
    dirInfo = dirInfo(~contains(dirInfo, {'.', 'Testing', 'old','testing'}));

    % dirInfo = dirInfo(~contains(dirInfo, {'cikmbgx', 'mdwm5io', 'z4ztqsp','na0vk4h'}));
    dirInfo = dirInfo(~contains(dirInfo, {'cikmbgx', 'mdwm5io', 'z4ztqsp'}));

    dirInfo = regexp(dirInfo, '\w{7}(?!.)', 'match');
    dirInfo = vertcat(dirInfo{:});
    IDs = intersect(GetIDs, dirInfo, 'stable');
    NaturalGetIDs = intersect(unique(NaturalGetIDs),IDs);
end

%% Declare some constants and preallocate data structures
% Preallocates data based on these maximums. batchimp will likley throw an
% error if there are greater than maxNumTrials for any participant or if
% either NG or PG task has greater than maxNumParticipants
maxNumTrials = 150;
maxNumParticipants = 30;

% Assumes 10 blocks or fewer per participant. If there are more, the data will be read in and
% analyzed but the blk#_ntrial columns in expinfo will not be created. If
% this is an issue, it is strightforward to add additional blocks
expinfo_head = {'id','exp', 'mode', 'config', 'headNames', 'mkr1', 'mkr2', 'mkr3', 'mkr4', 'mkr5', 'mkr6',... 
    'blk0_ntrial', 'blk1_ntrial', 'blk2_ntrial', 'blk3_ntrial', 'blk4_ntrial',...
    'blk5_ntrial', 'blk6_ntrial', 'blk7_ntrial', 'blk8_ntrial', 'blk9_ntrial', 'blk10_ntrial'...
    'total_ntrial', 'bad_ntrial', 'barAngles', 'barLengths'};
num_conditions = 4;
num_grasp_types = 2;
tfsdat = cell(maxNumTrials+1, maxNumParticipants, num_conditions);
mkrIdx = ~cellfun('isempty', regexp(expinfo_head, 'mkr\d'));
expinfo = cell(numel(IDs), numel(expinfo_head), num_grasp_types);  

%% Initiate Data Import Loop

fprintf('Beginning data import... \n')

for ii = 1:numel(IDs)
    
    if ismember(IDs(ii),NaturalGetIDs)
        grasp = 'NaturalGrasp';
        NG = true;
    else
        grasp = 'Pantomime';
        NG = false;
    end

    dirLook = strcat(datadir,slashChar,string(IDs(ii)), slashChar);
    dirList = dir(char(dirLook));
    dirContents = string({dirList.name})';
    dirContents = dirContents(~cellfun(@(x) startsWith(x, '.'), dirContents));
    
    singleTarIdx = contains(dirContents, grasp) & contains(dirContents, 'single');
    dualTarIdx = contains(dirContents, grasp) & contains(dirContents, 'dual');
    baselineTarIdx = contains(dirContents, 'baseline');
    TypeTargs = [singleTarIdx,dualTarIdx,baselineTarIdx];
    typeNames = [{'Single'},{'Dual'},{'Baseline'}];
  
    
    % typ == 1 for single, typ == 2 for dual, typ == 3 for baseline
    for typ = 1:3
        % Treat single/dual differently than baseline
        if typ < 3
            fprintf('Processing %s %s data for ID %d of %d (%s) \n', grasp, typeNames{typ}, ii, numel(IDs), IDs{ii})
            tarIdx = TypeTargs(:,typ);
            skipFlag = false;
            if ~any(tarIdx)
                try
                    fileNames = regexp(dirContents, '\w*\.txt', 'match')';
                    fileNames = cellstr(vertcat(fileNames{:,:}));

                    % Remove bad trials
                    fileNames = fileNames(contains(fileNames,'bt0'));

                    [out, mkrInfo, outCOLS] = GetOptkTFs(dirLook, fileNames, marks, dims);
                    
                    if NG
                        tfsdatPage = typ;
                    else
                        tfsdatPage = typ + 2;
                    end
                    tfsdatCol = find(cellfun('isempty',tfsdat(1,:,tfsdatPage)),1);
                    
                    tfsdat(2:length(out)+1,tfsdatCol,tfsdatPage) = out;
                    tfsdat(1,ii,tfsdatPage) = cellstr(fileNames{1}(1:7));
                    [tparams.(char(IDs(ii))).([grasp, typeNames{typ}]), numBadTrialsValid] = GetExpSummaryData(fileDir);
                catch
                    warning('Could not find %s %s data for ID %s \n Skipping to next...',... 
                        grasp, typeNames{typ}, string(IDs(ii)))
                    skipFlag = true;
                end

            else

                configFile = regexp(dirContents(tarIdx), '(?<=_)[a-z](?=_)', 'match');
                
                % Accomodate participants that have multiple folders for same task
                % TODO: cleanup data to avoid issue, as this code naively
                % selects the first folder
                if length(configFile) > 1
                    configFile = configFile(1);
                    fprintf("Participant has multiple data folders. Choosing config:\n")
                    fprintf("%s\n",configFile{1});
                end

                fileDir = strcat(dirLook, dirContents(tarIdx), slashChar);
                % Accomodate participants that have multiple folders for same task
                % TODO: cleanup data to avoid issue, as this code naively
                % selects the first folder (see participants: b4hxw6g,vlfwh64)
                if size(fileDir,1) > 1
                    fileDir = strip(fileDir(1,:));
                    fprintf("Participant has multiple data folders. Choosing:\n")
                    fprintf("%s\n",fileDir);
                end

                
                dirData = strcat(dirLook, dirContents(tarIdx), slashChar, 'OTCReorganizedTF', slashChar);
                if ~IsOSX
                    dirData = char(dirData);
                    fileDir = char(fileDir);
                end
                
                % Accomodate participants that have multiple folders for same task
                % TODO: this code naively selects the first data folder for
                % any participant with >1 data folders. Data folders
                % may need manual adjustment
                if size(dirData,1) > 1
                    dirData = strip(dirData(1,:));
                end
                allFiles = dir(dirData);
                fileNames = {allFiles.name};
                fileNames = regexp(fileNames,'\w*\.txt', 'match');
                fileNames = vertcat(fileNames{:});
                %fileNames = sort(regexp(fileNames(:), '\w*\.txt', 'match'))';
                
                % Remove bad trials
                fileNames = fileNames(contains(fileNames,'bt0'));

                %[out, mkrInfo, outCOLS] = GetOptkTFs(dirData, fileNames, marks, dims);
                [out, mkrInfo, outCOLS] = GetOptkTFs(dirData, fileNames, marks, dims);
                
                % If type is PG, use pages 3/4 of tfsdat
                if NG
                    tfsdatPage = typ;
                else
                    tfsdatPage = typ + 2;
                end
                tfsdatCol = find(cellfun('isempty',tfsdat(1,:,tfsdatPage)),1);

                tfsdat(2:length(out)+1,tfsdatCol,tfsdatPage) = out;
                tfsdat(1,tfsdatCol,tfsdatPage) = cellstr(fileNames{1}(1:7));
                [tparams.(char(IDs(ii))).([grasp, typeNames{typ}]), numBadTrialsValid] = GetExpSummaryData(fileDir);
            end
            
            if ~skipFlag
                expinfo(ii,1,typ) = cellstr(fileNames{1}(1:7));
                expinfo(ii,2,typ) = cellstr(grasp);
                expinfo(ii,3,typ) = cellstr(typeNames{typ});
                expinfo(ii,4,typ) = cellstr(configFile);
    
                expinfo(ii,mkrIdx,typ) = num2cell(mkrInfo);
                PutIdx = strcmp(expinfo_head, 'headNames');
                %     holdCell = cell(1, length(outCOLS)+1);
                %     holdCell([1:3, 5:end]) = outCOLS;
                %     holdCell(4) = cellstr('Time');
                expinfo{ii, PutIdx, typ} = {outCOLS};
    
                nGoodTrials = size(tparams.(char(IDs(ii))).([grasp, typeNames{typ}]),1);
                PutIdx = strcmp(expinfo_head, 'bad_ntrial');
                expinfo{ii, PutIdx, typ} = {numBadTrialsValid};
                PutIdx = strcmp(expinfo_head, 'total_ntrial');
                expinfo{ii, PutIdx, typ} = {numBadTrialsValid + nGoodTrials};
            end
            
        else
            % Read and save Baseline data but not processed
            fprintf('Processing %s data for ID %d of %d \n', typeNames{typ}, ii, numel(IDs))
            tarIdx = TypeTargs(:,typ);

            configFile = regexp(dirContents(tarIdx), '(?<=_)[a-z](?=_)', 'match');
            fileDir = strcat(dirLook, dirContents(tarIdx), '/');
            if ~IsOSX
                fileDir = char(fileDir);
            end

            [tparams.(char(IDs(ii))).(typeNames{typ}), ~] = GetExpSummaryData(fileDir);
        end
    end
end

fprintf('Data import complete! \n')

%% Experiment Info Loop

cd(dirBack)

fprintf('Gathering and organizing experiment info... \n')

for typ = 1:size(expinfo,3)
    for jj = 1:nnz(~cellfun('isempty', expinfo(:,1,typ)))
        
        if typ == 1
            fprintf('Processing ID %d of %d \n', jj, numel(IDs))
        end
        
        ID = expinfo(jj,1,typ);
        if ismember(ID,NaturalGetIDs)
            grasp = 'NaturalGrasp';
        else
            grasp = 'Pantomime';
        end
        
        T = tparams.(char(IDs(jj))).([grasp, typeNames{typ}]);
        T = sortrows(T,{'BlockNum','TrialNum','TrialCount'},'ascend');

        % maxBlockNum = max(T.BlockNum);
        for kk = 1:11
            GetIdx = T.BlockNum == (kk-1);
            PutIdx = strcmp(expinfo_head, strcat('blk', num2str(kk-1),...
                '_ntrial'));
            nTrial = nnz(GetIdx);
            expinfo(jj,PutIdx,typ) = {nTrial};
        end
        
        PutIdx = strcmp(expinfo_head, 'barAngles');
        expinfo(jj,PutIdx, typ) = {T.BarAngle};
        PutIdx = strcmp(expinfo_head, 'barLengths');
        expinfo(jj,PutIdx, typ) = {T.BarLength};
        
    end
end        

fprintf('Finished gathering experiment info! \n')

expinfoSingle = cell2table(expinfo(:,:,1), 'VariableNames', expinfo_head); 
expinfoDual = cell2table(expinfo(:,:,2), 'VariableNames', expinfo_head); 
expinfo = [expinfoSingle; expinfoDual];

fprintf('Nearly finished, performing some preliminary cleaning... \n')

% For each task type and mode (NG single/dual, PG single/dual)
for typ = 1:size(tfsdat,3)

    % Make sure page isn't empty (e.g only NG or PG participants selected)
    if ~isempty(tfsdat{1,1,typ})
        
        % For each participant for this task type/mode
        for jj = 1:nnz(~cellfun('isempty', tfsdat(1,:,typ)))

            eIdx = find(~cellfun('isempty',tfsdat(:,jj,typ)), 1, 'last' );

            for kk = 2:eIdx

                % Find all mkr rows that are all NaN, find idx before ending
                % trail of NaNs, include values only up to the ending trail
                nanRows = all(isnan(tfsdat{kk,jj,typ}(:,end-8:end)), 2);
                lastNonNaNRow = find(~nanRows, 1, 'last');

                % Remove NaN trail and data from markers 4,5,6
                tfsdat{kk,jj,typ} = tfsdat{kk,jj,typ}(1:lastNonNaNRow, :);

            end

        end
    end
end

return
end


function [out, mkrInfo, GetCOLSlabel] = GetOptkTFs(fileDir, fileNames, MKRnums, DIMS) 


%% Exception and Error Handling

% disp('Processing request...')
% fileDir = dirLook;
% MKRnums = 1:6;
% DIMS = 'xy';

if nargin < 1 || ~exist('MKRnums', 'var') || isempty(MKRnums)
    warning('No argument supplied for MKRnums or DIMS. Using default values.');
    MKRnums = 4:6;
end

if ~isnumeric(MKRnums) || numel(MKRnums) > 6 || sum(ismember(MKRnums,...
        [1,2,3,4,5,6])) ~= numel(MKRnums) 
    error('Invalid entry for MKRnums. See ''help GetTFmarkers''.')
end

if nargin < 2 || ~exist('DIMS', 'var') || isempty(DIMS)
    warning('No argument supplied for MKRnums. Using default values.');
    DIMS = 'xyz';
end

if ~ischar(DIMS) || numel(DIMS) > 3 || sum(ismember(DIMS, 'xyz')) ~= numel(DIMS) 
    error('Invalid entry for DIMS. See ''help GetTFmarkers''.');
end


%% Use GUI for file lookup
% [fileNames,fileDir]=uigetfile('MultiSelect','On','*tf.txt');


%% Get the file count
FILEcount = numel(fileNames); 

% Account for case of single trial selection
if FILEcount == 1
    fileNames = cellstr(fileNames);
end

%% Sort by trial number
% fileNames = transpose(fileNames);
% [~, sortORDER] = sortrows(cellfun(@(x) regexp(x, 't\d*(?=_)', 'match'),...
%     fileNames), 'ascend');
% fileNames = fileNames(sortORDER);


%% Create regular expressions to specify columns to retain for data import
MKRSexp = strcat('[', erase(num2str(MKRnums), ' '), ']');
DIMSexp = strcat('[', DIMS, ']');
GENexp =  strcat('Mkr', MKRSexp, '_', DIMSexp);
anyMKRexp = strcat('Mkr', '[0-9]+', '_', '[xyz]');

%% Get header from one of the trials and determine relevant column indices
fid = fopen(fullfile(fileDir, fileNames{1}),'r');
headerNames = strsplit(fgetl(fid), ',');

if any(cellfun(@(x) contains(x, 'TrialCountRepeatFlag'), headerNames))
    headerNames = {'BlockNum', 'TrialNum', 'TrialCount', 'RepeatFlag', 'SampleRate', ...
                'Mkr1_x', 'Mkr1_y', 'Mkr1_z', 'Mkr2_x', 'Mkr2_y', 'Mkr2_z',...
                'Mkr3_x', 'Mkr3_y', 'Mkr3_z', 'Mkr4_x', 'Mkr4_y', 'Mkr4_z',...
                'Mkr5_x', 'Mkr5_y', 'Mkr5_z', 'Mkr6_x', 'Mkr6_y', 'Mkr6_z'};
end

fclose(fid);
AreMkrCOLS = regexp(headerNames, anyMKRexp, 'match');
AreMkrCOLSidx = cellfun(@(x) ~isempty(x), AreMkrCOLS); 
NotMkrCOLSidx = ~AreMkrCOLSidx;
GetMkrCOLS = regexp(headerNames, GENexp, 'match'); 
GetMkrCOLSidx = cellfun(@(x) ~isempty(x), GetMkrCOLS); 
GetCOLSidx = or(NotMkrCOLSidx, GetMkrCOLSidx);
GetCOLSlabel = headerNames(1,GetCOLSidx);
exp = 'Mkr\d(?=_[xyz])';
mkrs = regexp(headerNames, exp, 'match', 'noemptymatch');
mkrs = char(unique(vertcat(mkrs{:})));
mkrInfo = ismember(1:6, str2num(mkrs(:,end)));
%% Generate the format specification for full data import
formSpec = [repelem({'%f'}, 1, numel(headerNames)), {'\r\n'}];
% formSpec(getCOLS) = {'%f'};


%% We are ready to sail. Preallocate data array and read in the goodies.

out = cell(FILEcount, 1); 

for ii = 1:numel(fileNames)
    
    try
        fid = fopen(fullfile(fileDir, fileNames{ii}),'r');
        optkTFdata = single(cell2mat(textscan(fid,[formSpec{:}],...
        'HeaderLines', 1, 'Delimiter',',')));
        out{ii} = optkTFdata(:, GetCOLSidx);
        fclose(fid);
    
    catch
        warning('There was a problem loading file: %s', fileNames{ii});
    
    end
    
end

end


function [tparams_table, numBadTrialsValid] = GetExpSummaryData(fileDir) 

%% Load in Data given argument fileDir
% Accomodate participants that have multiple folders for same task
% TODO: cleanup data to avoid issue, as this code naively selects the most
% recent folder to input
fileDirStr = string(fileDir);
if length(fileDirStr) > 1
    fileDir = char(fileDirStr(end));
    fprintf("Participant has multiple data folders. Choosing:\n")
    fprintf("%s\n",fileDir);
end
if IsOSX
    listing = ls(fileDir);
    tsFile = char(regexp(listing, '\w*\.csv', 'match')');
else
    listing = dir(fileDir);
    listing = {listing.name};
    tsFile = regexp(listing, '\w*\.csv', 'match')';
    tsFile = tsFile(~cellfun('isempty',tsFile));
    tsFile = tsFile{:};
    tsFile = tsFile{:};
end
fileID = fopen(fullfile(fileDir, tsFile), 'r');
headerNames = strsplit(fgetl(fileID), ',');

% Need to accomodate variations in the results_out.csv file as number of
% columns as well as column location changed over course of experiment
% if ~contains(headerNames,'PracticeSkipped')
%     fSpec = horzcat({'%s'},{'%d'}, {'%s'}, repelem({'%d'},4), repelem({'%f'},6), {'%s'}, {'%f'}, {'%f'}, {'%s'},...
%      repelem({'%f'},6), {'\r\n'});
% elseif ~contains(headerNames,'wmNBack')
%     fSpec = horzcat({'%s'},{'%d'}, {'%s'}, repelem({'%d'},5), repelem({'%f'},6), {'%s'}, {'%f'}, {'%f'}, {'%s'},...
%      repelem({'%f'},6), {'\r\n'});
% else
%     fSpec = horzcat({'%s'},{'%d'}, {'%s'}, repelem({'%d'},6), repelem({'%f'},6), {'%s'}, {'%f'}, {'%f'}, {'%s'},...
%      repelem({'%f'},6), {'\r\n'});
% end
% fSpec = ['%s%d%s', repmat('%d', 1, 6), repmat('%f', 1, 5), '%s', '%f%f%s%s%f%f%f%d%f%d%d\r\n'];
    
fSpec = horzcat({'%s'},{'%d'}, {'%s'}, repelem({'%d'},6), repelem({'%f'},6), {'%s'},... 
{'%f','%f','%s','%s','%f','%f','%f','%d','%f','%d','%d'}, {'\r\n'});
out = textscan(fileID,[fSpec{:}], 'HeaderLines', 0, 'Delimiter',',');
fclose(fileID);

% Convert TRUE/FALSE strings into logical values

PracticeBlockIdx = strcmp(headerNames,'PracticeBlock');

if iscellstr(out{:,PracticeBlockIdx})
    PracticeBlockLogical = strcmpi(out{:,PracticeBlockIdx}, 'true');
    out{:,PracticeBlockIdx} = double(PracticeBlockLogical);
else
    out{:,PracticeBlockIdx} = double(out{:,PracticeBlockIdx});
end
    

%% Parse based on data type
dtype = string(arrayfun(@(x) class(x{:}), out, 'UniformOutput', false));
idxA = strcmp("int32", dtype);
idxB = strcmp("double", dtype);
idxC = strcmp("cell", dtype);
%idxC(1) = false; % Exclude participant ID from output

convertedout = cell(size(out{1},1),size(out,2));
convertedout(:,idxA) = num2cell(single([out{idxA}]));
convertedout(:,idxB) = num2cell(single([out{idxB}]));
convertedout(:,idxC) = cellfun(@string, [out{idxC}], 'UniformOutput', false);


%% Create Table for Trial Parameters

% BlockNum, TrialNum, BadTrial, BarAngle, InduceAngle
tparams_table = cell2table(convertedout,'VariableNames', headerNames);

% Don't count 'bad trials' registered in the practice block
numBadTrialsValid = nnz(and(tparams_table.BlockNum > 0, tparams_table.BadTrial ~= 0)); 
% numBadTrialsValid = sum(tparams_table.BadTrial ~= 0); 

% Obtain logical index of all rows marked as bad trials, for subsequent
% removal
isBadTrialIdxAll = (tparams_table.BadTrial ~= 0 & tparams_table.BadTrial ~= 5);

% The TrialCount variable in the data files count trial numbers within
% blocks, including bad trials. For later identification and checking that
% tparams rows align with tfsdat we add a TrialCount variable to tparams
% before removing bad trials marked 2
tparams_table.TrialCount = nan([size(tparams_table,1)],1);
for block = 0:max(tparams_table.BlockNum)
    tparams_table.TrialCount(tparams_table.BlockNum == block) = (1:sum(tparams_table.BlockNum == block))';
end

tparams_table = tparams_table(~isBadTrialIdxAll,:);
tparams_table = movevars(tparams_table,'TrialCount','After','BlockNum');

return

end