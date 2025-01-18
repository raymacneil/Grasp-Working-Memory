function ReWriteOptkTFs(out, trialInfo)

fileNames = trialInfo{1,1};
tinfo = trialInfo{1,2};

NDIDatHeaderTF = ['BlockNum,','TrialNum,','TrialCount,',...
                            'RepeatFlag,','SampleRate,',...
                            'Mkr1_x,','Mkr1_y,','Mkr1_z,',...
                            'Mkr2_x,','Mkr2_y,','Mkr2_z,',...
                            'Mkr3_x,','Mkr3_y,','Mkr3_z,',...
                            'Mkr4_x,','Mkr4_y,','Mkr4_z,',...
                            'Mkr5_x,','Mkr5_y,','Mkr5_z,',...
                            'Mkr6_x,','Mkr6_y,','Mkr6_z\n'];

path = 'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\Data\na0vk4h\grasp_wm_b_rewrite';

for ii = 1:numel(out)
current_trial = out{ii};
current_trial_info = tinfo(ii,:);
nsamples_current_trial = size(current_trial,1);
current_trial_info_expand = single(repmat(current_trial_info, nsamples_current_trial, 1));
current_trial(1:size(current_trial_info_expand,1),1:size(current_trial_info_expand,2)) = current_trial_info_expand; 
current_trial_fname = fileNames{ii};
ffpath = fullfile(path,current_trial_fname);
fid = fopen(ffpath, 'w');
fprintf(fid, NDIDatHeaderTF);
fclose(fid);
dlmwrite(ffpath,current_trial,'-append','delimiter',...
    ',','newline','pc','precision',12);    
end
                        
                        
disp('Sucess')                        
                        
                        
end