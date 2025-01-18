function [optk, mkPos, mkSpeed, mkDis] = ptb_optotrak_collect_sample(optk, marker_num, smpRt, frame)
%PTB_OPTOTRAK_COLLECT_SAMPLE Collect a real-time Optotrak sample w/ vel

%Store the raw, real-time optotrak data (which is returned as a column vector)
[optk.rnFlags, optk.puFrmNum, optk.puElmnts, optk.puFlgs, optk.dataNDI_rt(optk.RAWDATAROW:end,frame)] = ...
      DataGetLatest3d(optk.puFrmNum, optk.puElmnts, optk.puFlgs, optk.dataNDI_rt(optk.RAWDATAROW:end,frame));
           
% Transform into screen-plane coordinates and save in separate data array
formatted_optk_sample = reshape(optk.dataNDI_rt(optk.RAWDATAROW:end,frame), 3, optk.nMarkers)';
rigidOrigin = transform4(optk.optoToRigid, formatted_optk_sample)';
optk.dataNDI_tf(optk.RAWDATAROW:end,frame) = rigidOrigin(:);

% Frame 1 has no acceleration
if frame == 1
    mkSpeed = 0; mkDis = [0,0,0];
%if there is missing data, assume no movement
elseif any(any(optk.dataNDI_tf(marker_num,frame-1:frame) < optk.MISSINGDATACUTOFFVALUE))
    mkSpeed = 0; mkDis = [0,0,0];
    %if there is missing data, assume no movement
elseif any(any(optk.dataNDI_tf(marker_num,frame-1:frame) == 0))
    mkSpeed = 0; mkDis = [0,0,0];
%otherwise, compute the speed of the marker
else
    [mkSpeed, mkDis] = MarkerSpeedRows(optk.dataNDI_tf(marker_num,frame-1:frame), smpRt);
end

mkPos = optk.dataNDI_tf(marker_num,frame);
optk.mkr_position(frame,:) = mkPos;
optk.mkr_speed(frame) = mkSpeed;
optk.mkr_displacement(frame,:) = mkDis;


end

