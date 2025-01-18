function dataReorg = ptb_end_optotrak(optk, out, part_dems, dataReorg, t, tn, bn, wm_rpt, write_dat)
%PTB_END_OPTOTRAK 

    DataBufferStop();
%     if write_dat
    optk.puSpoolComplete = 0;
    fprintf('spooling data\n');
    %transfer data from the optotrak to the computer
    while (optk.puSpoolComplete == 0)
        % call C library function here. See PDF
        [optk.puRealtimeData,optk.puSpoolComplete,optk.puSpoolStatus,optk.pulFramesBuffered] = ...
            DataBufferWriteData(optk.puRealtimeData,optk.puSpoolComplete,optk.puSpoolStatus,optk.pulFramesBuffered);
        WaitSecs(.1);
        if optk.puSpoolStatus ~= 0
            disp('Spooling Error');
            break;
        end
    end
%     disp('spooling complete. deactivating markers');
%     end
    
    %Deactivate the Markers
    OptotrakDeActivateMarkers();

    % disp(['attempting to read file: ' deblank([optk.NDIFPath optk.NDIFName])]);
    % open the .dat file stored by Optotrak
    [fid, ~] = fopen(deblank([optk.NDIFPath optk.NDIFName]),'r+','l'); % little endian byte ordering

    %Read the header portion of the file
    [~,items,subitems,numframes] = read_nd_c_file_header(fid);

    %Read the data portion of the file
    rawData = read_nd_c_file_data(fid, items, subitems, numframes);
    fclose(fid);

    if write_dat
        disp('converting data');
        %Convert the data to a format OTCTextWrite accepts
%         assignin('base', 'optk', optk);
%         assignin('base', 'dataReorg', dataReorg);
        idxShift = optk.NUMADDNTLROWS; 
        
        for i = 1:optk.nMarkers
            %append the marker data to dataReorg and delete the 
            dataReorg(1:size(rawData,3),(i*3+idxShift-2):(i*3+idxShift)) = ... 
                transpose(squeeze(rawData(i,:,:)));
        end

        %Convert missing data to NaNs
        dataReorg(dataReorg < optk.MISSINGDATACUTOFFVALUE) = NaN;
        
        %add the data collection information to the data
        dataReorg(:,1) = bn;
        dataReorg(:,2) = tn;       
        dataReorg(:,3) = t;
        dataReorg(:,4) = wm_rpt;
        dataReorg(:,5) = optk.smpRt;
       
        
        %navigate to the 'OTCReorganized' file folder
        NDIDatFile = [part_dems.id, optk.OPTO, 'bn', optk.block_txt, 'tn',... 
            optk.txtTrial, 't', optk.txtTrialCount 'rp', optk.txtRpt, 'bt', optk.txtBad, '.txt'];
        NDIDatHeader = ['BlockNum,','TrialNum,','TrialCount,',...
                        'RepeatFlag,','SampleRate,',...
                        'Mkr1_x,','Mkr1_y,','Mkr1_z,',...
                        'Mkr2_x,','Mkr2_y,','Mkr2_z,',...
                        'Mkr3_x,','Mkr3_y,','Mkr3_z,',...
                        'Mkr4_x,','Mkr4_y,','Mkr4_z,',...
                        'Mkr5_x,','Mkr5_y,','Mkr5_z,',...
                        'Mkr6_x,','Mkr6_y,','Mkr6_z\n'];
        %ALWAYS STORE A RAW DATA SET
%         disp(['Saving file: ' NDIDatFile ' ...'])
        fid = fopen([optk.NDIDatPath NDIDatFile], 'w');
        fprintf(fid, NDIDatHeader);
        fclose(fid);
        dlmwrite([optk.NDIDatPath NDIDatFile],...
                    dataReorg,'-append','delimiter',...
                    ',','newline','pc','precision',12);
        
                
        % TRANSFORMATION FROM GLOBAL TO LOCAL COORDINATE FRAME
        % optk.optoToRigid is defined in opto_getscreen_plane.m
        % This is achieved by first passing the data from the markers
        % representing the origin (bottom-left, Mkr 1), 
        % xplane (bottom-right Mkr 2), and the xyplane top-left, Mrk 3),
        % to the MakeCoordSystem function
        rigidOrigin = transform4(optk.optoToRigid, dataReorg(:,6:8));
        rigidX = transform4(optk.optoToRigid, dataReorg(:,9:11));
        rigidXY = transform4(optk.optoToRigid, dataReorg(:,12:14));
        mkr4 = transform4(optk.optoToRigid, dataReorg(:,15:17));
        mkr5 = transform4(optk.optoToRigid, dataReorg(:,18:20));
        mkr6 = transform4(optk.optoToRigid, dataReorg(:,21:23));
        dataTF = [dataReorg(:,1:5) rigidOrigin rigidX rigidXY mkr4 mkr5 mkr6];
        

        % OPTK Filename
        NDIDatFileTF = [part_dems.id, optk.OPTO, 'bn', optk.block_txt, 'tn',... 
            optk.txtTrial, 't', optk.txtTrialCount 'rp', optk.txtRpt, 'bt', optk.txtBad, 'tf.txt'];
        NDIDatHeaderTF = ['BlockNum,','TrialNum,','TrialCount,',...
                            'RepeatFlag,','SampleRate,',...
                            'Mkr1_x,','Mkr1_y,','Mkr1_z,',...
                            'Mkr2_x,','Mkr2_y,','Mkr2_z,',...
                            'Mkr3_x,','Mkr3_y,','Mkr3_z,',...
                            'Mkr4_x,','Mkr4_y,','Mkr4_z,',...
                            'Mkr5_x,','Mkr5_y,','Mkr5_z,',...
                            'Mkr6_x,','Mkr6_y,','Mkr6_z\n'];
%         disp(['Saving file: ' NDIDatFileTF ' ...'])
        fid = fopen([optk.NDIDatPathTF NDIDatFileTF], 'w');
        fprintf(fid, NDIDatHeaderTF);
        fclose(fid);
        dlmwrite([optk.NDIDatPathTF NDIDatFileTF],...
                   dataTF,'-append','delimiter',...
                    ',','newline','pc','precision',12);
        disp('Success!')
    end
end

