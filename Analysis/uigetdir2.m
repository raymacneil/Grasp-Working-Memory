function [pathname] = uigetdir2(start_path, dialog_title)
% Pick multiple directories and/or files



import javax.swing.JFileChooser;

% if nargin < 1 || ~exist(start_path, 'var')
if nargin < 1
    start_path = 'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\Data';
elseif nargin < 2
    if isnumeric(start_path) % Allow a null argument.
        start_path = pwd;
    end
end

jchooser = javaObjectEDT('javax.swing.JFileChooser', start_path);

jchooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
if nargin > 1
    jchooser.setDialogTitle(dialog_title);
end

jchooser.setMultiSelectionEnabled(true);

status = jchooser.showOpenDialog([]);

if status == JFileChooser.APPROVE_OPTION
    jFile = jchooser.getSelectedFiles();
	pathname{size(jFile, 1)}=[];
    for i=1:size(jFile, 1)
		pathname{i} = char(jFile(i).getAbsolutePath);
	end
	
elseif status == JFileChooser.CANCEL_OPTION
    pathname = [];
else
    error('Error occured while picking file.');
end
