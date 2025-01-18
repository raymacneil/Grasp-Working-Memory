function [row_ct, out] = write_data_skipped_practice_block(out, block_dat, trial_list, bad_trials, bn, part_dems, row_ct)

is_practice_block = true;
skip_practice = 1;
num_trials = length(trial_list);

for ii = 1:num_trials
    

        t = ii;
        % Collect all trial numbers
        tn = trial_list(t);

        % Retrieve vars for current trial
        trial_row_in_block_dat = block_dat.trial_num == tn;
        if nnz(trial_row_in_block_dat) > 1
            trial_row_in_block_dat(1:t-1) = false;
        end
        trial_dat = block_dat(trial_row_in_block_dat, :);

        % Initiate output structure
        trial_out = struct;
        trial_out.trial_start_time = NaN;
        trial_out.reach_time = NaN; trial_out.return_time = NaN;
        trial_out.reach_vel = NaN; trial_out.return_vel = NaN;
        trial_out.reach_dir = NaN; trial_out.return_dir = NaN;
        trial_out.bar_angle = trial_dat.bar_angle;
        trial_out.bar_length = trial_dat.bar_length;
        trial_out.tgt_collision = NaN;
        trial_out.wm_resp_digits = 'NaN';
        trial_out.wm_resp_motor = 'NaN';
         trial_out.wm_response_time = NaN;
        trial_out.wm_onset_time = trial_dat.wm_init_time;
        trial_out.wm_tgt = trial_dat.wm_stimulus{:};    
        trial_out.wm_tgt_pos = trial_dat.wm_position;
        trial_out.wm_nback_motor_stim_ref = trial_dat.wm_nback_motor_stim_ref{:};
        trial_out.wm_stim_frames = trial_dat.wm_stim_frames;
        trial_out.wm_modality = trial_dat.wm_modality;
        trial_out.wm_nback_digit_correct = trial_dat.wm_nback_digit_correct;
        trial_out.wm_nback = trial_dat.wm_nback;
        trial_out.wm_task_is_dual = trial_dat.wm_task_is_dual;
        trial_out.wm_rpt = trial_dat.wm_rpt;
        
        [row_ct, out] = outputTrialRow(row_ct, out, part_dems, ...
                                        bn, is_practice_block,...
                                        skip_practice, tn, t,... 
                                        bad_trials, trial_out);
                
end

end