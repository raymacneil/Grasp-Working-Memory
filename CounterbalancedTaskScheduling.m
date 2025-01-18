% % Counterbalancing Task Schedule 
% tasks = ["RG1", "RG2", "PG1", "PG2"];
% taskPerms = perms(tasks);
% wmBaselineString = repmat([repelem("Start",3,1); repelem("End",3,1)], size(taskPerms,1)/6, 1);
% taskSchedule = [transpose(1:24), taskPerms, wmBaselineString];
% taskScheduleCopy = taskSchedule;
% % sortOrderInit = 1:6:size(taskSchedule,1);
% % sortOrder = reshape(flipud(transpose(repmat(sortOrderInit,6,1) + repelem(transpose(0:5),1,4))),[],1);
% % taskSchedule = taskSchedule(sortOrder,:); 
% % temp = strings(size(taskSchedule,1), size(taskSchedule,2));
% % MixIdx1 = reshape(MixIdx1(:,1:2:size(MixIdx1,2)),[],1);
% % MixIdx2 = setdiff(transpose(1:size(taskSchedule,1)), MixIdx1,'rows', 'legacy');
% % temp(1:(size(temp,1)/2),:) = taskSchedule(MixIdx2,:);
% % temp((size(temp,1) / 2 + 1):end,:) = taskSchedule(MixIdx1,:);
% 
% taskSchedule = array2table(taskSchedule,'VariableNames',{'ID','Task1', 'Task2','Task3','Task4','wmBaseTrials'});
% writetable(taskSchedule, 'grasp-wm-task-schedule.xlsx');
% 
% 
% % Generate Configs
% addpath('C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\source')
% stimNames = GetStimNames();
% stimNames = stimNames(~contains(stimNames(:,1),'Two-2-5-'),1);
% stimCombs = combinations(stimNames(1:3), stimNames(4:6), stimNames(7:9));
% numUniqueStim = 9;
% 
% path = 'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\Config_Files';
% cd(path)
% t = readtable('a_tconfig_grasp_wm_dual.csv');
% tstim = t(t.block_num >0,:);

rng(123,'twister')
seed = rng;

% Counterbalancing Task Schedule 
container = cell(2,1);
tasksRG = ["RG1", "RG2", "WM"];
tasks = tasksRG;
taskPerms = repmat(Shuffle(perms(tasks),2),2,1);

configs = ["a","f"; "c","d"; "b","e"; "c","e"; "a","d"; "b","f";...
 "f","a"; "d","c"; "e","b"; "e","c"; "d","a"; "f","b"];

% configs = combinations({'a','b','c'},{'d','e','f'});
% config_select_idx = NaN;
% while numel(unique(config_select_idx)) ~= size(perms(tasks),1)
%     config_select_idx = randi(9,6,1);
% end
% selected_configs = string([configs(config_select_idx,:); 
%     fliplr(configs(config_select_idx,:))]);
single_configs = strings(size(configs,1),1);
for ii = 1:size(configs)
    choice = setdiff(["a","b","c","d","e","f"],configs(ii,:));
    choice_idx = randi(4,1,1);
    single_configs(ii) = choice(choice_idx);
end
taskPermsPG = strrep(taskPerms,"R","P");
taskSchedule = array2table([taskPerms; taskPermsPG],'VariableNames',{'Task1', 'Task2','Task3'}); 
% writetable(taskSchedule, 'grasp-wm-task-schedule-updated-3.xlsx');
temp = strings(24,6);

taskSchedule = [transpose(1:24), taskPerms, wmBaselineString];
taskScheduleCopy = taskSchedule;
% sortOrderInit = 1:6:size(taskSchedule,1);
% sortOrder = reshape(flipud(transpose(repmat(sortOrderInit,6,1) + repelem(transpose(0:5),1,4))),[],1);
% taskSchedule = taskSchedule(sortOrder,:); 
% temp = strings(size(taskSchedule,1), size(taskSchedule,2));
% MixIdx1 = reshape(MixIdx1(:,1:2:size(MixIdx1,2)),[],1);
% MixIdx2 = setdiff(transpose(1:size(taskSchedule,1)), MixIdx1,'rows', 'legacy');
% temp(1:(size(temp,1)/2),:) = taskSchedule(MixIdx2,:);
% temp((size(temp,1) / 2 + 1):end,:) = taskSchedule(MixIdx1,:);

taskSchedule = array2table(taskSchedule,'VariableNames',{'ID','Task1', 'Task2','Task3'});
writetable(taskSchedule, 'grasp-wm-task-schedule.xlsx');


% Generate Configs
addpath('C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\source')
stimNames = GetStimNames();
stimNames = stimNames(~contains(stimNames(:,1),'Two-2-5-'),1);
stimCombs = combinations(stimNames(1:3), stimNames(4:6), stimNames(7:9));
numUniqueStim = 9;

path = 'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\Config_Files';
cd(path)
t = readtable('a_tconfig_grasp_wm_dual.csv');
tstim = t(t.block_num >0,:);










