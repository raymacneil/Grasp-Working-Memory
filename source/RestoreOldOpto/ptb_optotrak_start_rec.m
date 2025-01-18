function [optk, dataReorg] = ptb_optotrak_start_rec(optk, out, dataReorg, part_dems, bn, tn, t, wm_rpt)
%PTB_OPTOTRAK_START_REC Summary of this function goes here
%   Detailed explanation goes here
    optk.puRealtimeData=0;optk.puSpoolComplete=0;
    optk.puSpoolStatus=0;optk.pulFramesBuffered=0;

    %determine the trial number text
    optk.txtTrial = [num2str(tn, '%03d') '_']; % pad left side with zeros
   

    %determine block number text
    optk.block_txt = [num2str(bn, '%02d') '_']; % pad left side with zeros
    optk.txtTrialCount = [num2str(t, '%03d'), '_']; % pad left side with zeros
    optk.txtBad = '';
    optk.txtRpt = [num2str(wm_rpt, '%02d'), '_']; 
    
    
%     optk.txtRptFlag = [num2str(rn, '%02d

%             optotrack_trial_mapping = [optotrack_trial_mapping; [int2str(tn) current_trial_name]];

    %The NDI dat file name for the current trial
    optk.NDIFName = [part_dems.id optk.OPTO optk.block_txt optk.txtTrial optk.txtTrialCount '.dat'];

    if tn == 1
        %re-initialize the reorganized data
        dataReorg = NaN(optk.framesPerTrial, (optk.nMarkers*3) + optk.NUMADDNTLROWS);
    end
    
    %initialize dataNDI so that it will accept the raw Optotrak data from
    %'DataGetNext3D'. NOTE that 'DataGetNext3D' outputs the positional data
    %as a column vector.
    optk.dataNDI_rt = single(zeros((optk.nMarkers * 3) + optk.NUMADDNTLROWS, optk.framesPerTrial));
    optk.dataNDI_tf = single(zeros((optk.nMarkers * 3) + optk.NUMADDNTLROWS, optk.framesPerTrial));
    optk.dataNDI_init = single(zeros((optk.nMarkers * 3) + optk.NUMADDNTLROWS,1));
    optk.mkr_speed = zeros(optk.framesPerTrial,1);
    optk.mkr_position = single(zeros(optk.framesPerTrial,3));
    optk.mkr_displacement = zeros(optk.framesPerTrial,3);
    
% -------------- Start the optotrack recording here! -------------------- %
    %start collecting data, the number of frames to collect was
    %pre-specified by the function OPTOTRAKSETUPCOLLECTION.

    %initialize the file for spooling
    OptotrakActivateMarkers();
    WaitSecs(0.010);
    DataBufferInitializeFile(0,[optk.NDIFPath optk.NDIFName]);
    DataBufferStart();
    
    WaitSecs(0.10);
    optk = opto_get_screen_plane(optk, 1, 2, 3); % define marker numbers
    % origin (bottom left) = 1, xplane (bottom right) = 2, xyplane (top
    % right) = 3
end

