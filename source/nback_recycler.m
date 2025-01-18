function [block_dat, trial_list, num_trials_redo] = nback_recycler(block_dat,... 
    trial_list, t, bn_nback, num_remaining_trials, no_wm_response_required_nan, wm_modality)

if no_wm_response_required_nan
    consec_nan = isnan(block_dat.wm_nback(t+1));
    bad_trials_redo = ( ( t- ( bn_nback - 1 - consec_nan)):t );
    block_dat_redo = block_dat( nonzeros( bad_trials_redo),:);
    bk_end_idx = size(block_dat,1);
    redo_slice_idx = (bk_end_idx - ( bn_nback - 1):bk_end_idx) - bn_nback;
    block_dat_redo.wm_nback( isnan( block_dat_redo.wm_nback)) = bn_nback;
    slice_idx = [true ~consec_nan];
    block_dat_redo.wm_rpt = block_dat_redo.wm_rpt + 1;
 
    
    if strcmp(wm_modality, 'digits') % Update stimulus finger count (Digits Task)
    
        block_dat_redo.wm_nback_digit_correct(isnan(block_dat_redo.wm_nback_digit_correct)) = ...
            StimName2Num(block_dat.wm_stimulus(redo_slice_idx(slice_idx(1:bn_nback))));
        block_dat = [block_dat(1:(end-bn_nback),:);
            block_dat_redo; block_dat((end-(bn_nback-1):end),:)];
        block_dat.wm_nback_motor_stim_ref((end-(bn_nback-1):end),:) = ...
            block_dat.wm_stimulus(redo_slice_idx + numel(bad_trials_redo));
        block_dat.wm_nback_digit_correct((end-(bn_nback-1):end),:) = ...
            StimName2Num(block_dat.wm_stimulus(redo_slice_idx + numel(bad_trials_redo)));
    

    elseif strcmp(wm_modality, 'motor') % Update reference posture stimulus ID (Motor Task)
        
        try
            block_dat_redo.wm_nback_motor_stim_ref(strcmp(block_dat_redo.wm_nback_motor_stim_ref, 'NA')) = ...
                block_dat.wm_stimulus(redo_slice_idx(slice_idx(1:bn_nback)));
%                 strrep(block_dat.wm_stimulus(redo_slice_idx(slice_idx(1:bn_nback))),'Back','Front');
        catch
            assignin('base', 'block_dat', block_dat)
            assignin('base', 'bad_trials_redo', bad_trials_redo)
            assignin('base', 'bk_end_idx', bk_end_idx)
            assignin('base', 'consec_nan', consec_nan)
            assignin('base', 'block_dat_redo', block_dat_redo)
            assignin('base', 'slice_idx', slice_idx)
        end
            
            
        block_dat = [block_dat(1:(end-bn_nback),:);
            block_dat_redo; block_dat((end-(bn_nback-1):end),:)];
        block_dat.wm_nback_motor_stim_ref((end-(bn_nback-1):end),:) = ...
            block_dat.wm_stimulus(redo_slice_idx + numel(bad_trials_redo));
%             strrep(block_dat.wm_stimulus(redo_slice_idx + numel(bad_trials_redo)),'Back','Front'); % Stim reference;
         
    end

    
    % Reassemble the trial sequence so that we preserve existing structure,
    % but allow for recycling.
    trial_list = [trial_list(1:(end-bn_nback));...
        trial_list(bad_trials_redo); trial_list(end-(bn_nback-1):end)];

    
elseif num_remaining_trials == 0
    bad_trials_redo = (t-bn_nback):t;
    block_dat_redo = block_dat(bad_trials_redo,:);
    block_dat_redo.wm_rpt = block_dat_redo.wm_rpt + 1;
    block_dat = [block_dat(1:end,:); block_dat_redo];
    trial_list = [trial_list(1:end); trial_list(bad_trials_redo)];
    
else
    bad_trials_redo = (t-bn_nback):t;
    block_dat_redo = block_dat(bad_trials_redo,:);
    bk_end_idx = size(block_dat,1);
    redo_slice_idx = (bk_end_idx - (bn_nback - 1):bk_end_idx) - bn_nback;
    block_dat_redo.wm_nback( isnan( block_dat_redo.wm_nback)) = bn_nback;
    
    
    if strcmp(wm_modality, 'digits') % Update finger count reference (Digits Task)    
        block_dat_redo.wm_nback_digit_correct(1:numel(redo_slice_idx)) = ...
            StimName2Num(block_dat.wm_stimulus(redo_slice_idx));
        block_dat.wm_nback_digit_correct((end-(bn_nback-1):end),:) = ...
            StimName2Num(block_dat_redo.wm_stimulus((end-(bn_nback-1):end)));
        
    elseif strcmp(wm_modality, 'motor') % Update posture ID reference (Motor Task)    
     
%         block_dat_redo.wm_nback_motor_stim_ref(1:numel(redo_slice_idx)) = ...
%             strrep(block_dat.wm_stimulus(redo_slice_idx),'Back','Front');
%         block_dat.wm_nback_motor_stim_ref((end-(bn_nback-1):end),:) = ...
%             strrep(block_dat_redo.wm_stimulus((end-(bn_nback-1):end)),'Back','Front');
                
        block_dat_redo.wm_nback_motor_stim_ref(1:numel(redo_slice_idx)) = ...
            block_dat.wm_stimulus(redo_slice_idx);
        block_dat.wm_nback_motor_stim_ref((end -(bn_nback - 1):end),:) = ...
            block_dat_redo.wm_stimulus((end -(bn_nback - 1):end));
        
    end
    
    % Mark the repetition
    block_dat_redo.wm_rpt = block_dat_redo.wm_rpt + 1;
    % Assemble the block data with updated trial order to enable recycling
    block_dat = [block_dat(1:(end-bn_nback),:); ...
        block_dat_redo; block_dat((end-(bn_nback-1):end),:)];
    % Assemble the trial list to reflect updated trial order with recycling
    trial_list = [trial_list(1:(end-bn_nback));...
        trial_list(bad_trials_redo); trial_list(end-(bn_nback-1):end)];   
end

% Update the reference fields to reflect non-response trials
block_dat.wm_nback((t+1):(t+bn_nback)) = NaN;
block_dat.wm_nback_digit_correct((t+1):(t+bn_nback)) = NaN;    
block_dat.wm_nback_motor_stim_ref((t+1):(t+bn_nback)) = {'NA'};
num_trials_redo = numel(bad_trials_redo);

end