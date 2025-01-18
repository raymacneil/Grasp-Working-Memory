function optk = ptb_init_optotrak(opto_initialized, out, part_dems, max_trial_time)
% instrreset
% opto_initialized = 0; 
% olddir = pwd;

% % prompt for UID
% % this may as well be a function
% prompt = {'Enter subject ID:'}; %,'Enter configuration file name:'};
% dlg_title = 'Subject ID';
% num_lines= 1;
% def     = {uuid};
% answer  = inputdlg(prompt,dlg_title,num_lines,def);
% 
% %if the user clicks 'cancel', 'answer' is empty. Quit the program.
% if isempty(part_dems.id)
%     return;
% end
% % end prompt

% %select the subject's folder
% expDir = uigetdir('Select a Directory to store the Subject''s data');
% cd(expDir)

% %create a new file folder to store the participant's data in
% [~, fname, ext] = fileparts(config_fname);
% part_out_path = [out_path part_dems.id '/' fname '/'];
% if exist(part_out_path, 'dir') == 7
% else
%     mkdir(expDir,part_dems.id);
% end
% cd(part_dems.id)

% Struct containing Optotrak variables
optk = struct();

optk.OPTO = '_opto_';
optk.FNRAWDATA = 'RawNDIDatFiles';
optk.FNOTCREORG = 'OTCReorganized';
optk.FNOTCREORG_TF = 'OTCReorganizedTF';
optk.fixation_threshold = 75;
optk.MISSINGDATACUTOFFVALUE = -3.6972e28; %an 'anything less than' cutoff value for missing data, 
optk.RAWDATAROW = 4; %the row at and beyond which the raw positional data is stored
optk.NUMADDNTLROWS = 3;

%create a new file folder to store the NDI raw data if the folder does not exist
NDI_dat_path = out.part_out_path;
% NDI_dat_dir = 'FNRAWDATA';
NDI_dat_dir = optk.FNRAWDATA; 
if exist([NDI_dat_path '/' NDI_dat_dir], 'dir') == 7
else
    mkdir(NDI_dat_path, NDI_dat_dir);
end
optk.NDIFPath = [out.part_out_path optk.FNRAWDATA '/'];

%create a new file folder to store the reorganized data if the folder does not exist
% NDI_dat_reorg_dir = 'FNOTCREORG';
NDI_dat_reorg_dir = optk.FNOTCREORG;
if exist([NDI_dat_path '/' NDI_dat_reorg_dir], 'dir') == 7
else
    mkdir(NDI_dat_path, NDI_dat_reorg_dir);
end
optk.NDIDatPath = [out.part_out_path optk.FNOTCREORG '/'];

NDI_dat_tf_dir = optk.FNOTCREORG_TF;
if exist([NDI_dat_path '/' NDI_dat_tf_dir], 'dir') == 7
else
    mkdir(NDI_dat_path, NDI_dat_tf_dir);
end
optk.NDIDatPathTF = [out.part_out_path optk.FNOTCREORG_TF '/'];

% eyelink works, let's set up the Optotrack stuff here.
if opto_initialized==0
    optotrak_init
end

%setup collection parameters. 'nMarkersPerPort' is a 4 element array with
%'0' for the 4th element.
% OTCParamsHandler is creates a GUI prompt for the parameters
% realistically the values are probably known beforehand, maybe just set
% those as defaults so experimenter can "enter" through
%[nMarkers, smpRt, smpTime, nMarkersPerPort] = OTCParamsHandler;
nMarkers=6; smpRt=200; smpTime=max_trial_time+0.2; 
nMarkersPerPort=[0 nMarkers 0 0];
optk.nMarkers=nMarkers;
optk.smpRt=200;
optk.smpTime=smpTime;

%setup the strober specific information (number of markers per
%port)...NOTE, this function requires a value for a 4th port, but since the
%Certus only has 3, this 4th value is always 0
OptotrakSetStroberPortTable(nMarkersPerPort(1),nMarkersPerPort(2),...
    nMarkersPerPort(3),nMarkersPerPort(4));

%setup collection - note, these values are from Binstead code,
%which match those listed in the API.
nMarkers = sum(sum(nMarkersPerPort));
fMarkerFrequency = 2500.0;
nThreshold = 30;
nMinimumGain = 160;
nStreamData = 0;
fDutyCycle = 0.5;
fVoltage = 8.0;
fPreTriggerTime = 0.0;
nFlags = 0;

% setup.
OptotrakSetupCollection(nMarkers,smpRt,fMarkerFrequency,nThreshold,...
    nMinimumGain,nStreamData,fDutyCycle,fVoltage,smpTime,fPreTriggerTime,...
    nFlags);


% Realtome optotrak variables
optk.puFrmNum = 0;
optk.puElmnts = 0;
optk.puFlgs = 0;

%Raw data, Reorganized Data
A = {}; B = {};

%compute additional collection parameters
optk.ISI = (1/optk.smpRt); %inter-sample-interval (in seconds).
optk.framesPerTrial = smpTime/optk.ISI; %the total number of sample frames to collect per trial

WaitSecs(1); %wait times recommended in API
OptotrakActivateMarkers();
WaitSecs(2); %wait times recommended in API

% optotrack set should be finished before the loop

% cd(olddir);
end