function results = nback_trial_recycling_dev()

addpath('C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\source')
path = 'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\Config_Files\Digits';
targetConfig = 'a_tconfig_grasp_wm_digits_dual.csv';
config_dat_fname = fullfile(path, targetConfig);
config_dat = readtable(config_dat_fname);
results = table();

% Set output row counter to 1
row_ct = 1; 
% Get list of blocks from config file
blocks = unique(config_dat.block_num);
num_blocks = length(blocks);



for b = 1:num_blocks

    
% Retrieve block rows for current block
bn = blocks(b);
idx_block_trials = (config_dat.block_num == bn);
block_dat = config_dat(idx_block_trials, :);

% Get number of trials in block
block_size = nnz(idx_block_trials);

% Determine if next and current blocks are practice
current_block_is_practice = any(block_dat.is_practice_block);


% preallocate empty vector
bk_nback_digit_correct = NaN(block_size,1);
bk_nback_motor_stim_ref = cell(block_size,1);
bk_nback_motor_stim_ref(1:end) = repelem({'NA'},block_size,1);
bk_stim_id = block_dat.wm_stimulus;
block_dat.wm_rpt = zeros(block_size,1);
wm_modality = unique(block_dat.wm_modality);
wm_modality = wm_modality{:};
block_dat.wm_nback_digit_correct = bk_nback_digit_correct;
block_dat.wm_nback_motor_stim_ref = bk_nback_motor_stim_ref;

% Is n-back response required: not applicable to single task NG and RG
nback_response_required = any(~isnan(block_dat.wm_nback));

if nback_response_required
    exp = '[a-zA-Z]*(?=-)';
    bk_stim_digits_tag = regexp(bk_stim_id, exp, 'match');
    bk_stim_digits_tag = vertcat(bk_stim_digits_tag{:});
    [~, bk_stim_digits_num] = ismember(bk_stim_digits_tag, {'Two', 'Three', 'Four'});
    bk_stim_digits_num = bk_stim_digits_num + 1;
    bk_nback = unique(block_dat.wm_nback(~isnan(block_dat.wm_nback)));
    bk_nback_resp_trials = find(~isnan(block_dat.wm_nback));
    bk_correct_idx = bk_nback_resp_trials - bk_nback; % "Determine-if-correct reference" index
    
    % For Digits Task
    bk_nback_digit_correct(bk_nback_resp_trials) = bk_stim_digits_num(bk_correct_idx);
    % For Motor Task
    bk_nback_motor_stim_ref(bk_nback_resp_trials) = ...
        strrep(bk_stim_id(bk_correct_idx),'Back','Front');
    
    
    % These default to NaN (digits) and 'NA' (motor), respectively.
    if strcmp(wm_modality, 'digits')
        block_dat.wm_nback_digits_correct = bk_nback_digit_correct;
    elseif strcmp(wm_modality, 'motor')
        block_dat.wm_nback_motor_stim_ref = bk_nback_motor_stim_ref;
    end
    
    
    if b < num_blocks % If it's not the last block
        
        idx_next_block_trials = (config_dat.block_num == (bn+1));
        next_block_dat = config_dat(idx_next_block_trials, :);
        next_bn_nback = unique(next_block_dat.wm_nback(~isnan(next_block_dat.wm_nback)));
        
        
        if current_block_is_practice
            msgs.practiceStartMsg = strcat('Now beginning practice block.',...
                ['\n\nN-Back = ', num2str(bk_nback), '\n\nPress ''Space'' Key To Continue',...
                '\n\nPress ''s'' Key to Skip Practice.']);
            msgs.blockEndMsg =  strcat('Practice Block Finished',...
                '\n\nNext Block, N-Back = ', num2str(next_bn_nback),...
                '\n\nPress Any Key To Continue');
        else
            msgs.blockEndMsg =  strcat('Block Finished.',...
                '\n\nNext Block, N-Back = ', num2str(next_bn_nback),...
                '\n\nPress Any Key To Continue');
        end  % current_block_is_practice
        
    end % b < num_blocks
       
    
    % Set appropriate EXPERIMENTER PROMPT MESSAGE for collecting WM Response
    if strcmp(wm_modality, 'digits') % Digits task
        msgs.prompt_wm_response = strcat('Participant to indicate \n\nnumber of extended digits.\n\n',...
            'N-Back = ', num2str(bk_nback));
    elseif strcmp(wm_modality, 'motor') % Motor task
        msgs.prompt_wm_response = strcat('Participant is to reproduce \n\nthe hand posture.\n\n',...
            'N-Back = ', num2str(bk_nback), '\n\n"1" Incorrect, "2" Correct');
    end
    
else % if not nback_response_required

    bk_nback = NaN;
end % nback_response_required



trial_list = unique(block_dat.trial_num);

% Calculate total number of trials
num_trials = length(trial_list);
% Create vector to flag bad trials for repeat at end of block
bad_trials = zeros(num_trials,1);

% Display practice block message, if applicable
% Set trial counter
t = 1;
block_complete = false;

fprintf('\nIt is block number %d with n-back = %d. \n', bn, bk_nback);
fprintf('Press any key to continue... \n')
 KbPressWait;
clc;

while ~block_complete
    
    % If all trials have been presented
    if t > num_trials
        block_complete = true;
        continue
    end
    
    
    % -- Pre-trial initialization: event schedules, calculate masks --
    % Collect all trial numbers
    tn = trial_list(t);
    
    % Retrieve vars for current trial
    trial_row_in_block_dat = block_dat.trial_num == tn;
    trial_row_in_block_dat(1:t-1) = false;
    trial_dat = block_dat(trial_row_in_block_dat, :);
 
%     wm_init_time = (trial_dat.wm_init_time / 1000);
%     wm_stim_id = trial_dat.wm_stimulus{:};
%     wm_stim_position = trial_dat.wm_position;
%     wm_stim_frames = trial_dat.wm_stim_frames;
%     wm_modality = trial_dat.wm_modality;
%     wm_task_is_dual = trial_dat.wm_task_is_dual;
%     wm_nback_id = trial_dat.wm_nback;
%     wm_rpt = trial_dat.wm_rpt;
    
   
    
    
    trial_out = init_trial_output_struct(trial_dat);
    
    
    % Get initial hand positions
    
    
    % Flip and sync us to the vertical retrace, store trial start time
    trial_out.trial_start_time = GetSecs;
    last_frame = trial_out.trial_start_time;

    

    in_WM_feedback_loop = false;
    in_WM_resp_loop = false;
    in_trial_loop = true;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% ******************** %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% *** ACTION LOOP **** %%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% ******************** %%%%%%%%%%%%%%%%%%%%%%%
    txt = "";
    prompt = sprintf('Simulate an in-reach error for bk = %d, tn = %d, and t = %d? [y/n]: ',... 
        bn, tn, t);
    
    while ~ismember(txt, ["y", "n"])
        txt = input(prompt, 's');
        txt = string(txt);
        if txt == "y"
            bad_trials(t) = 1;
        elseif txt == "n"
            bad_trials(t) = 0;
        else
            fprintf('\nInvalid input, please indicate yes (''y'') or no (''n''). \n');
        end
    end
    
    WaitSecs(0.5);
    
    
    if bad_trials(t) == 0
        
        txt = "";
        prompt = sprintf('Simulate bad trial (5) for bk = %d, tn = %d, and t = %d? [y/n]: ',...
            bn, tn, t);
        
        while ~ismember(txt, ["y", "n"])
            txt = input(prompt,'s');
            txt = string(txt);
            if txt == "y"
                bad_trials(t) = 1;
            elseif txt == "n"
                bad_trials(t) = 0;
            else
                fprintf('Invalid input, please indicate yes (''y'') or no (''n''). \n')
            end
        end
        
    end
    
    
    
%     if bad_trials(t) ~= 0
%         % Play low sine tone for 300ms (note: does not pause program)
%         Beeper(256, 1.0, 0.3);
%         WaitSecs(0.3); % pause manually to wait for Beeper to finish
%     end
    
    
    
    
    if bad_trials(t) ~= 0
        
        num_remaining_trials = size(block_dat,1) - t;
        
        if nback_response_required && ~isnan(bk_nback) && (bk_nback > 0)
            
            no_response_required_nan = isnan(block_dat.wm_nback(t));
            [block_dat, trial_list, num_trials_redo] = nback_recycler(block_dat,...
                trial_list, t, bk_nback, num_remaining_trials,...
                no_response_required_nan, wm_modality);
            bad_trials = [bad_trials; repelem(0, num_trials_redo, 1)]; %#ok<AGROW>
            num_trials = num_trials + num_trials_redo;
            
        else
            
            if num_remaining_trials == 0
                bad_trial_redo_idx = t;
            else
                bad_trial_redo_idx = randi(num_remaining_trials)+t;
            end
            
            block_dat = [block_dat(1:bad_trial_redo_idx,:); block_dat(t,:);...
                block_dat(bad_trial_redo_idx+1:end,:)];
            trial_list = [trial_list(1:bad_trial_redo_idx)' trial_list(t)...
                trial_list(bad_trial_redo_idx+1:end)']';
            bad_trials = [bad_trials; 0]; %#ok<AGROW>
            num_trials = num_trials + 1;
            
        end % is_nback && bn_nback > 0
        
    end % bad_trials(t) ~= 0
    
    % Increment trial counter
    t = t + 1;
    
end % while ~block_complete
results = [results; block_dat]; %#ok<AGROW>

end


end




    
