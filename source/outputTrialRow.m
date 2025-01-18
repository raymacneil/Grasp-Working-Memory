function [row_ct, out] = outputTrialRow(row_ct, out, part_dems, ...
                                        bn, is_practice_block,...
                                        practice_skipped, tn, t,... 
                                        bad_trials, trial_out)
% Output data row for current trial 

    % Allocate new otuput table row if necessary
    if row_ct > size(out.pData,1)
        out.pData = [out.pData; out.blank_data_row];
%         out.tData = [out.tData; NaN(1,size(out.tData,2))];
    end
%     assignin('base', 'tList', time_list);
%     assignin('base', 'row_ct', row_ct);
%     assignin('base', 'tData', out.tData);
%     assignin('base', 'out', out);
%     out.tData(row_ct,:) = time_list(row_ct,:);

    
    % Record the trial data into out data matrix
    out.pData.participant{row_ct} = part_dems.id;
    out.pData.BlockNum{row_ct} = bn;
    out.pData.PracticeBlock{row_ct} = is_practice_block;
    out.pData.PracticeSkipped{row_ct} = practice_skipped;
    out.pData.TrialNum{row_ct} = tn;
    out.pData.BadTrial{row_ct} = bad_trials(t); % TBD
    out.pData.TrialRepeat{row_ct} = trial_out.wm_rpt;

    out.pData.BarAngle{row_ct}      = trial_out.bar_angle;
    out.pData.BarLength{row_ct}     = trial_out.bar_length;
    out.pData.Collision{row_ct}     = trial_out.tgt_collision;
  
    out.pData.ReachTime{row_ct}      = trial_out.reach_time;
    out.pData.ReturnTime{row_ct}     = trial_out.return_time;
    out.pData.TrialStartTime{row_ct} = trial_out.trial_start_time;
    out.pData.ReachVelocity{row_ct}  = trial_out.reach_vel;
    out.pData.ReturnVelocity{row_ct} = trial_out.return_vel;

    out.pData.wmModality{row_ct}   = trial_out.wm_modality;
    out.pData.wmRespDigits{row_ct} = trial_out.wm_resp_digits;
    out.pData.wmRespMotor{row_ct}  = trial_out.wm_resp_motor;
    out.pData.wmCorrect{row_ct}    = trial_out.wm_nback_digit_correct;
    out.pData.wmStimID{row_ct}     = trial_out.wm_tgt;
    out.pData.wmRefStimID{row_ct}  = trial_out.wm_nback_motor_stim_ref;
    out.pData.wmSOA{row_ct}        = trial_out.wm_onset_time;
    out.pData.wmNBack{row_ct}      = trial_out.wm_nback;
    out.pData.wmInputRT{row_ct}    = trial_out.wm_response_time;
    out.pData.wmStimFrames{row_ct} = trial_out.wm_stim_frames;    
    out.pData.wmStimPos{row_ct}    = trial_out.wm_tgt_pos;
    out.pData.wmTaskIsDual{row_ct} = trial_out.wm_task_is_dual;
    

    % -- Write trial data out to one line of participant data file --------
    % Extract row corresponding to current trial
    trial_data = out.pData{row_ct,:};

    % Fill any empty entries with NaN and convert all cells to strings
    for idx = 1:numel(trial_data)
        if isempty(trial_data{idx})
            trial_data{idx} = NaN;           
        end
        
        if isnumeric(trial_data{idx})
            trial_data{idx} = num2str(trial_data{idx});
        end
    end

    % Append strings
    trial_row = string(trial_data);
    fSpec = [repmat('%s,', 1, numel(trial_row)-1), '%s\n'];

    % Write line to participant data output file
    fid = fopen(out.part_data_fname,'at');
    if fid>0
        fprintf(fid,fSpec,trial_row);
        fclose(fid);
    end

    % Iterate row counter for participant data
    row_ct = row_ct + 1;
end

