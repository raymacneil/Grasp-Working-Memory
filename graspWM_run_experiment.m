%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SETUP NOTES
% MARKERS:
% 1 = tabletop screen bottom left (experimenter's point of view)
% 2 = tabletop screen bottom right
% 3 = tabletop screen top right
% 4 = participant's wrist
% 5 = participant's index
% 6 = participant's thumb
%
% -Jamie Kai, UBC Vision Lab, 2021
% -Ray MacNeil, UBC Vision Lab, 2021-2024
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function graspWM_run_experiment(useOptotrak, simOptotrak)


if nargin < 1
    useOptotrak = 1;
    simOptotrak = 0;
elseif nargin < 2
    simOptotrak = 0;
end
    
% Clear the workspace and the screen
sca;       
close all;

clearvars -except useOptotrak simOptotrak

instrreset
opto_initialized = 0;  
% Add source code path
addpath('source');
 
% Seed random number generator for participant ID
rand('seed', sum(100 * clock));

% Set messages to participant
msgs.welcomeMsg = ['Welcome to the experiment!\n\n\n',...
              'Please give instructions \n',...
              'to the participant now.\n\n',...
              'Press Any Key To Begin\n',...
              'Esc to exit at any time'];
          
msgs.practiceStartMsg = ['Now beginning practice block.\n\n',...
                         'Press ''Space'' Key To Continue.\n\n',...
                         'Press ''s'' Key to Skip Practice.'];
msgs.practiceEndMsg = ['Practice Block Finished.\n\n\n',...
                       'Press Any Key To Continue'];
msgs.blockEndMsg = ['Block Finished.\n\n',...
                    'Press Any Key To Continue'];

msgs.preTrialMsg = ['Place Bar on Screen Now\n\n\n',...
                    'When ready, press Ctrl+S to start trial'];               
                
msgs.expEndMsg = 'Experiment Finished\n\n\nPress Any Key To Exit';

msgs.timeoutMsg = 'Trial Time Expired.\n\n\nPress Any Key To Continue';

msgs.blockEndMsgPracticeSkip = '';



% kbrespMsg = 'Letter?';

% Name of current experiment, used for data out files
exp_name = 'grasp_wm';

% Output directory for data and demographics file
out_path = 'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\Data\';

% Maximum trial time in seconds
max_trial_time = 5;

% Diagonal of touch screen display
SCREEN_DIAG_INCHES = 32;

% Acceptable stimulus image formats, must be compatible with imread()
img_formats = {'.png', '.jpg'};

% Task variables needed for adjusting event control logic
% Defaults value of 'false' overidden based on input from GetDemographics. 
BaselineWM = false;
Pantomime = false;

try
    %----------------------------------------------------------------------
    %                       Experimenter Setup
    %----------------------------------------------------------------------
    % Get demographics info
    [part_dems, config_dat] = GetDemographics(out_path, exp_name);
    
    if isempty(fieldnames(part_dems)) || isempty(config_dat)
       return 
    end

    if strcmp(part_dems.task, 'BaselineWM')
        useOptotrak = 0;
        simOptotrak = 0;
        BaselineWM = true;
    end

    % Initialize the data output file;
    out = ptb_init_output_table(out_path, exp_name, part_dems, config_dat);
    
    %----------------------------------------------------------------------
    %                       PyschToolbox Setup
    %----------------------------------------------------------------------
    % Run function to init PsychToolbox screen and store relevant vars for
    % later rendering and timing
    ptb = ptb_init_screen( SCREEN_DIAG_INCHES );

    % Get background and text color from config file
    ptb.bg_color = ptb.white;
    ptb.text_color = ptb.black;
    
    % Get window handle for PTB rendering
    window = ptb.window;

    % Get monitors Inter-Frame Interval and waittime (# of frames b/t renders)
%     ifi = ptb.ifi;
%     waitframes = ptb.waitframes;

    % Flip to clear
    Screen('Flip', window);

   

    %---------------------------------------------------------------------%
    %       Load in Stim PNGs and store as PTB Textures in MAP object     %
    %---------------------------------------------------------------------%
   
    stim_dir = 'C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\stimuli\';
    img_names = unique(string(config_dat.wm_stimulus)); 
    ref_img_names = strrep(img_names, 'Back', 'Front');
    img_names = [img_names; ref_img_names];
    stmap = ptb_load_textures(ptb,stim_dir,img_names,img_formats,[]);    

    %----------------------------------------------------------------------
    %                       Optotrak Setup
    %----------------------------------------------------------------------
    optk = struct();
    if useOptotrak
        warning('off','all')
        % Initialize Optotrak
        optk = ptb_init_optotrak(opto_initialized, out, part_dems, max_trial_time);
        warning('on','all')
    end 
    optk.useOptotrak = useOptotrak;
    optk.simulateOptotrak = simOptotrak;
    
    %----------------------------------------------------------------------
    %                       Goggles Setup
    %----------------------------------------------------------------------
    % Create instance of ArduinoGoggles control object
    % Note: check that COM port & Arduino model are correct (use Arduino IDE)
    ag = ArduinoGoggles('COM3','Mega2560');
  
    %----------------------------------------------------------------------
    %                       Experimental loop
    %----------------------------------------------------------------------
    graspWM_trials(ptb, part_dems, optk, ag, msgs, out, config_dat, stmap,...
        BaselineWM);


    % Flip again to sync us to the vertical retrace
    Screen('Flip', window);

    % End of experiment screen. We clear the screen once they have made their
    % response
    % Draw End of Experiment text
    DrawFormattedText(window, msgs.expEndMsg, ...
                ptb.exprmtrMsgLoc_x, ptb.exprmtrMsgLoc_y, ptb.text_color);
    Screen('Flip', window);
    KbStrokeWait;
    ShowCursor('arrow', window);
    
catch ME
    sca;
    ListenChar(0);
    rethrow(ME);
end
sca;