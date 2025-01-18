function dual_dev()

try
% Dual Work Development
% Clear the workspace and the screen
sca;       
close all;
clearvars -except useOptotrak

% instrreset
% opto_initialized = 0;  

% Add source code path
addpath('source');

% Disable output to MATLAB Command Window
% ListenChar(2);

% Seed random number generator for participant ID
rand('seed', sum(100 * clock));

% Diagonal of touch screen display
SCREEN_DIAG_INCHES = 32;

% Initialize Psychtoolbox
InitializePsychSound;
pahandle = PsychPortAudio('Open');
Snd('Open', pahandle, 1);
ptb = ptb_init_screen(SCREEN_DIAG_INCHES);
ptb.text_color = ptb.black;
ifi = ptb.ifi;
waitframes = ptb.waitframes;
msgPosX = ptb.xCenter - 150;
msgPosY = ptb.yCenter - 100;
AssumedRefreshRate = 60;

% % % % DEFINE WINDOW % % % %
window = ptb.window;


% % % % GENERATE MESSAGES % % % %
welcomeMsg = ['Welcome to the experiment!\n\n\n',...
              'Please give instructions \n',...
              'to the participant now.\n\n',...
              'Press Any Key To Begin\n',...
              'Esc to exit at any time'];
          
preTrialMsg = ['Place Bar on Screen Now\n\n\n',...
              'When ready, press the space key\n',...
              'to start the trial.'];
          
fillerTrialMsg = ['Action loop under development!\n\n',...
                  'Press the space key to continue']; %#ok<NASGU>
              
expEndMsg = ['Experiment complete!\n\n',...
            'Press any key to exit'];


% % % % DEFINE BAR OUTLINE % % % %
% These params are very close to the 60-mm bar size on the ELO 3202L
pixLength = 168;
pixWidth = 38;
% Get the centre coordinate of the window
% [ptb.xCenter, ptb.yCenter] = RectCenter(ptb.windowRect);


% Define placement area for the target and define the rect
TargetPosX = ptb.screenXpixels * 0.50;
TargetPosY = ptb.screenYpixels * 0.75;

InitializeTargRect = [0 0 pixWidth pixLength];
DiffRectSizes = [1 1 1 4/6; 1 1 1 5/6; 1 1 1 1];
DiffImgLengths = [4/6, 5/6, 6/6];
InitializeAllTargRects = repmat(InitializeTargRect, 3, 1) .* DiffRectSizes;
AllTargRectsCentered = nan(size(DiffRectSizes,1), size(DiffRectSizes,2));

TargRectImages = cell(1,3);

% TargRectTextures = cell(1,3);

% Get Images and Rects
for ii = 1:size(DiffRectSizes,1) 
    AllTargRectsCentered(ii,:) = CenterRectOnPointd(InitializeAllTargRects(ii,:),...
        TargetPosX, TargetPosY);
    TargRectImages{ii} = uint8(zeros(pixLength*DiffImgLengths(ii),pixWidth,3));
end

TargRectTexture = Screen('MakeTexture', window, TargRectImages{1});


% % % % % Hand Posture Stimuli % % % %
smap = ptb_load_textures(ptb);
StimKeyNames = smap.keys; 
StimPx = 400;
StimOffsetX = 300;
NumTrials = 15;
BaseStimRect = [0 0 StimPx StimPx];
StimOffsetSched = randi([0,1],NumTrials,1);
RightStimRect = CenterRectOnPointd(BaseStimRect,...
        TargetPosX + StimOffsetX, TargetPosY);
LeftStimRect = CenterRectOnPointd(BaseStimRect,...
        TargetPosX - StimOffsetX, TargetPosY);
    
% Subject n-back messages
SubjectMsgLocX = ptb.screenXpixels * (4/5);
SubjectMsgLocY = ptb.screenYpixels * (1.25/5);
wm_nback_id = 0;
% [~,~,bbox,cache] = DrawFormattedText2(['<size=40>','Provide your response.\n\n<b>N-Back = ',... 
%     num2str(wm_nback_id),'<b>','<size>'], 'win', window, 'sx', 'center', 'sy', 'center',... 
%     'baseColor', ptb.text_color, 'transform', {'flip', 1, 'rotate', 90}, 'cacheOnly', true);
[~,~,bbox,cache] = DrawFormattedText2(['<size=40>','Provide your response.\n\n<b>         N-Back = ',... 
    num2str(wm_nback_id),'<b>','<size>'], 'win', window,'xalign','center', 'sx', 'center', 'sy', 'center',... 
    'baseColor', ptb.text_color, 'cacheOnly', true);

SubjectMsgRect = CenterRectOnPointd(bbox, SubjectMsgLocX, SubjectMsgLocY);



% % % % % % % % % WELCOME MESSAGE % % % % % % % % %

    
welcome = true;
while welcome
    DrawFormattedText(window, welcomeMsg, msgPosX, msgPosY,...
        ptb.text_color);
        
    Screen('Flip', window);
    
    % Listen for Esc key to abort experiment
    [~, keyCode, ~] = KbStrokeWait;
    if keyCode(ptb.escapeKey)
        
        sca;
        ShowCursor('arrow', window);
        ListenChar(0);
        return;
    else
        welcome = false;
    end

end

% Define trial-level variables
TrialAngleOrder = Shuffle(repmat([1:5]',3,1)); %#ok<NBRAK>
TrialLengthOrder = Shuffle(repmat([1:3]',5,1));  %#ok<NBRAK>
AngleArray = [-10 -5 0 5 10];
tn = 1;
timer = NaN(2000,2);

% Timing register
% FlipTimer = single(NaN(NumTrials,1));



% % % % % % % % % TRIAL LOOP % % % % % % % % %
TrialsComplete = false;
AbortExperiment = false;

while ~TrialsComplete
    
    if tn > NumTrials
        TrialsComplete = true;
        continue        
    end
    
    
    if AbortExperiment
        ShowCursor('arrow', window);
        ListenChar(0);
        sca;
        return;
    end
    
    pre_trial_placement = true;
    % Detect if key is down on pre-trial loop start
    key_down_on_loop_start = KbCheck();
    
    % Get bar angle
    AngleIndex = TrialAngleOrder(tn);
    LengthIdx = TrialLengthOrder(tn);
    TargetAngle = AngleArray(AngleIndex);
    StimRight = StimOffsetSched(tn);
    StimID = StimKeyNames{tn};
    
    % Time register
    
     
    while pre_trial_placement
        
        % Draw the outline of the bar
        Screen('BlendFunction', window, 'GL_ONE', 'GL_ZERO');
        Screen('DrawTexture', window, TargRectTexture,[],...
            AllTargRectsCentered(LengthIdx,:), -1*TargetAngle, [], [],...
            [], [], [], []);        

        % Display pre-trial message to experimenter
        DrawFormattedText(window, preTrialMsg, msgPosX, msgPosY,...
            ptb.text_color);
        Screen('Flip', window);
        
        [key_down, ~, keyCode] = KbCheck();
            if key_down
                if ~key_down_on_loop_start
                    if keyCode(ptb.spaceKey)
                        pre_trial_placement = false; 
                    elseif keyCode(ptb.escapeKey)
                        AbortExperiment = true;
                        break;
                    end
                end
            elseif key_down_on_loop_start
                key_down_on_loop_start = false;
            end
    end

    key_down_on_loop_start = KbCheck();
    action_loop = true;
    frames_for_action_loop = 8;
    fCounter = 0;
    
    
    while action_loop
        
        Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        if StimRight
            Screen('DrawTexture', window, smap(StimID),[],...
                RightStimRect, [], [], [],...
                [], [], [], []);
        else
            Screen('DrawTexture', window, smap(StimID),[],...
                LeftStimRect, [], [], [],...
                [], [], [], []);
        end
            
%         DrawFormattedText(window, fillerTrialMsg, msgPosX, msgPosY,...
%             ptb.text_color);
        
        vbl = Screen('Flip', window);
        
        
        
        [key_down, ~, keyCode] = KbCheck();
            if key_down
                if ~key_down_on_loop_start
                    if keyCode(ptb.spaceKey)
                        action_loop = false; 
                    elseif keyCode(ptb.escapeKey)
                        AbortExperiment = true;
                        break;
                    end
                end
            elseif key_down_on_loop_start
                key_down_on_loop_start = false;
            end
        
    end
    
    key_down_on_loop_start = KbCheck();
    response_loop = true;
        
    while response_loop
        
        Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
%         [~,~,bbox,cache] = DrawFormattedText2(['<size=40>','Provide your response.\n\n<b>N-Back = ',... 
%             num2str(wm_nback_id),'<b>','<size>'], 'win', window, 'winRect', SubjectMsgRect, 'sx', 'center', 'sy', 'center',... 
%              'baseColor', ptb.text_color, 'transform', {'flip', 1, 'rotate', 90});
%          DrawFormattedText2(['<size=40>','Provide your response.\n\n<b>N-Back = ',...
%              num2str(wm_nback_id),'<b>','<size>'], 'win', window, 'winRect', SubjectMsgRect, 'sx', 'center', 'sy', 'center',...
%              'baseColor', ptb.text_color, 'transform', {'flip', 1, 'rotate', 90});
        DrawFormattedText2(cache,'win', window, 'transform', {'translate', [300,-800], 'flip', 1, 'rotate', 90});
%         Screen('FrameRect', window, [255 0 0 128], bbox, 2);
        Screen('Flip', window);
        
        [key_down, ~, keyCode] = KbCheck();
            if key_down
                if ~key_down_on_loop_start
                    if keyCode(ptb.spaceKey)
                        response_loop = false; 
                    elseif keyCode(ptb.escapeKey)
                        AbortExperiment = true;
                        assignin('base', 'bbox', bbox)
                        assignin('base', 'cache', cache)
                        break;
                    end
                end
            elseif key_down_on_loop_start
                key_down_on_loop_start = false;
            end
        
    end
        
    tn = tn + 1;
end


DrawFormattedText(window, expEndMsg, msgPosX, msgPosY,...
    ptb.text_color);
Screen('Flip', window);
KbStrokeWait;
ListenChar(0);
sca;
  
catch ME
%     if exist('smap', 'var')
%         assignin('base','smap', smap)
%     end
    ListenChar(0);
    sca;
    rethrow(ME);
end

end
