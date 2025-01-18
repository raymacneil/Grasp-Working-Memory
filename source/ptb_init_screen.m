function [ ptb ] = ptb_init_screen( monitor_diag )
%ptb_initscreen Inits Psychtoolbox and returns struct with window vars

%----------------------------------------------------------------------
%                       PyschToolbox Setup
%----------------------------------------------------------------------

ptb = struct();

%bypass psychtoolbox sync tests
Screen('Preference', 'SkipSyncTests', 2 );

% Reduce error messages to increase frame rate
Screen('Preference', 'Verbosity', 1);

% Setup PTB with some default values
PsychDefaultSetup(2);

% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle'). 
% Look at the help function of rand "help rand" for more information
rand('seed', sum(100 * clock));


%----------------------------------------------------------------------
%                       Display Information
%----------------------------------------------------------------------

% Get the screen numbers. This gives us a number for each of the screens
% attached to our computer. For help see: Screen Screens?
screens = Screen('Screens');

% Draw we select the maximum of these numbers. So in a situation where we
% have two screens attached to our monitor we will draw to the external
% screen. When only one screen is attached to the monitor we will draw to
% this. For help see: help max
ptb.screenNumber = max(screens);

% Define black and white (white will be 1 and black 0). This is because
% luminace values are (in general) defined between 0 and 1. For help see:
% help WhiteIndex and help BlackIndex
ptb.white = WhiteIndex(ptb.screenNumber);
ptb.black = BlackIndex(ptb.screenNumber);
ptb.grey = ptb.white / 2;
ptb.inc = ptb.white - ptb.grey;
ptb.red = [92 0 0];
ptb.green = [0 92 0];

% Open an on screen window and color the background For help see: Screen
% OpenWindow?
[ptb.window, ptb.windowRect] = PsychImaging('OpenWindow', ...
                                            ptb.screenNumber, ptb.grey);

% Hide cursor for touchscreen display (will use ShowCursor on program exit)
HideCursor(ptb.screenNumber);

% Retreive the maximum priority number and set max priority
topPriorityLevel = MaxPriority(ptb.window);
Priority(topPriorityLevel);

% Get the size of the on screen window in pixels For help see: Screen
% WindowSize?
[ptb.screenXpixels, ptb.screenYpixels] = Screen('WindowSize', ptb.window);

% Get the centre coordinate of the window in pixels For help see: help
% RectCenter
[ptb.xCenter, ptb.yCenter] = RectCenter(ptb.windowRect);

% Get Pixels per cm of current monitor, convert to centimeters
ptb.ppcm = sqrt(ptb.screenXpixels^2 + ptb.screenYpixels^2) / (2.54*monitor_diag);

% Enable alpha blending for anti-aliasing For help see: Screen
% BlendFunction? Also see: Chapter 6 of the OpenGL programming guide
Screen('BlendFunction', ptb.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Set the text size
Screen('TextSize', ptb.window, 30);
ptb.exprmtrMsgLoc_x = ptb.screenXpixels * 0.40;
ptb.exprmtrMsgLoc_y = ptb.screenYpixels * 0.55;

%----------------------------------------------------------------------
%                       Mouse & Keyboard information
%----------------------------------------------------------------------

% Use OSX internal naming scheme, to increase portability of this script
KbName('UnifyKeyNames');

% Define the keyboard keys that are listened for.
ptb.escapeKey = KbName('ESCAPE');
ptb.spaceKey = KbName('SPACE');
ptb.ctrlLKey = KbName('LeftControl');
ptb.ctrlRKey = KbName('RightControl');
ptb.minusKey = KbName('-_');
ptb.plusKey = KbName('=+');
ptb.aKey = KbName('a');
ptb.rKey = KbName('r');
ptb.fKey = KbName('f');
ptb.yKey = KbName('y');
ptb.nKey = KbName('n');
ptb.sKey = KbName('s');
ptb.F3Key = KbName('F3');
ptb.F12Key = KbName('F12');
ptb.oneKey = KbName('1!');
ptb.numpadOneKey = KbName('1');
ptb.twoKey = KbName('2@');
ptb.numpadTwoKey = KbName('2');

% Turn off character input to the Command Window
ListenChar(2);

%----------------------------------------------------------------------
%                       Timing Information
%----------------------------------------------------------------------

% Measure the vertical refresh rate of the monitor
ptb.ifi = Screen('GetFlipInterval', ptb.window);

% Numer of monitor frames to wait between screen renders (default: 1)
ptb.waitframes = 1;


end

