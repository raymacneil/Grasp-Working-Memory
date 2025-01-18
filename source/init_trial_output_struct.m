% Initiates the the trial output structure for writing data to the results
% summary CSV file, via outputTrialRow().
% Takes a single input, namely the trial_dat structure that is generated in
% graspWM_trials.

function trial_out = init_trial_output_struct(trial_dat)

trial_out = struct;
trial_out.trial_start_time = NaN;
trial_out.reach_time = NaN; trial_out.return_time = NaN;
trial_out.reach_vel = NaN; trial_out.return_vel = NaN;
trial_out.reach_dir = NaN; trial_out.return_dir = NaN;
trial_out.wm_response_time = NaN;
trial_out.bar_angle = trial_dat.bar_angle;
trial_out.bar_length = trial_dat.bar_length;
trial_out.tgt_collision = NaN;
trial_out.wm_resp_digits = 'NaN';
trial_out.wm_resp_motor = 'NaN';
trial_out.wm_onset_time = trial_dat.wm_init_time;
trial_out.wm_tgt = trial_dat.wm_stimulus{:}; 
trial_out.wm_tgt_pos = trial_dat.wm_position;
trial_out.wm_stim_frames = trial_dat.wm_stim_frames;
trial_out.wm_modality = trial_dat.wm_modality;
trial_out.wm_nback_digit_correct = trial_dat.wm_nback_digit_correct;
% replace_str = ["Back", "Front"];
% if ~(strcmp(trial_dat.wm_nback_motor_stim_ref, 'NA'))
%     wm_ref_stim_id = trial_dat.wm_nback_motor_stim_ref{:};
%     regexp_ref_stim_id = string(regexp(wm_ref_stim_id, '(?<=-)[a-zA-Z]*', 'match'));
%     rsIdx = ~(regexp_ref_stim_id == replace_str);
%     wm_ref_stim_id = char(strrep(wm_ref_stim_id, regexp_ref_stim_id,...
%         replace_str(rsIdx)));
%     
% end
% assignin('base', 'trial_out', trial_out);
% assignin('base', 'trial_dat', trial_dat);
% error('FATAL! The world is melting!');

trial_out.wm_nback_motor_stim_ref = trial_dat.wm_nback_motor_stim_ref{:};
trial_out.wm_nback = trial_dat.wm_nback;
trial_out.wm_task_is_dual = trial_dat.wm_task_is_dual;
trial_out.wm_rpt = trial_dat.wm_rpt;


end