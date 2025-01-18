function WriteAllMetrics(AllMetrics,fileName)

if nargin < 2 || ~exist('fileName', 'var')
    dt = char(datetime('now', 'Format','yyyy-MMM-dd-HH:mm'));
    dt = strrep(dt, ':', '');
    fileName = strcat('GraspWM-Data-', dt, '.mat');
    fileName = getDownloadsPath(fileName);
end
        

    T = table;
    Tidx = 1;
    
    % If NG data exists, write all data for all NG participants
    if ~isempty(AllMetrics(1,1,1))
        for jj = 1:nnz(~cellfun('isempty', AllMetrics(1,:,1))) % Cycle through all NG participants
            temp = vertcat(AllMetrics{2,jj,1:2});
            T(Tidx:(Tidx + height(temp) - 1),:) = temp;
            Tidx = Tidx + height(temp);
        end
    end
    
    % If PG data exists, write all data for all PG participants
    if ~isempty(AllMetrics(1,1,3))
        for jj = 1:nnz(~cellfun('isempty', AllMetrics(1,:,3))) % Cycle through all PG participants
            temp = vertcat(AllMetrics{2,jj,3:4});
            T(Tidx:(Tidx + height(temp) - 1),:) = temp;
            Tidx = Tidx + height(temp);
        end
    end

    writetable(T,fileName);

end


function downloadPath = getDownloadsPath(fileName)
    % Get the operating system type
    if ispc()
        % Windows: Use USERPROFILE environment variable
        rootDir = getenv('USERPROFILE');
        downloadPath = fullfile(rootDir, 'Downloads', fileName);
    elseif ismac()
        % macOS: Downloads folder is in the user's home directory
        rootDir = getenv('HOME');
        downloadPath = fullfile(rootDir, 'Downloads', fileName);
    else
        % Linux/Unix: Similar to macOS
        rootDir = getenv('HOME');
        downloadPath = fullfile(rootDir, 'Downloads', fileName);
    end
    
    % Verify the Downloads directory exists
    downloadsDir = fileparts(downloadPath);
    if ~exist(downloadsDir, 'dir')
        error('Downloads directory not found at: %s', downloadsDir);
    end
end

