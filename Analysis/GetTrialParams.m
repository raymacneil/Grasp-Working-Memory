function TrialParamsOut = GetTrialParams(datadir)
% function TrialParams = GetTrialParams(datadir)
% 
% INPUTS:

% selectIDs <BOOL> A boolean that determines whether participant folders
% should be selected manually or found/imported in bulk
% datadir <CHR>: One of either 'Digits' or 'Motor'
%

% OUTPUTS:

% TrialParams <struct>


%% Exception handling for INPUT
if nargin < 1
   datadir = '/Users/ray.macneil/Nextcloud/Grasp-Working-Memory/Data'; 
end


if IsOSX
    slashChar = '/';
else
    slashChar = '\';
end


DefaultDataDir = '/Users/ray.macneil/Nextcloud/Grasp-Working-Memory/Data';
DemographicsFileName = 'Demographics_grasp_wm.csv';
demsFilePath = fullfile(DefaultDataDir,DemographicsFileName);

if string(DefaultDataDir) ~= string(datadir)
   
   datadir = fullfile(DefaultDataDir, datadir);
     
   try
       copyfile(demsFilePath, datadir)
   catch 
       error('Issue copying demographics file.\nCheck that %s is contained in %s',... 
           DemographicsFileName, DefaultDataDir) 
   end
   
end
   


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
dirContents = regexp(dirContents, '\w*(\.csv)?', 'match')';
dirContents = dirContents(~startsWith(dirContents, '.'));
dirFiles = dirContents(contains(dirContents,'.'));

if ~any(contains(dirFiles, DemographicsFileName))
    error(sprintf(['Selected directory does not contain the file: graspwm_dems_overview.csv \n',...
        'This file must be located in the specified diectory for batchimpWM.m to run. \n',... 
        'Please ensure that this file is located in the selected directory and ',...
        'try again. \n'])) %#ok<SPERR>
end

fName = fullfile(datadir, DemographicsFileName); 


%% Determine Relevant IDs for Data Import

    
dataFolders = uigetdir2(datadir);
if isempty(dataFolders)
    fprintf("No folder selected. Exiting...\n")
    return
end
dataFolders = dataFolders';
dCell = char(dataFolders(:));
all_rows_same = all(diff(dCell, [], 1) == 0, 1);
common_cols = find(~all_rows_same, 1, 'first') - 1;
dataDirRenamed = dataFolders{1}(1:common_cols);
[~,IDs] = cellfun(@(x) fileparts(x),dataFolders,'UniformOutput',false);

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


if strcmp(datadir, DefaultDataDir)
    datadir = dataDirRenamed;
end

 

%% Initiate Data Import Loop

fprintf('Beginning data import... \n')

for ii = 1:numel(IDs)
    
    if ismember(IDs(ii),NaturalGetIDs)
        grasp = 'NaturalGrasp';
    else
        grasp = 'Pantomime';
    end

    dirLook = fullfile(datadir,string(IDs(ii)));
    dirList = dir(char(dirLook));
    dirContents = string({dirList.name})';
    dirContents = dirContents(~cellfun(@(x) startsWith(x, '.'), dirContents));
    oldData = cellfun(@(x) size(x,1)>0, regexp(dirContents, '\d*',"match"),... 
        'UniformOutput',false);
    oldData = vertcat(oldData{:});
    
    
    singleTarIdx = contains(dirContents, grasp) & contains(dirContents, 'single') & ~oldData;
    dualTarIdx = contains(dirContents, grasp) & contains(dirContents, 'dual') & ~oldData;
    baselineTarIdx = contains(dirContents, 'baseline') & ~oldData;
    TypeTargs = [singleTarIdx,dualTarIdx,baselineTarIdx];
    typeNames = [{'Single'},{'Dual'},{'Baseline'}];
  
    
    % typ == 1 for single, typ == 2 for dual, typ == 3 for baseline
    for typ = 1:3
        % Treat single/dual differently than baseline
        if typ < 3
            fprintf('Processing %s %s data for ID %d of %d (%s) \n', grasp, typeNames{typ}, ii, numel(IDs), IDs{ii})
            tarIdx = TypeTargs(:,typ);

          

            configFile = regexp(dirContents(tarIdx), '(?<=_)[a-z](?=_)', 'match');
            
            % Accomodate participants that have multiple folders for same task
            % TODO: cleanup data to avoid issue, as this code naively
            % selects the first folder
            if length(configFile) > 1
                configFile = configFile(1);
                fprintf("Participant has multiple data folders. Choosing config:\n")
                fprintf("%s\n",configFile{1});
            end
            
            fileDir = strcat(dirLook, slashChar, dirContents(tarIdx), slashChar);
            % Accomodate participants that have multiple folders for same task
            % TODO: cleanup data to avoid issue, as this code naively
            % selects the first folder (see participants: b4hxw6g,vlfwh64)
            if size(fileDir,1) > 1
                fileDir = strip(fileDir(1,:));
                fprintf("Participant has multiple data folders. Choosing:\n")
                fprintf("%s\n",fileDir);
            end
            
            
            
            if ~IsOSX
                fileDir = char(fileDir);
            end
            T = GetExpSummaryData(fileDir);
            Config = repelem(configFile, height(T), 1);
            Grasp = repelem({grasp},height(T), 1);
            Mode = repelem(typeNames(typ), height(T), 1);
            T = addvars(T, Grasp, Mode, Config, 'After', 'participant');
            TrialParams.(char(IDs(ii))).([grasp, typeNames{typ}]) = T;
            
            

            
        else
            % Read and save Baseline data but not processed
            fprintf('Processing %s data for ID %d of %d \n', typeNames{typ}, ii, numel(IDs))
            tarIdx = TypeTargs(:,typ);

            configFile = regexp(dirContents(tarIdx), '(?<=_)[a-z](?=_)', 'match');
            fileDir = strcat(dirLook, slashChar,dirContents(tarIdx), slashChar);
            if ~IsOSX
                fileDir = char(fileDir);
            end
            
            T = GetExpSummaryData(fileDir);
            Config = repelem(configFile, height(T), 1);
            Grasp = repelem({grasp},height(T), 1); 
            Mode = repelem(typeNames(typ), height(T), 1);
            T = addvars(T, Grasp, Mode, Config, 'After', 'participant');
            TrialParams.(char(IDs(ii))).(typeNames{typ}) = T;
        
        end
        
    end
    
end

fprintf('Data import complete! \n')

tableData = cell(numel(IDs),3);

for jj = 1:numel(IDs)
    tableData(jj,:) = struct2cell(TrialParams.(char(IDs(jj))));
end
tableData = reshape(tableData', [], 1);
TrialParamsOut = vertcat(tableData{:});
dt = char(datetime('now', 'Format','yyyy-MMM-dd-HH:mm'));
dt = strrep(dt, ':', '');
fPath = '~/Nextcloud/Grasp-Working-Memory/Analysis/Output/';
fName = strcat(fPath, 'GraspWM-wmM-Data-', dt, '.csv');
writetable(TrialParamsOut, fName);


return
end





function TrialParamsTable = GetExpSummaryData(fileDir) 

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
TrialParamsTable = cell2table(convertedout,'VariableNames', headerNames);


% The TrialCount variable in the data files count trial numbers within
% blocks, including bad trials. For later identification and checking that
% tparams rows align with tfsdat we add a TrialCount variable to tparams
% before removing bad trials marked 2
TrialParamsTable.TrialCount = nan([size(TrialParamsTable,1)],1);
for block = 0:max(TrialParamsTable.BlockNum)
    TrialParamsTable.TrialCount(TrialParamsTable.BlockNum == block) = (1:sum(TrialParamsTable.BlockNum == block))';
end

TrialParamsTable = movevars(TrialParamsTable,'TrialCount','After','BlockNum');

return

end