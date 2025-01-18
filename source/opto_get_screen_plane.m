function optk = opto_get_screen_plane(optk, mkr_origin, mkr_xplane, mkr_xyplane)
%%OPTO_GET_SCREEN_PLANE 
% Updated by Raymond MacNeil, 2024-05-31, Vision Lab
% Changed hard-coding of indices for extracting reference markers positional data
% so that it is now dependent on the number of auxillary rows included 
% in the optotrak data output.
%  mkr_origin = bottom left of tabletop screen (relative to experimenter) 
%                                      (default = marker 1)
%  mkr_xplane = bottom right of screen (default = marker 2)
%  mkr_xyplane = top right of  screen  (default = marker 3)

% Define marker rows in optotrak data table based on marker number
% see default numbering above
mkr_origin_rows = ((mkr_origin*3) + optk.NUMADDNTLROWS - 2):((mkr_origin*3) + optk.NUMADDNTLROWS); % 6-8
mkr_xplane_rows = ((mkr_xplane*3) + optk.NUMADDNTLROWS - 2):((mkr_xplane*3) + optk.NUMADDNTLROWS); % 9-11
mkr_xyplane_rows = ((mkr_xyplane*3) + optk.NUMADDNTLROWS - 2):((mkr_xyplane*3) + optk.NUMADDNTLROWS); % 12-14

loop_first_sample = false;
optk.first_smp_success = false;
max_first_sample_tries = 250;
num_first_sample_tries = 0;

while ~loop_first_sample
    %Store the raw, real-time optotrak data (which is returned as a
    %column vector)
    [optk.rnFlags, optk.puFrmNum, optk.puElmnts, optk.puFlgs, optk.dataNDI_init(optk.RAWDATAROW:end)] = ...
          DataGetNext3D(optk.puFrmNum, optk.puElmnts, optk.puFlgs, optk.dataNDI_init(optk.RAWDATAROW:end));

    %get rotation/translation from opto coords to this new coord frame
    [optk.optoToRigid,optk.rigidToOpto]=MakeCoordSystem(optk.dataNDI_init(mkr_origin_rows),...
                                                        optk.dataNDI_init(mkr_xplane_rows),...
                                                        optk.dataNDI_init(mkr_xyplane_rows));

    if any(any(isnan(optk.optoToRigid))) || any(any(isnan(optk.rigidToOpto)))
        num_first_sample_tries = num_first_sample_tries + 1;
        if num_first_sample_tries > max_first_sample_tries
            loop_first_sample = true;
        end
    else
        loop_first_sample = true;
        optk.first_smp_success = true;
    end
end

end

