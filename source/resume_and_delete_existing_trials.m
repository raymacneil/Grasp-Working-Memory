function resume_and_delete_existing_trials(old_data_path, last_block)
dir_str = dir(old_data_path);
dir_str_folders = {dir_str.name}'
optkFolders = {'OTCReorganized';
               'OTCReorganizedTF'};
optkFoldersExist = intersect(dir_str_folders, optkFolders);               

if numel(optkFoldersExist) == optkFolders
    
    for ii = 1:numel(optkFolders)
        fullPath = fullfile
        
        
    end
end



end