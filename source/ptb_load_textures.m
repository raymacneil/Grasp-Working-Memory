function [ stim_textures ] = ptb_load_textures(ptb, stim_dir, img_names, img_formats, img_pads)
%ptb_loadtextures % Load each stimulus image as a PsychToolbox texture

if ~exist('ptb', 'var') || isempty(ptb)
    error("Must provide argument ptb for the Psychtoolbox Window to draw textures.")
    return;
end
    
if (exist('stim_dir', 'var') && ~isempty(stim_dir)) && (~exist('img_names', 'var') || isempty(img_names))
    error("If argument for stim_dir provided, then must also specify image names.")
    return;
end

if ~exist('stim_dir', 'var') || isempty(stim_dir)
   stim_dir =  'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\stimuli2\';
end

if ~exist('img_names', 'var') || isempty(img_names)
   img_dir_struct = dir(stim_dir);
   img_fnames = string({img_dir_struct.name});
   img_fnames = img_fnames(~startsWith(img_fnames, '.'));
   img_fnames = cellfun(@(x) strsplit(x, '.'),... 
       cellstr(img_fnames), 'UniformOutput', false);
   img_fnames = vertcat(img_fnames{:});
   img_names = string(img_fnames(:,1));
   ext = strcat(string(repelem({'.'},numel(img_fnames(:,2)),1)),...
       string(lower(img_fnames(:,2))));  
   img_fnames =  strcat(img_names, ext); %#ok<NASGU>
end

if ~exist('img_pads', 'var') || isempty(img_pads)
   img_pads = 0; 
   img_pads = repelem(img_pads, numel(img_names));
end

if ~exist('img_formats', 'var') || isempty(img_formats)
    img_formats = {'.png'};
end

% store handles in a Map object
stim_textures = containers.Map;

warning off MATLAB:imagesci:png:libraryWarning

for ii=1:length(img_names)
    % Retrieve name of stimulus image
    img_name = char(img_names(ii));
    img_fname = [];
    
    for ff = 1:length(img_formats)
        fn = [stim_dir img_name char(img_formats{ff})];
        if exist(fn, 'file') == 2
            img_fname = fn;
        end
    end
    
    if isempty(img_fname)
        sca;
        error(['Could not load stimulus image \"%s\" \n' ...
               'Please check your config file and stimulus directory.\n'...
               'Exiting...'], img_name);
    end
    
    % Load image using imread(), save colormap and alpha channel
    % for further processing if needed
    [img, ~, alpha] = imread(img_fname);
    
    if img_pads(ii) ~= 0
        img = padarray(img, [img_pads(ii) img_pads(ii)], 255, 'both');
        alpha = padarray(alpha, [img_pads(ii) img_pads(ii)], 0, 'both');
    end
    
    if ~isempty(alpha)
        % Add alpha channel to image matrix
        img = cat(3, img, alpha);
    end
    
    % Make the image into a texture, save object handle as property
    h = Screen('MakeTexture', ptb.window, img);
%     h = img;
    
    % Add image name and texture handle to Map for later display
    stim_textures(img_name) = h;
end

end

