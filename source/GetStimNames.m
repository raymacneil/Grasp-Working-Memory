function [ out ] = GetStimNames(print)

if nargin < 1
    print = false;
end
   stim_dir = 'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\stimuli2';  
   img_dir_struct = dir(stim_dir);
   img_fnames = string({img_dir_struct.name});
   img_fnames = img_fnames(~startsWith(img_fnames, '.'));
   img_fnames = cellfun(@(x) strsplit(x, '.'),... 
       cellstr(img_fnames), 'UniformOutput', false);
   img_fnames = vertcat(img_fnames{:});
   img_names = string(img_fnames(:,1));
   ext = strcat(string(repelem({'.'},numel(img_fnames(:,2)),1)),...
       string((img_fnames(:,2))));  
   img_fnames =  flipud(strcat(img_names, ext)); %#ok<NASGU>
   img_names =  flipud(img_names); 
   
   % Seperate Front and Back Viewpoint into Separate Columns
   idx = contains(img_names, 'Back');
   img_names = [img_names(idx), img_names(~idx)];
   out = img_names;
   if print
       fileID = fopen('stimuli\fNamesForStim.csv', 'w+');
       fSpec = '%s,%s\n';
       fprintf(fileID,fSpec,"Back", "Front");
       
       for ii = 1:length(out)
           fprintf(fileID,fSpec,out(ii,1),out(ii,2));
       end
       fclose(fileID);
   end
       
end



