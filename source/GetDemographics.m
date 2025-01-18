function [part_dems, config_dat] = GetDemographics(out_path, exp_name)
%GetDemographics Get participant demographics (handedness, gender, age)

% Init output structure
fname = '';
part_dems = struct();
config_dat = [];
% demog_dat = [];

% Read demographics file to check if participant ID has already been used
demog_fname = [out_path 'Demographics_' exp_name '.csv'];

% If demorgraphics file does not already exist, then create one and output
% header row
if ~exist(demog_fname, 'file')
%        demog_header = 'ParticipantID,Task,WorkMemoryResp,Gender,Age,ConfigFile,ExperimentTime';
%        fSpec = '%s,';
    demog_header = ["ParticipantID", "Experiment", "Task", "Gender",... 
        "Age", "MaxGripAperture", "ConfigFile", "ExperimentTime"];

    fid = fopen(demog_fname,'wt');
    fSpec = [repmat('%s,',1,numel(demog_header)-1), '%s\n'];
    
    if fid>0
       fprintf(fid,fSpec,demog_header);
       fclose(fid);
    end
    demog_dat = readtable(demog_fname);
    get_new_dems = 1;
else
    % Read demographics table
    demog_dat = readtable(demog_fname);
    opts.Interpreter = 'tex';
    opts.Default = 'Cancel';
    % If there is existing data, prompt to continue with last participant
    if size(demog_dat,1) > 0
        last_subj_id = demog_dat.ParticipantID(end);
        old_part_message = sprintf('Continue with last used participant ID (\\bf%s\\rm), or start new participant?', cell2mat(last_subj_id));
        old_id_answer = questdlg(old_part_message, 'Participant ID', ...
                          'Use last', 'New Participant', 'Cancel', opts);
        switch old_id_answer
            % If use last, load old participant data from last used row
            case 'Use last'
                part_id = last_subj_id;
                part_g = cell2mat(demog_dat.Gender(end));
                part_age_resp = {num2str(demog_dat.Age(end))};
                part_mga_resp = demog_dat.MaxGripAperture(end);
                part_sign_resp = demog_dat.SignLanguage(end);
                get_new_dems = 0;
                
            case 'New Participant'
                get_new_dems = 1;
            case 'Cancel'
                return
        end
    else
        get_new_dems = 1;
    end
end

if get_new_dems
    % Generate subject ID, user may overwrite if desired
    letters = ['a':'z']; %#ok<NBRAK>
    symbols = ['a':'z' '0':'9'];
    MAX_ST_LENGTH = 7;
    ltr = randi(numel(letters));
    nums = randi(numel(symbols),[1 MAX_ST_LENGTH-1]);
    subj_id = [letters(ltr) symbols(nums)];
    part_id = inputdlg('Participant ID (press Ok to continue):','Participant ID',[1 40],{subj_id});

    if isempty(part_id)
        return
    end

    % Get participant gender
    genders = {'Female','Male','Other'};
    [part_g,tf] = listdlg('PromptString','Select Participant''s Gender:',...
       'SelectionMode','single',...
       'ListString',genders);
    if isempty(part_g) || ~tf
        return
    end
    part_g = genders{part_g};

    % Get participant age
    part_age_resp = inputdlg('Enter Participant''s Age:','Age',[1 30],{'99'});
    if isempty(part_age_resp)
        return
    end
    
    % Get participant handedness, abort if not right-handed
    handedness = {'Left','Right'};
    [part_h,tf] = listdlg('PromptString','Select Participant''s Handedness:',...
                               'SelectionMode','single',...
                               'ListString',handedness);
    if isempty(part_h) || ~tf
        return
    elseif part_h == 1
        % Display exception message, abort program
    	opts.Interpreter = 'tex';
        opts.Default = 'Exit';
        questdlg('Participant must be right-hand dominant to take part in this experiment.', ...
                 'Prerequesite Exception', ...
                 'Exit', opts);
        return
    end
    
    % Get participant history of neurological disease, abort if yes
    hist_nd = {'Yes','No'};
    [part_hnd,tf] = listdlg('PromptString','History of Neurological Disease?',...
                               'SelectionMode','single',...
                               'ListString',hist_nd);
    if isempty(part_hnd) || ~tf
        return
    elseif part_hnd == 1
        % Display exception message, abort program
    	opts.Interpreter = 'tex';
        opts.Default = 'Exit';
        questdlg('Participant must have no history of neurological disease to take part in this experiment.', ...
                 'Prerequesite Exception', ...
                 'Exit', opts);
        return
    end
    
    % Get maximum grip aperture (mm)
    part_mga_resp = inputdlg('Enter Participant''s Maximum Grip Aperture (mm):',...
        'Maximum Griper Aperture (mm)',[1 30],{'0'});
    
    
    if ~(str2double(part_mga_resp) > 0)
        opts = struct('WindowStyle','modal',... 
              'Interpreter','tex');
        errordlg('Must measure and enter participant''s maximum grip aperture.',... 
            'Error', opts);
        return
    elseif isempty(part_mga_resp) 
        return
    else % do nothing
    end    
    
    
    % Prompt for knowledge of sign language
    sign_resp = {'No','Yes'};
    [part_sign_resp,tf] = listdlg('PromptString',...
    {'Fluent in any sign',... 
     'language?'}, 'SelectionMode','single',...
       'ListString',sign_resp);
    part_sign_resp = num2str(part_sign_resp-1);
    if isempty(part_sign_resp) || ~tf
        return
    end
    
end


% Get experiment
exps = {'Digits','Motor'};
[part_exp,tf] = listdlg('PromptString','Select experiment...',...
                           'SelectionMode','single',...
                           'ListString', exps);
if isempty(part_exp) || ~tf
    return
end
part_exp = exps{part_exp};


% Get experiment task
exp_tasks = {'NaturalGrasp','Pantomime','BaselineWM'};
[part_task,tf] = listdlg('PromptString','Select experiment task',...
                           'SelectionMode','single',...
                           'ListString', exp_tasks);
if isempty(part_task) || ~tf
    return
end
part_task = exp_tasks{part_task};


% Get working memory response
% wm_modality_labels = {'Digits', 'Motor', 'None'};
% [part_wm_modality,tf] = listdlg('PromptString','Select the working memory response mode',...
%                            'SelectionMode','single',...
%                            'ListString', wm_modality_labels);
% if isempty(part_wm_modality) || ~tf
%     return
% end
% part_wm_modality = wm_modality_labels{part_wm_modality};

% Copy responses for demographics info into output structure
part_dems.id = part_id{1};
part_dems.exp = part_exp;
part_dems.task = part_task;
% part_dems.wm_modality = part_wm_modality;
part_dems.gender = part_g;
part_dems.age = part_age_resp{1};
try
    part_dems.mga = part_mga_resp{1};
catch
    part_dems.mga = part_mga_resp;
end    
part_dems.sign = part_sign_resp;
[config_fname,config_path] = uigetfile(['./Config_Files/', part_exp, '/*.csv'],...
                              'Select an experiment %%config file');                     
config_fname = [config_path config_fname];

if ~ischar(config_fname)
    return
end

% Extract config file name for demographics file
[~, fname, ~] = fileparts(config_fname);

% If necessary, determine if a single or dual-task configuration file has
% been appropriately selected.
exp = '_[a-zA-Z]*(?=.csv)';
match = char(regexp(config_fname, exp, 'match'));

% If the task selected is BaselineWM, i.e. baseline working memory 
% performance without grasping required, ensure that a single-task
% configuration file has been selected.
if strcmp(part_task, 'BaselineWM') && any(strcmp(match, {'_dual', '_single'}))
    error("Must select a configuration file with a ''_baseline'' tag.");
    return 
end

exp_tags = {'digits', 'motor'};
config_exp_id = ['_', exp_tags{ismember(exp_tags, strsplit(fname, '_'))}];

if ~strcmp(['_',lower(part_exp)], config_exp_id) 
    error("Invalid configurtation file for selected experiment.");
end
 
part_dems.config_name = [fname(1) match config_exp_id]; %[fname ext];
% Save date for demographics file
part_dems.experiment_date = char(datetime);

% Read specified config file for this experiment
config_dat = readtable(config_fname);

% If the selected participant ID already exists (including "use last"),
% then ask if we would like to start over or cancel
matches_participant = strcmp(part_dems.id, demog_dat.ParticipantID);
matches_config =  strcmp(part_dems.config_name, demog_dat.ConfigFile);
matches_exp = strcmp(part_dems.exp, demog_dat.Experiment);
matches_task =  strcmp(part_dems.task, demog_dat.Task);

if any(all([matches_participant matches_config matches_exp matches_task],2))
    
    % Include the desired Default answer
    opts.Interpreter = 'tex';
    opts.Default = 'Cancel';
%     part_message = ['Participant \bf' part_dems.id ...
%                    '\rm has existing data for selected experiment, task, and config '...
%                    '\newline \newline' ...
%                    'Would you like to continue, start over (and automatically backup old data), or quit?'];
    part_message = {['\fontsize{9}Participant \bf' part_dems.id '\rm has existing data for selected experiment, task, and configuration file.'],...
                    '',...
                    'Would you like to continue from the last block, start over (auto backup old data), or quit?'};
    answer = questdlg(part_message, 'Participant ID Already Exists!', ...
                      'Continue', 'Start Over', 'Quit', opts);
                  
%   out.part_out_path = [out_path pid '/' exp_name '_' part_dems.config_name '_' part_dems.task '/'];
  
    switch answer
        case 'Continue'
            old_data_path = [out_path part_dems.id '\' exp_name '_' part_dems.config_name '_' part_dems.task '\'];
            old_data_fname = [old_data_path part_dems.id '_' part_dems.config_name '_results_out.csv']; 
%             old_data_fname = [out_path part_dems.id '\' exp_name '_' part_dems.config_name '_' part_dems.task '\' part_dems.id '_' part_dems.config_name '_results_out.csv'];
            old_data = readtable(old_data_fname,'HeaderLines', 0, 'Delimiter',',');
            last_block = old_data{end, 2};
%             last_trial = old_data{end, 3};
            opts2.Interpreter = 'Tex';
            opts2.Default = 'Cancel';
                        
            dialog_config_ref = strrep(part_dems.config_name,'_','\_');
            resume_message = {['\fontsize{9}Resuming experiment with configuration file\bf ' dialog_config_ref '\rm.'],...
                              '',...
                            ['Starting from the beginning of \bfBlock ', num2str(last_block), '\rm.'],...
                              '',...
                            '\bfN.B. \rmExisting trials for this block will be deleted.'};
                            
            resume_answer = questdlg(resume_message, 'Resume Experiment', ...
                             'Resume', 'Cancel', opts2);
            switch resume_answer
                case 'Resume'
                    dat_block_rows = config_dat.block_num == last_block;
%                     dat_trial_rows = config_dat.trial_num == last_trial;
                    resume_row = find(dat_block_rows, 1, 'first');
                    config_dat = config_dat(resume_row:end,:);
                    idx_trials_to_remove = old_data.BlockNum == last_block;
                    old_data_update = old_data(~idx_trials_to_remove,:);
                    PracticeBlock = strcmp(old_data_update.PracticeBlock, 'true');
%                     PracticeBlock = table(strcmp(old_data_update.PracticeBlock, 'true'),'VariableNames', 'PracticeBlock');
                    old_data_update = [old_data_update(:,1:2), table(PracticeBlock), old_data_update(:,4:end)];
                    writetable(old_data_update, old_data_fname); 
                    
       
                    
                case 'Cancel'
                    return
            end
        case 'Start Over'
            try
                old_path = [out_path part_dems.id '/' exp_name '_' part_dems.config_name '_' part_dems.task];
                old_date = getFileDate(old_path);
                old_date = strrep(datestr(old_date),' ','_');
                old_date = strrep(old_date,':','-');
                movefile([old_path '/'],[old_path '_' old_date '/']);
            catch ME
                rethrow(ME);  
            end
        case 'Quit'
            return
    end
end
%----------------------------------------------------------------------%
%                     Write Demographics Information                   %
%----------------------------------------------------------------------%

% Convert demographic info to cell array
demog_data = struct2cell(part_dems);

% Convert all cells to strings
part_demog_data = cellfun(@num2str, demog_data, 'UniformOutput', false);

% Convert to string to easily append with fprintf()
demographic_row = string(part_demog_data);
fSpec = [repmat('%s,', 1, numel(demographic_row)-1), '%s\n'];

% Write line to demographics file
fid = fopen(demog_fname, 'at');
if fid > 0
    fprintf(fid, fSpec, demographic_row);
    fclose(fid);
end


end

