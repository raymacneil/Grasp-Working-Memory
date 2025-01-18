function [out, mkrInfo, GetCOLSlabel, trialInfo] = GetOptkTFs2(fileDir, fileNames, MKRnums, DIMS) 


%% Exception and Error Handling

% disp('Processing request...')
% fileDir = dirLook;
% MKRnums = 1:6;
% DIMS = 'xy';
if nargin < 2 || ~exist('fileDir', 'var')
% Use GUI for file lookup
[fileNames,fileDir]=uigetfile('MultiSelect','On','*tf.txt');
end


if nargin < 3 || ~exist('MKRnums', 'var') || isempty(MKRnums)
    warning('No argument supplied for MKRnums or DIMS. Using default values.');
    MKRnums = 1:6;
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




%% Get the file count
FILEcount = numel(fileNames); 

% Account for case of single trial selection
if FILEcount == 1
    fileNames = cellstr(fileNames);
end

%% Sort by trial number
unnest = @(y) vertcat(y{:});
fileNames = transpose(fileNames);
tNums = str2num(char(unnest(cellfun(@(x) regexp(x, '(?<=t)\d{3}(?=_)', 'match'),...
    fileNames, 'UniformOutput', false))));
bNums = str2num(char(unnest(cellfun(@(x) regexp(x, '(?<=bn)\d{2}(?=_)', 'match'),...
    fileNames, 'UniformOutput', false))));
tnNums = str2num(char(unnest(cellfun(@(x) regexp(x, '(?<=tn)\d{3}(?=_)', 'match'),...
    fileNames, 'UniformOutput', false))));
rpNums = str2num(char(unnest(cellfun(@(x) regexp(x, '(?<=rp)\d{2}(?=_)', 'match'),...
    fileNames, 'UniformOutput', false)))); %#ok<*ST2NM>
trialInfo = [bNums,tnNums,tNums,rpNums];
tinfo = cell(1,2);
tinfo{1,1} = fileNames;
tinfo{1,2} = trialInfo;
trialInfo = tinfo;


% [Y, NDX] = SortCell(temp, [1,2]) 
% look = cellfun(@(x) regexp(x, '\d{2}', 'match'),...
%     bNums, 'UniformOutput', true);
% [Y, NDX] = SortCell(temp, [1,2]) 
% look = cellfun(@(x) str2num( regexp(x, '\d{2}', 'match') ),...
%     Y(:,1), 'UniformOutput', false);
% look2 = vertcat(look{:});
%     
% [~, sortORDER] = sortrows(cellfun(@(x) regexp(x, 't\d{3}(?=_)', 'match'),...
%     fileNames, 'UniformOutput', false), 'ascend');
% fileNames = fileNames(sortORDER);


%% Create regular expressions to specify columns to retain for data import
MKRSexp = strcat('[', erase(num2str(MKRnums), ' '), ']');
DIMSexp = strcat('[', DIMS, ']');
GENexp =  strcat('Mkr', MKRSexp, '_', DIMSexp);
anyMKRexp = strcat('Mkr', '[0-9]+', '_', '[xyz]');

%% Get header from one of the trials and determine relevant column indices
fid = fopen(fullfile(fileDir, fileNames{1}),'r');
headerNames = strsplit(fgetl(fid), ',');
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
    
    catch ME
        rethrow(ME);
    
    end
    
end

end


