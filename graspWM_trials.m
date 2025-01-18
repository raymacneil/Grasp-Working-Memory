function graspWM_trials( ptb, part_dems, optk, ag, msgs, out, config_dat, stmap, BaselineWM)

w = ptb.window;
useOptotrak = optk.useOptotrak;
simulateOptotrak = optk.simulateOptotrak;

InitializePsychSound;
pahandle = PsychPortAudio('Open');
Snd('Open', pahandle, 1);


% MARKER NUMBER FOR VELOCITY DETECTION
% MARKERF = [16:18]; % MARKER 5 - INDEX FINGER
MARKER_IDX = 18:20; % MARKER 5 - INDEX FINGER

% Velocity (in mm/sec) threshold for reach detection
REACH_VEL_THRESH = 50;

% Boundary (in transformed Optotrak coordinates) for return position
% (y-axis, relative to screen) - on Elo 2293 total screen height is 400
RETURN_REGION_Y_BOUND = 350;
RETURN_REGION_Y_MAX = 1e5;
RETURN_REGION_Y_MIN = -1e5;

REACH_HOLDOFF_TIME = 0.500;
MAX_REACH_DELAY_SECS = 0.500;
MAX_TRIAL_TIME_SECS  = 4.00;
WM_RESPONSE_DELAY_SECS = 3.50;

if simulateOptotrak
    WM_RESPONSE_DELAY_SECS = 1.00;
end
    


% SET RSVP TIMING VARIABLES
% get secs of 1 frame (60 Hz = 0.0167s)
% screenRefreshSecs = Screen('GetFlipInterval', w);
screenRefreshRateHz = Screen('NominalFrameRate', w);
            

% Stimulus params for the grating:
phase = 0;
freq = .047;
contrast = 0.5;

% try
% Define coordinates for drawing the line that will dissect the screen and
% guide the placement of the mirror for testing. These numbers reflect 
% optimal paramters for ELO 3202L, 1920*1080 res, Display: 27.49"x 15.47" 

lineXst = ptb.screenXpixels * (1/3);
lineYst = ptb.screenYpixels * 0;
lineXen = lineXst + (ptb.screenYpixels * tand(45));
lineYen = ptb.screenYpixels * 1;
penWidth = 2;

% Define placement area for the front-of-mirror texture
frntTargPosX = ptb.screenXpixels * (3/4);
frntTargPosY = ptb.screenYpixels * (1/4);


% Calculate intercept of x = yPosA with mirror line as a first step in
% determining the guiding rect coordinates for actual object placement
% so as to be 'alligned' with the virtual image. We know the slope of the 
% line guiding mirror placement is tand(45). We can prove this in a number 
% of ways, but let us take a simple approach: rise over run (note the
% reversed y coordinate orientation, however, which is typical of monitor
% displays where the origin (0,0) is in the top left and y increases as you
% move toward the bottom of the screen

slopeMirror = -((lineYen - lineYst) / (lineXen - lineXst)); 
% the above expression evaluates to 1, which is equivalent to tand(45) 
% recall the equation of a line is given by the formula y = mx + b and
% dtermine b (y intercept) by solving for known point [lineXst, lineYst]
% we reverse the sign to account for the reversed directionality of the 
% y-axis when dealing with monitor displats
% lineYst = sloperMirror * linexSt + yIntercept; rearrange
% 0 = -1(200) + yIntercept
yIntercept = -(slopeMirror * lineXst);

% x coordinate for the intersection of x = yPosA with mirror line is 
% then given by: -yPosA = slopeMirror * xIntersect + yIntercept
% rearranged, we have:
xIntersect = (-frntTargPosY - yIntercept) / slopeMirror;

% the xIntersect gives the x coordinate for the placement of our object
% such that it aligns (more or less) with the virtual image; to determine
% the y-coord we just take the difference between the x-coords of the actual 
% image and mirror intercept, and then subsequently subtract that value 
% from the y coordinate of the mirror intercept; 
yVirtual = frntTargPosY - (xIntersect - frntTargPosX);

% you can verify this by doing the math, i.e. plotting the line that passes 
% through the xy-coords of the actual image and virtual image xy-coords 
% obtained from the above calculations -- though make necessary adjustments
% to account for reversed directionality of y-axis on the monitor; you'll
% see that it forms a 90 degree angle with the line guding mirror placement
% and similarly dissects the screen at a 45 degree angle


% Define placement area for the virtual image projection rect
backTargPosX = xIntersect;
backTargPosY = yVirtual;


% these params are very close to giving the actual 60mm targ bar size on 
% the ELO 3202L -- will likely have to adjust if using another display
pixLength = 168;
pixWidth = 38;
barBaseRectBackOfMirror = [0 0 pixWidth pixLength];
barBaseRectFrntOfMirror = [0 0 pixLength pixWidth];

DiffTargLengths = [4/6, 5/6, 6/6];
DiffRectLengthsBack = [1 1 1 DiffTargLengths(1); 
                       1 1 1 DiffTargLengths(2); 
                       1 1 1 DiffTargLengths(3)];
DiffRectLengthsFrnt = circshift(DiffRectLengthsBack, -1, 2);

                   
AllTargBackRects = repmat(barBaseRectBackOfMirror, numel(DiffTargLengths),...
    1) .* DiffRectLengthsBack;
AllTargFrntRects = repmat(barBaseRectFrntOfMirror, numel(DiffTargLengths),...
    1) .* DiffRectLengthsFrnt;

% Pre-allocate stimulus matrices for centering front and back rects of
% variable target lengths
AllTargBackRectsCentered = nan(size(DiffRectLengthsBack,1),...
    size(DiffRectLengthsBack,2));
AllTargFrntRectsCentered = AllTargBackRectsCentered;

% Pre-allocate a cell for containing the base target textures in uint8
% format (to accomodate variable target lengths)
TargBaseTextures = cell(3,1);

% Loop to center the rects and generate target base textures
for ii = 1:numel(DiffTargLengths) 
    AllTargBackRectsCentered(ii,:) = CenterRectOnPointd(AllTargBackRects(ii,:),...
        backTargPosX, backTargPosY);
    AllTargFrntRectsCentered(ii,:) = CenterRectOnPointd(AllTargFrntRects(ii,:),...
        frntTargPosX, frntTargPosY);
    TargBaseTextures{ii} = uint8(zeros(pixLength*DiffTargLengths(ii),pixWidth,3));
end


% This computes the end-points of the (back-of-mirror) target's 
% longitudinal axis when theta = 0, i.e. the base case
[TargBackCentX, TargBackCentY] = RectCenterd(AllTargBackRectsCentered); %#ok<ASGLU>
backRect_pointA = [AllTargBackRectsCentered(:,1) + (AllTargBackRects(:,3) ./ 2),...
    AllTargBackRectsCentered(:,2)]; %#ok<NASGU>
backRect_pointB = [AllTargBackRectsCentered(:,3) - (AllTargBackRects(:,3) ./ 2),...
    AllTargBackRectsCentered(:,4)];  %#ok<NASGU>

BarTexture = Screen('MakeTexture', w, TargBaseTextures{1});

% Experimental loop
    
% Flag to detect experiment end (ESC)
abort_experiment = false;

% Set output row counter to 1
row_ct = 1;
 
% Get list of blocks from config file
blocks = unique(config_dat.block_num);
num_blocks = length(blocks);


% BLOCK LOOP
for b=1:num_blocks
    
    if abort_experiment
        break
    end

    % Collect all block numbers
    bn = blocks(b);
    
    % Retrieve block rows for current block
    idx_block_trials = (config_dat.block_num == bn);
    block_dat = config_dat(idx_block_trials, :);
    
    % Get number of trials in block
    block_size = nnz(idx_block_trials);
    
    % Determine if next and current blocks are practice
    current_block_is_practice = any(block_dat.is_practice_block);
    next_block_is_practice = any(config_dat.is_practice_block(config_dat.block_num == (bn+1),:)); 
    skip_practice = 0;
    
    %-------------------------------------------------------------------%
    %-------------------------------------------------------------------% 
    %           Retrieve n-Back Information for Current Block           %
    %-------------------------------------------------------------------%
    %-------------------------------------------------------------------%
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
    next_bn_nback = NaN;
%     assignin('base', 'nback_response_required', nback_response_required);
    
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
            bk_stim_id(bk_correct_idx);
%             strrep(bk_stim_id(bk_correct_idx),'Back','Front');

        
        % These default to NaN (digits) and 'NA' (motor), respectively.
        if strcmp(wm_modality, 'digits')
            block_dat.wm_nback_digit_correct = bk_nback_digit_correct;
            block_dat.wm_nback_motor_stim_ref = bk_nback_motor_stim_ref;
        elseif strcmp(wm_modality, 'motor')
            block_dat.wm_nback_motor_stim_ref = bk_nback_motor_stim_ref;
        end
        
          
        if b < num_blocks % If it's not the last block
            
            idx_next_block_trials = (config_dat.block_num == (bn+1));
            next_block_dat = config_dat(idx_next_block_trials, :);
            next_bn_nback = unique(next_block_dat.wm_nback(~isnan(next_block_dat.wm_nback)));
            
            
            if current_block_is_practice
                
                % Experimenter Messages
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
        
        % Subject response prompt (cached)
        [~,~,~,subject_prompt_input_msg_cache] = DrawFormattedText2(['<size=40>','Provide your response.\n\n<b>         N-Back = ',...
            num2str(bk_nback),'<b>','<size>'], 'win', w,'xalign','center', 'sx', 'center', 'sy', 'center',...
            'baseColor', ptb.text_color, 'cacheOnly', true); 
      
        % Subject practice block start message (cached)
        [~,~,~,subject_practice_block_start_msg_cache] = DrawFormattedText2(['<size=40>','Practice block.\n\n<b>   N-Back = ',...
            num2str(bk_nback),'<b>','<size>'], 'win', w,'xalign','center', 'sx', 'center', 'sy', 'center',...
            'baseColor', ptb.text_color, 'cacheOnly', true);

        % Subject regular block start message (cached)
        [~,~,~,subject_regular_block_start_msg_cache] = DrawFormattedText2(['<size=35>','Block finished...\n\n',... 
             'Clear your memory. \n\n', '<b>', 'Next Block, N-Back = ', num2str(next_bn_nback), '<b>','<size>'], 'win', w,... 
             'xalign', 'center', 'sx', 'center', 'sy', 'center', 'baseColor', ptb.text_color, 'cacheOnly', true);
        % Correct feedback message (cached)
        [~,~,~,correct_feedback_msg_cache] = DrawFormattedText2(['<size=40>','<b>','Correct!','<b>','<size>'],... 
            'win', w,'xalign','center', 'sx', 'center', 'sy', 'center', 'baseColor', ptb.green, 'cacheOnly', true);              
        % Incorrect feedback message (cached)
        [~,~,~,incorrect_feedback_msg_cache] = DrawFormattedText2(['<size=40>','<b>','Incorrect!','<b>','<size>'],... 
            'win', w,'xalign','center', 'sx', 'center', 'sy', 'center', 'baseColor', ptb.red, 'cacheOnly', true);
         
        % Set appropriate EXPERIMENTER PROMPT MESSAGE for collecting WM Response 
         if strcmp(wm_modality, 'digits') % Digits task
             msgs.prompt_wm_response = strcat('Participant to indicate \n\nnumber of extended digits.\n\n',...
                 'N-Back = ', num2str(bk_nback));       
         elseif strcmp(wm_modality, 'motor') % Motor task
%              msgs.prompt_wm_response = strcat('Participant is to reproduce \n\nthe hand posture.\n\n',...
%                  'N-Back = ', num2str(bk_nback), '\n\n"1" Incorrect, "2" Correct');
             msgs.prompt_wm_response = strcat('Participant is to reproduce \n\nthe posture (N-Back = ',...
                 num2str(bk_nback), ').', '\n\n"1" Incorrect, "2" Correct');
         end       
        
    else % if not nback_response_required
%         block_dat.wm_nback_digit_correct = NaN(block_size,1);
%         block_dat.wm_nback_motor_stim_ref = bk_stim_id;
        bk_nback = NaN;
    end % nback_response_required
 
    %-------------------------------------------------------------------%
    %-------------------------------------------------------------------% 
    %           Initate block, show messages, etc.                      %
    %-------------------------------------------------------------------%
    %-------------------------------------------------------------------%
        
    
Screen('TextSize', w, 30);
        
    % If this is the very first trial, present a start screen and wait
    % for a key-press
    if b == 1
        
        % Draw welcome text
        DrawFormattedText(w,msgs.welcomeMsg,...
                ptb.exprmtrMsgLoc_x, ptb.exprmtrMsgLoc_y, ptb.text_color);
    
        Screen('Flip', w);


        % Listen for Esc key to abort experiment
        [~, keyCode, ~] = KbStrokeWait;
        if keyCode(ptb.escapeKey)
            sca;
            return;
        end
    end
    
    % Retreive list of trials
    trial_list = unique(block_dat.trial_num);
%     time_list = NaN(size(trial_list,1),26);

    % Calculate total number of trials
    num_trials = length(trial_list);
    
    % Create vector to flag bad trials for repeat at end of block
    bad_trials = zeros(num_trials,1);
            
    % Display practice block message, if applicable
    if current_block_is_practice
        
        
        % Draw practice block or generic block end message
        if nback_response_required
            DrawFormattedText2(subject_practice_block_start_msg_cache,'win', w, 'transform',...
                {'translate', [300, -800], 'flip', 1, 'rotate', 90});
            DrawFormattedText(w, msgs.practiceStartMsg, ...
                ptb.exprmtrMsgLoc_x, ptb.exprmtrMsgLoc_y, ptb.text_color);
        else 
            DrawFormattedText(w, msgs.practiceStartMsg, ...
                ptb.exprmtrMsgLoc_x, ptb.exprmtrMsgLoc_y, ptb.text_color);
        end
        
        Screen('Flip', w);
        key_down_on_loop_start = KbCheck();
        key_press_required = true;
        
        while key_press_required
        
            [key_down, ~, keyCode] = KbCheck();
            if key_down
                if ~key_down_on_loop_start
                    
                    if keyCode(ptb.spaceKey) 
                        key_press_required = false;
                        
                    elseif keyCode(ptb.sKey)
                        skip_practice = true;
                        key_press_required = false;
                        
                    elseif keyCode(ptb.escapeKey)
                        abort_experiment = true;
                        break;
                    end
                end
            elseif key_down_on_loop_start
                key_down_on_loop_start = false;
            end
        end
        
              
    end % current_block_is_practice



    % Set trial counter
    t = 1;
    block_complete = false;
%     rpt_bad_trials = false;
    
    dataReorg = [];
    
    % TRIAL LOOP
while ~block_complete

        % If all trials have been presented
        if t > num_trials
            block_complete = true;
            continue
        elseif current_block_is_practice && skip_practice
            [row_ct, out] = write_data_skipped_practice_block(out, block_dat,... 
                trial_list, bad_trials, bn, part_dems, row_ct);
            block_complete = true;
            continue
        end

        if abort_experiment
            break
        end

        % -- Pre-trial initialization: event schedules, calculate masks --
        % Collect all trial numbers
        tn = trial_list(t);

        % Retrieve vars for current trial
        trial_row_in_block_dat = block_dat.trial_num == tn;
        trial_row_in_block_dat(1:t-1) = false;
        trial_dat = block_dat(trial_row_in_block_dat, :);
        trial_bar_angle = trial_dat.bar_angle;
        targ_length_idx = trial_dat.bar_length / 10 - 3; % 40,50,60 to 1,2,3, respectively
        is_openloop_trial = trial_dat.vis_feedback; % 1; Held constant as of 16-Jan-2024
        vis_fb_time = (trial_dat.vis_feedback_time / 1000); % 0.7; Held constant as of 16-Jan-2024
        wm_init_time = (trial_dat.wm_init_time / 1000);	
        wm_stim_id = trial_dat.wm_stimulus{:};
        wm_stim_position = trial_dat.wm_position;
        wm_stim_frames = trial_dat.wm_stim_frames;
        wm_modality = trial_dat.wm_modality;
        wm_task_is_dual = trial_dat.wm_task_is_dual;      
        wm_motor_ref_stim_id = trial_dat.wm_nback_motor_stim_ref{:};
%         replace_str = ["Back", "Front"];
%         if ~(string(wm_motor_ref_stim_id) == "NA")
%             regexp_ref_stim_id = string(regexp(wm_motor_ref_stim_id, '(?<=-)[a-zA-Z]*', 'match'));     
%             rsIdx = ~(regexp_ref_stim_id == replace_str);
%             wm_motor_ref_stim_id = char(strrep(wm_motor_ref_stim_id, regexp_ref_stim_id,... 
%             replace_str(rsIdx)));
%         end
%         trial_dat.wm_nback_motor_stim_ref = wm_motor_ref_stim_id; 
        wm_nback_id = trial_dat.wm_nback;
        wm_rpt = trial_dat.wm_rpt;

        
        % WM STIMULUS POSITION ABOUT TARGET (CARDINAL POINTS):
        % 1 = right of target (left for experimenter)
        % 2 = bottom of grating (bottom for experimenter)
        % 3 = left of grating (right for experimenter)
        % 4 = top of grating (top for experimenter)
        wmStimSizeX = 180;
        wmStimSizeY = 214;
        wmRefStimSizeX = 240; 
        wmRefStimSizeY = 240;
        wmStimAllPositions = [ [(frntTargPosX - 50 - wmStimSizeY/2) frntTargPosY];...
                              [(frntTargPosX + 10) (frntTargPosY - 140)];...
                              [(frntTargPosX + 50 + wmStimSizeY/2) frntTargPosY];...
                              [(frntTargPosX + 10)  (frntTargPosY + 140)] ];

        % draw rect, centering on 1 of 4 cardinal points (from config)
        wmStimRectSize =    [0 0 wmStimSizeX wmStimSizeY];
        wmRefStimRectSize = [0 0 wmRefStimSizeX wmRefStimSizeY];
        wmStimRect = CenterRectOnPointd(wmStimRectSize, ...
                                      wmStimAllPositions(wm_stim_position, 1),...
                                      wmStimAllPositions(wm_stim_position, 2));
        [XStimCenter, YStimCenter] = RectCenter(wmStimRect);
%         wmRefStimRect = CenterRectOnPointd(wmRefStimRectSize,...
%             ptb.exprmtrMsgLoc_x + 260, (ptb.exprmtrMsgLoc_y + 300));
        wmRefStimRect = CenterRectOnPointd(wmRefStimRectSize,...
            ptb.exprmtrMsgLoc_x, (ptb.exprmtrMsgLoc_y + 300));

               
        trial_out = init_trial_output_struct(trial_dat);

       
        
        
        % Detect if key is down on pre-trial loop start
        key_down_on_loop_start = KbCheck();
        
        
        %%%%%%%%%%%%%%%%%%%%%% ******************** %%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%% *** PRE-TRIAL    *** %%%%%%%%%%%%%%%%%%%%%%% 
        %%%%%%%%%%%%%%%%%%%%%% ******************** %%%%%%%%%%%%%%%%%%%%%%%
        
        
        
        % Pre-trial bar placement period
        % Close googles
        ag.closeBothEyes();
        
        pre_trial_placement = true;
        while pre_trial_placement

            % Draw rectangular outline to guide proper placement of the physical target
            % bar behind the mirror
             Screen('DrawLine', w, [0 0 0], lineXst, lineYst, lineXen, lineYen, penWidth);   
       
            % In front of mirror (rotation is clockwise, so reverse since
            % we are upside down - bottom of screen faces back of mirror)                 
            Screen('BlendFunction', w, 'GL_ONE', 'GL_ZERO');           
            Screen('DrawTexture', w, BarTexture,[],...
                AllTargFrntRectsCentered(targ_length_idx,:), -1*trial_bar_angle,...
                [], [], [], [], [], [phase, freq, contrast, 0]);

            % In back of mirror
            Screen('DrawTexture', w, BarTexture, [],...
                AllTargBackRectsCentered(targ_length_idx,:), trial_bar_angle,...
                [], [], [], [], [], [phase, freq, contrast, 0]);           
            
            % Display pre-trial message to experimenter
            DrawFormattedText(w, msgs.preTrialMsg, ptb.exprmtrMsgLoc_x,... 
                ptb.exprmtrMsgLoc_y, ptb.text_color);        

            % Flip and sync us to the vertical retrace:
            Screen('Flip', w);
            
    
            % Wait for CTRL+S to continue
            [key_down, ~, keyCode] = KbCheck();
            if key_down
                if ~key_down_on_loop_start
                    if (keyCode(ptb.ctrlLKey) || keyCode(ptb.ctrlRKey)) && keyCode(ptb.sKey)
                        pre_trial_placement = false; 
                    elseif keyCode(ptb.escapeKey)
                        abort_experiment = true;
                        break;
                    end
                end
            elseif key_down_on_loop_start
                key_down_on_loop_start = false;
            end
                   
        end
        
       %%%%%%%%%%%%%%%%%%%% END OF PRE-TRIAL PLACEMENT %%%%%%%%%%%%%%%%%%%%
        
        if abort_experiment
            break
        end
        
       
        % Clear screen
        Screen('Flip', w);
        
        
    
        %%%%%%%%%%%%%%%%%%%%%% ******************** %%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%% *** TRIAL PROPER *** %%%%%%%%%%%%%%%%%%%%%%% 
        %%%%%%%%%%%%%%%%%%%%%% ******************** %%%%%%%%%%%%%%%%%%%%%%%

         
        % Wait 1 second
        WaitSecs(1);
        
        % Play sine tone for 500ms (note: does not pause program)
        Beeper(440, 1.0, 0.5);
        
%         WaitSecs(0.5); % pause manually to wait for Beeper to finish
         
        % Wait 500ms to start trial
%         WaitSecs(0.5); OptoTrak now paauses for 
        
        % Optotrak pauses for 1 second to allow marker activation
        if useOptotrak
            [optk, dataReorg] = ptb_optotrak_start_rec(optk, out, dataReorg, part_dems, bn, tn, t, wm_rpt);
        else
            WaitSecs(1);
        end
    
        
        
        % Flip and sync us to the vertical retrace, store trial start time
        trial_out.trial_start_time = Screen('Flip', w);
        last_frame = trial_out.trial_start_time;
%         time_list(t,1) = last_frame;
        
        
        % Open goggles
        ag.openBothEyes()
      
        % See if key is down on loop start, so as not to accidentally
        % trigger
        key_down_on_loop_start = KbCheck; 
        
        % Set trial parameters to their defaults
        marker_vel = 0;
        start_reach = false;
        reach_holdoff_time_elapsed = false;
        returned = false;
        frame = 1;
        wmStimFrameCount = 0;
        digits = false;
        motor = false;
        time_since_reach = 0;
        in_WM_feedback_loop = false;
        in_WM_resp_loop = false;
        in_trial_loop = true;
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%% ******************** %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% *** ACTION LOOP **** %%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%% ******************** %%%%%%%%%%%%%%%%%%%%%%%
        
        while in_trial_loop
            % Get hand marker positions
            if useOptotrak
                [optk, marker_pos, marker_vel] = ptb_optotrak_collect_sample(optk, MARKER_IDX, screenRefreshRateHz, frame);
%                 fprintf('Marker vel: %f', marker_vel);
            elseif simulateOptotrak 
                % No Optotrak - USE KEYBOARD SIMULATION
                [~, ~, keyCode] = KbCheck();
                if keyCode(ptb.fKey)
                    marker_vel = randi([100 300],1,1);
                elseif keyCode(ptb.rKey)
                    marker_vel = randi([-300 -100],1,1);
                end
            end


            
            % If crossed velocity threshold, reach initated, store reach velocity            
            if useOptotrak
                if (marker_vel > REACH_VEL_THRESH) && (marker_pos(2) < RETURN_REGION_Y_BOUND) && (marker_pos(2) > RETURN_REGION_Y_MIN) && ~start_reach
                    start_reach = true;
                end
                
                % If reach has begun, and returned to start region, end trial
                if start_reach && reach_holdoff_time_elapsed && (marker_pos(2) > RETURN_REGION_Y_BOUND) && (marker_pos(2) < RETURN_REGION_Y_MAX)
                    returned = true;
                end
            elseif  simulateOptotrak % USE KEYBOARD SIMULATION
                if (marker_vel > REACH_VEL_THRESH) && ~start_reach
                    start_reach = true;
                end
                
                % If reach has begun, and returned to start region, end trial
                if start_reach && reach_holdoff_time_elapsed && (marker_vel <= REACH_VEL_THRESH * -1)
                    returned = true;
                end
            end
            
            % Check for keyboard presses
            [key_down, ~, keyCode] = KbCheck();
            if key_down
                if ~key_down_on_loop_start
                    % if "a" pressed, flag as bad_trial = 3 and abort
                    if keyCode(ptb.aKey)
                        bad_trials(t) = 3;
                        break
                    elseif keyCode(ptb.minusKey)
                        ag.closeBothEyes()
                    elseif keyCode(ptb.plusKey)
                        
                        
                        
                    % if "esc" pressed, end experiment
                    elseif keyCode(ptb.escapeKey)
                        bad_trials(t) = -1;
                        abort_experiment = true;
                        break;
                    end
                end
            elseif key_down_on_loop_start
                key_down_on_loop_start = false;
            end
            
            % If reach or return has started this frame, save time & marker
            
            if useOptotrak || simulateOptotrak
                
                if start_reach && isnan(trial_out.reach_time)
                    trial_out.reach_time = last_frame;
                    trial_out.reach_vel = marker_vel;
                    
                end
                
                if returned && isnan(trial_out.return_time)
                    trial_out.return_time = last_frame;
                    trial_out.return_vel = marker_vel;
                    in_trial_loop = false;
                    continue
                end
            end
            


                 
            % Get current time
            trial_time_elapsed = last_frame - trial_out.trial_start_time;
            
            % % % % % % % % % % % % % % % % % % % % % % % % % % % %
            % % % % % % % CHECK IF GOGGLES SHOULD CLOSE % % % % % %
            if is_openloop_trial
                if (trial_time_elapsed > vis_fb_time) && ~ag.bothEyesAreClosed()
                    ag.closeBothEyes()
%                     idx = find(~isnan(time_list(t,:)),1, 'first');
%                     time_list(idx) = last_frame;
                    
                end
            end
            


            % Get time elapsed since reach for comparison against the 
            if BaselineWM
                wmOnsetTrigger = trial_time_elapsed - wm_init_time;
            else               
                wmOnsetTrigger = time_since_reach - wm_init_time;
            end
 %-----------------------------------------------------------------------%           
            % % % % % % % % % % % % % % % % % % % % % % % % % % % % 
            % % % % % % % % % % Memory Stimulus % % % % % % % % % %  
 %-----------------------------------------------------------------------%  
            
            if (wmOnsetTrigger > 0) && wmStimFrameCount < wm_stim_frames
                
                Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
                Screen('glPushMatrix', w);
                Screen('glTranslate', w, XStimCenter, YStimCenter, 0);
                Screen('glScale', w, -1, 1, 1);
                Screen('glTranslate', w, -XStimCenter, -YStimCenter, 0);
                Screen('DrawTexture', w, stmap(wm_stim_id),[], wmStimRect, -90,...
                    [], [], [], [], [], []);           
                Screen('glPopMatrix', w);
                wmStimFrameCount = wmStimFrameCount + 1;
                
            end
            
            frame = frame + 1;

 %-----------------------------------------------------------------------%           
                  % Check time since reach, hold off time, etc. 
         
 %-----------------------------------------------------------------------% 
            
            % Calcualte time since reach, determine if holdoff time has
            % elapsed (for return),
            if useOptotrak || simulateOptotrak
            
                if ~isnan(trial_out.reach_time)
                    time_since_reach = last_frame - trial_out.reach_time;
                    
                    if ~reach_holdoff_time_elapsed
                        reach_holdoff_time_elapsed = (time_since_reach > REACH_HOLDOFF_TIME);
                    end                   
                    
                end
                
                % If MAX_GRASP_DELAY has elapsed, flag bad_trial = 1 and abort
                if ~start_reach && (trial_time_elapsed > MAX_REACH_DELAY_SECS)
                    bad_trials(t) = 1;
                    in_trial_loop = false;
                end
                
                % If MAX_TRIAL_TIME has elapsed, flag bad_trial = 2 and abort
                if (trial_time_elapsed > MAX_TRIAL_TIME_SECS)
                    bad_trials(t) = 2;
                    in_trial_loop = false;
                end
            
            else
                
               if trial_time_elapsed > WM_RESPONSE_DELAY_SECS
                   in_trial_loop = false;
               end
               
            end

            %%%%%% LAST FRAME TIME IS UPDATED %%%%%%%%%%%%
            last_frame = Screen('Flip', w, last_frame + (ptb.waitframes - 0.5) * ptb.ifi);
                      

        end % while in trial loop
            
        % Trial end
        Screen('TextSize', w, 30);
        
        % Stop Optotrak recording
        if useOptotrak
            optk.txtBad = [num2str(bad_trials(t), '%d'), '_'];
            if bad_trials(t) == 0
                dataReorg = ptb_end_optotrak(optk, out, part_dems, dataReorg, t, tn, bn, wm_rpt, true);
            else             
                dataReorg = ptb_end_optotrak(optk, out, part_dems, dataReorg, t, tn, bn, wm_rpt, true);
            end

        end
         
%-----------------------------------------------------------------------%           
                % COLLECT RESPONSE IF DUAL-TASK OR BASELINE
         
%-----------------------------------------------------------------------%       
   
        % if dual task or baseline n-back, collect participant response for
        % working memory stimulus
        if ~abort_experiment && (bad_trials(t) == 0) && (wm_task_is_dual || BaselineWM) && nback_response_required && ~isnan(wm_nback_id)
                    
%             DrawFormattedText(w, msgs.prompt_wm_response, ptb.exprmtrMsgLoc_x,...
%                 ptb.exprmtrMsgLoc_y, ptb.text_color);
            
            DrawFormattedText(w, msgs.prompt_wm_response, ptb.exprmtrMsgLoc_x - 75,...
                ptb.exprmtrMsgLoc_y, ptb.text_color);
            DrawFormattedText2(subject_prompt_input_msg_cache,'win', w, 'transform',...
                {'translate', [300, -800], 'flip', 1, 'rotate', 90});
                           
            
            if strcmp(wm_modality, 'digits')
                digits = true;
                in_WM_resp_loop = true;
                
            elseif strcmp(wm_modality, 'motor')
                Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
                Screen('DrawTexture', w, stmap(wm_motor_ref_stim_id),[], wmRefStimRect, 180,...
                    [], [], [], [], [], []);
                motor = true;
                in_WM_resp_loop = true;
                
            end
               
                
            Screen('Flip', w);
            
            if in_WM_resp_loop
               ag.openBothEyes()
            end
            StartTimeWmResponse = GetSecs; 
                         
            % Number keycodes: Above letters: 48:57, numpad: 96:105
            while in_WM_resp_loop
                
                
                
                % Listen for key to break
                [keyPressTime, keyCode, ~] = KbStrokeWait;                
                trial_out.wm_response_time = keyPressTime - StartTimeWmResponse;
                
                if keyCode(ptb.escapeKey)
                    abort_experiment = true;
                    break
                end
                
                
                keyCodeIdx = find(keyCode);
                
                if digits
                    
                    if isscalar(keyCodeIdx) && any(keyCodeIdx == [48:57, 96:105])
                        trial_out.wm_resp_digits = KbName(keyCode);
                        trial_out.wm_resp_motor = 'NaN';
                        if any(keyCodeIdx == 48:57)
                           trial_out.wm_resp_digits = trial_out.wm_resp_digits(1);
                        end
                        
                        in_WM_resp_loop = false;
                        
                        if current_block_is_practice % if practice block, trigger feedback
                           in_WM_feedback_loop = true;
                           response_correct = str2double(trial_out.wm_resp_digits) == trial_out.wm_nback_digit_correct;
                        end

                    else
                        in_WM_resp_loop = true;
                    end
                    
                elseif motor

                    if isscalar(keyCodeIdx) && any(keyCodeIdx == [ptb.oneKey,ptb.twoKey,...
                            ptb.numpadOneKey,ptb.numpadTwoKey])
                        trial_out.wm_resp_motor = KbName(keyCode);
                        trial_out.wm_resp_digits = 'NaN';
                        if any(keyCodeIdx == [ptb.oneKey, ptb.twoKey])
                            trial_out.wm_resp_motor = trial_out.wm_resp_motor(1);
                        end
                        
                        in_WM_resp_loop = false;
                        
                       
                        if current_block_is_practice % if practice block, trigger feedback
                            in_WM_feedback_loop = true;
                            response_correct = str2double(trial_out.wm_resp_motor) == 2;                    
                        end
                        
                        trial_out.wm_resp_motor = str2double(trial_out.wm_resp_motor) - 1;
                        
                    else
                        in_WM_resp_loop = true;
                    end
                end
                
            end
            
            time_at_start_feedback_loop = Screen('Flip', w);
            time_for_feedback = 0.750;
            
            while in_WM_feedback_loop 

                if ~isnan(response_correct) && response_correct
                    DrawFormattedText2(correct_feedback_msg_cache,'win', w, 'transform',...
                        {'translate', [300, -800], 'flip', 1, 'rotate', 90});
                    DrawFormattedText2(correct_feedback_msg_cache,'win', w, 'transform',...
                        {'translate', [-75, 200]});
                elseif ~isnan(response_correct) && ~response_correct
                    DrawFormattedText2(incorrect_feedback_msg_cache,'win', w, 'transform',...
                        {'translate', [300, -800], 'flip', 1, 'rotate', 90});
                    DrawFormattedText2(incorrect_feedback_msg_cache,'win', w, 'transform',...
                        {'translate', [-75, 200]});

                else % do nothing for now
               
                end
                
                time_after_start_feedback_loop = Screen('Flip', w, time_at_start_feedback_loop + (ptb.waitframes - 0.5) * ptb.ifi);
                time_elapsed_feedback = time_after_start_feedback_loop - time_at_start_feedback_loop; 
                
                if time_elapsed_feedback > time_for_feedback
                    in_WM_feedback_loop = false;
                    Screen('Flip', w);
                end
            end
                    
                        
            ag.closeBothEyes();
            
        end % if ~abort_experiment && (bad_trials(t) == 0) && (wm_task_is_dual || BaselineWM)
        
        % If the trial has not been aborted AND.....
        % It falls within  practice block, prompt the experimenter to accept or 
        % reject the trial; 

        if bad_trials(t) == 0 && (current_block_is_practice || useOptotrak || simulateOptotrak)
            
%             if ~optk.first_smp_success
%                 DrawFormattedText(w,'Warning! Could not detect screen markers!',...
%                     ptb.exprmtrMsgLoc_x, ptb.exprmtrMsgLoc_y+0.1, ptb.red);
%             end
            
            trial_out.tgt_collision = NaN;
            
            if current_block_is_practice
                DrawFormattedText(w,'Accept trial?\n\n"Y" to accept, "N" to repeat later.',...
                    ptb.exprmtrMsgLoc_x, ptb.exprmtrMsgLoc_y, ptb.text_color);
                in_accept_loop = true;

            else
                in_accept_loop = false;
            end
            

            Screen('Flip', w);

                
            
                     
            while in_accept_loop
                % Listen for 'Y' or 'N' key to break
                [~, keyCode, ~] = KbStrokeWait;
                            
                             
                if keyCode(ptb.nKey) && current_block_is_practice 
                    bad_trials(t) = 5;
                    in_accept_loop = false;
                end
                              
                if  keyCode(ptb.yKey) && current_block_is_practice
                    in_accept_loop = false;
                end
     
                if keyCode(ptb.escapeKey)
                    abort_experiment = true;
                    break;
                end
            end % while in accept loop
            
            Screen('Flip', w);
        end      
        
        if bad_trials(t) ~= 0
            % Play low sine tone for 300ms (note: does not pause program)
            Beeper(256, 1.0, 0.3);
            WaitSecs(0.3); % pause manually to wait for Beeper to finish
        end
        
      
        % Wait 1000ms
        WaitSecs(1);
        
        % Display Trial End message     
      
        % Output trial data
        [row_ct, out] = outputTrialRow(row_ct, out, part_dems, ...
            bn, current_block_is_practice, skip_practice, tn, t, bad_trials,...
            trial_out);

                                    

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
    
    if ~abort_experiment
        if (b < num_blocks) && ~next_block_is_practice
            % End of block screen. 
            if nback_response_required
                ag.openBothEyes()
                DrawFormattedText2(subject_regular_block_start_msg_cache, 'win', w, 'transform',...
                    {'translate', [300, -800], 'flip', 1, 'rotate', 90});
                DrawFormattedText(w, msgs.blockEndMsg, ...
                    ptb.exprmtrMsgLoc_x, ptb.exprmtrMsgLoc_y, ptb.text_color);
               
            else
                DrawFormattedText(w, msgs.blockEndMsg, ...
                    ptb.exprmtrMsgLoc_x, ptb.exprmtrMsgLoc_y, ptb.text_color);
            end
            % Draw practice block or generic block end message

      
            Screen('Flip', w);


            [~, keyCode, ~] = KbStrokeWait;
            if ~ag.bothEyesAreClosed()
                ag.closeBothEyes()
            end

            if keyCode(ptb.escapeKey)
                abort_experiment = true;
            end
            
        elseif b == num_blocks || next_block_is_practice % do nothing
            

        end % b < num_blocks
    else
        break
    end % abort_experiment
    
end % for b 1:num_bblocks

PsychPortAudio('Close', pahandle)
Snd('Close');
ListenChar(0)

end


