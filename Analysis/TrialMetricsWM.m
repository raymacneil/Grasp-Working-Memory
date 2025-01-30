function MetricData = TrialMetricsWM(ParticipantData, SampleRate, VTon, VToff, VDon, VDoff)

% Updated 10-10-2024, Raymond MacNeil
% Added flagging variables to identify if landmark frames or windows
% contain interpolated data. Metrics based on interpolated data should be
% treated with some suspicion, and particularly so if it depends on
% interpolated data across two markers.


% Updated 10-09-2024, Raymond MacNeil
% Added function to compute a trial-level adjustment factor for PGA to
% account for the extra distance in grip aperture due to the rigid bodies. 
% Exploits the fact that at the beginning of the trial, prior to reach onset, 
% the thumb and index finger are pinched together. See RigidGA() for further details. 

% Updated 09-23-2024, Raymond MacNeil
% Overhauled variable names, and adjusted variable assignment so that data
% would not be thrown out. Namely, Try-Catch blocks were chunking too much
% data together.



VTonDefault = 50;
VToffDefault = 75;
VDonDefault = 60;
VDoffDefault = 10;

% Define default parameters if undefined
if nargin < 3
    VTon = VTonDefault; VToff = VToffDefault;
    VDon = VDonDefault; VDoff = VDoffDefault;
elseif nargin < 4
    VToff = VToffDefault;
    VDon = VDonDefault; VDoff = VDoffDefault;
elseif nargin < 5
    VDon = VDonDefault; VDoff = VDoffDefault;
elseif nargin < 6
    VDoff = VDoffDefault;
end

varNames = ["id","Block","Trial_id","TrialCount_tfsdat",...
    "TimetoRon","TimetoPGA","TimetoPGAFlag","PeakVelH","PeakVelI","PeakVelTh","PeakVelAvg","PeakGAVelOpen","PeakGAVelClose"...
    "LDJ_GAVelOpen","SPARC_GAVelOpen","GAOpen_Interp_Flag", "GAOpen_Knot_Size","LDJ_GAVelOpen2","SPARC_GAVelOpen2", "LDJ_GAVelClose","SPARC_GAVelClose"...
    "GAClose_Interp_Flag", "GAClose_Knot_Size", "PGA","PGAVel","PGAadj","PGA_Interp_Flag",'GARon','GAAtPvelOpen','GAAtPvelClose','GARoff',"GACloseMag","barAngle","barLength",...
    "LDJ_Early","SPARC_Early", "ft0","fRonH","fRonTh","fRonI","fRon","fPGA","fRoffH","fRoffTh","fRoffI","fRoffIZMin","fRoffTZMin","fRoffVT","fRoffZMin","fRoffVTorZMin",...
    "fPeakVelH","fPeakVelI","fPeakVelTh","fPeakVelAvg","fPeakGAVelOpen","fPeakGAVelClose","VTon","VToff","VDon","VDoff"];

varTypes = ["categorical", repelem("single",length(varNames)-1)];
T = table('Size',[(sum(~cellfun('isempty',ParticipantData))-1),length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);
T{:,5:end-1} = nan;

flagNames = {'VelError','GAVelError','XYZVelSmoothError','GAVelSmoothError'};
trialCount = 0;

    for ii = 1:(sum(~cellfun('isempty',ParticipantData))-1)
        temp = ParticipantData{ii+1,1,1};
        flagIdx = false(length(flagNames),1);
        trialCount = trialCount + 1;
        fprintf("Computing metrics for block %d trial %d\n",temp.block(1),temp.trial(1));
        
        % Experiment info
        T.id(ii) = categorical(cellstr(ParticipantData{1,1,1}));
        T.Block(ii) = temp.block(1);
        T.Trial_id(ii) = temp.trial(1);
        T.TrialCount_tfsdat(ii) = temp.TrialCount(1);
        T.barAngle(ii) = temp.barAng(1);
        T.barLength(ii) = temp.barLen(1);
        T.VTon(ii) = VTon;
        T.VToff(ii) = VToff;
        T.VDon(ii) = VDon;
        T.VDoff(ii) = VDoff;
        
        
        % Interpolation of frames for a single marker 
        interpolation_flag1_ref = find( ( sum([temp.mkr5_intrp,temp.mkr6_intrp],2) == 1 ) );
        % Interpolation of frames for two markers
        interpolation_flag2_ref = find(and(temp.mkr5_intrp,temp.mkr6_intrp));
        
        %             if strcmp(string(T.id(ii)),"zb9y474")
        %                 VDon = 40;
        %             end
        
        % PGA info
        try
            T.fPGA(ii) = PeakGA2(temp, VTon, VToff, VDon, VDoff);
        catch
            VDon = 40; % Reset VDon for this trial
            T.fPGA(ii) = PeakGA2(temp, VTon, VToff, VDon, VDoff);
            T.VDon(ii) = VDon;
            
        end
        
        if ~isnan(T.fPGA(ii))
            T.PGA(ii) = temp.GAxyz(T.fPGA(ii));
            T.PGAVel(ii) = temp.GAxyz_vel(T.fPGA(ii));
        else
            T.PGA(ii) = NaN;
            T.PGAVel(ii) = NaN;
        end
        
        
        
        if any(T.fPGA(ii) == interpolation_flag2_ref)
            T.PGA_Interp_Flag(ii) = 2;
        elseif any(T.fPGA(ii) == interpolation_flag1_ref)
            T.PGA_Interp_Flag(ii) = 1;
        else
            T.PGA_Interp_Flag(ii) = 0;
        end
        
        % Index info
        T.fRonI(ii) = fwdReachStart(temp.mkrIXYZ_vel, VTon, VToff, VDon, VDoff);
        T.fRoffI(ii) = fwdReachEndVelocityThreshold(temp.mkrIXYZ_vel, T.fPGA(ii),... 
            VToff, VDoff);
        
        % Thumb info
        T.fRonTh(ii) = fwdReachStart(temp.mkrTXYZ_vel, VTon, VToff, VDon, VDoff);
        T.fRoffTh(ii) = fwdReachEndVelocityThreshold(temp.mkrTXYZ_vel, T.fPGA(ii),... 
            VToff, VDoff);
        
        % Hand info
        T.fRonH(ii) = fwdReachStart(temp.mkrHXYZ_vel, VTon, VToff, VDon, VDoff);
        T.fRoffH(ii) = fwdReachEndVelocityThreshold(temp.mkrIXYZ_vel, T.fPGA(ii),... 
            VToff, VDoff);
        
        % Final values
        T.fRon(ii) = min(T.fRonI(ii),T.fRonTh(ii));
        T.fRoffIZMin(ii) = fwdReachEndZMin(temp.mkr5Z, T.fPGA(ii), 20, 100);
        T.fRoffTZMin(ii) = fwdReachEndZMin(temp.mkr6Z, T.fPGA(ii), 20, 100);
        T.fRoffVT(ii) = min(T.fRoffI(ii),T.fRoffTh(ii));
        T.fRoffZMin(ii) = min(T.fRoffIZMin(ii),T.fRoffTZMin(ii));
        T.fRoffVTorZMin(ii) = min([T.fRoffI(ii),T.fRoffTh(ii),T.fRoffIZMin(ii),T.fRoffTZMin(ii)]);
        
        ft0Criteria = sum(~isnan([temp.mkrHXYZ_vel,temp.mkrIXYZ_vel,temp.mkrTXYZ_vel]),2) > 0;
        T.ft0(ii) = find(ft0Criteria,1,'first');
        
        % Time info
        SecPerSamp = 1/SampleRate;
        T.TimetoRon(ii) = T.fRon(ii) * SecPerSamp;
        T.TimetoPGA(ii) = T.fPGA(ii) * SecPerSamp;
        
        if temp.mkrHXYZ_vel(T.ft0(ii)+1) > VTon || temp.mkrIXYZ_vel(T.ft0(ii)+1) > VTon || temp.mkrTXYZ_vel(T.ft0(ii)+1) > VTon
            T.TimetoPGAFlag(ii) = 1;
            T.PGAadj(ii) = NaN;
        else
            T.TimetoPGAFlag(ii) = 0;
            T.PGAadj(ii) = RigidGA(temp.GAxyz, temp.GAxyz_vel, 10, T.fRon(ii));
        end
        
        if any(ismember(T.fRon(ii):T.fPGA(ii),interpolation_flag2_ref))
            T.GAOpen_Interp_Flag(ii) = 2;
            T.GAOpen_Knot_Size(ii) = sum(ismember(T.fRon(ii):T.fPGA(ii),interpolation_flag2_ref));
        elseif any(ismember(T.fRon(ii):T.fPGA(ii),interpolation_flag1_ref))
            T.GAOpen_Interp_Flag(ii) = 1;
            T.GAOpen_Knot_Size(ii) = sum(ismember(T.fRon(ii):T.fPGA(ii),interpolation_flag1_ref));
        else
            T.GAOpen_Interp_Flag(ii) = 0;
            T.GAOpen_Knot_Size(ii) = 0;
        end
        
        %%%%%%%%% TO FOLLOW UP ON %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if any(ismember(T.fPGA(ii):T.fRoffVT(ii),interpolation_flag2_ref))
            T.GAClose_Interp_Flag(ii) = 2;
            T.GAClose_Knot_Size(ii) = sum(ismember(T.fPGA(ii):T.fRoffVTorZMin(ii),interpolation_flag2_ref));
        elseif any(ismember(T.fPGA(ii):T.fRoffVTorZMin(ii),interpolation_flag1_ref))
            T.GAClose_Interp_Flag(ii) = 1;
            T.GAClose_Knot_Size(ii) = sum(ismember(T.fPGA(ii):T.fRoffVTorZMin(ii),interpolation_flag1_ref));
        else
            T.GAClose_Interp_Flag(ii) = 0;
            T.GAClose_Knot_Size(ii) = 0;
        end
        
        
        try
            [T.PeakVelH(ii),T.fPeakVelH(ii)] = max(temp.mkrHXYZ_vel(T.fRonH(ii):T.fRoffVTorZMin(ii)));
            T.fPeakVelH(ii) = T.fPeakVelH(ii) + T.fRonH(ii);
        catch
            warning("Error finding IDX peak velocity metrics: trial should be examined.\n");
        end
        
        
        try
            [T.PeakVelI(ii),T.fPeakVelI(ii)] = max(temp.mkrIXYZ_vel(T.fRonI(ii):T.fRoffVTorZMin(ii)));
            T.fPeakVelI(ii) = T.fPeakVelI(ii) + T.fRonI(ii);
        catch
            warning("Error finding IDX peak velocity metrics: trial should be examined.\n");
        end
        
        try
            [T.PeakVelTh(ii),T.fPeakVelTh(ii)] = max(temp.mkrTXYZ_vel(T.fRonTh(ii):T.fRoffVTorZMin(ii)));
            T.fPeakVelTh(ii) = T.fPeakVelTh(ii) + T.fRonTh(ii);
        catch
            warning("Error finding THB peak velocity metrics: trial should be examined.\n");
        end
        
        ft0 = T.ft0(ii);
        fRon = T.fRon(ii);
        fPGA = T.fPGA(ii);
        fRoff = T.fRoffVTorZMin(ii);
        
        
        try
            [T.PeakVelAvg(ii),T.fPeakVelAvg(ii)] = max( (1/3) * ( temp.mkrIXYZ_vel( fRon:fRoff )...
                + temp.mkrTXYZ_vel( fRon:fRoff )...
                + temp.mkrHXYZ_vel( fRon:fRoff ) ) );
            T.fPeakVelAvg(ii) = T.fPeakVelAvg(ii) + fRon;
        catch
            warning("Error finding average peake velocity metrics: trial should be examined.\n");
        end
        
        % Grip Aperture Velocity info
        try
            [T.PeakGAVelOpen(ii),T.fPeakGAVelOpen(ii)] = max( abs( diff( temp.GAxyz( fRon:fPGA ) ) * SampleRate) );
            T.fPeakGAVelOpen(ii) = T.fPeakGAVelOpen(ii) + fRon;
        catch
            warning("Error finding GA Open Velocity metrics, trial should be examined.\n");
        end
        
        try
            [T.PeakGAVelClose(ii),T.fPeakGAVelClose(ii)] = max( abs( diff( temp.GAxyz( fPGA:fRoff ) ) * SampleRate  ) );
            T.fPeakGAVelClose(ii) = T.fPeakGAVelClose(ii) + fPGA;
        catch
            warning("Error finding GA Close Velocity metrics, trial should be examined.\n");
        end
        
        
        if ~isnan(fRon)
            T.GARon(ii) = temp.GAxyz(fRon);
        else
            T.GARon(ii) = NaN;
        end
        
        if ~isnan(T.fPeakGAVelOpen(ii))
            T.GAAtPvelOpen(ii) = temp.GAxyz(T.fPeakGAVelOpen(ii));
        else
            T.GAAtPvelOpen(ii) = NaN;
        end
        
        if ~isnan(T.fPeakGAVelClose(ii))
            T.GAAtPvelClose(ii) = temp.GAxyz(T.fPeakGAVelClose(ii));
        else
            T.GAAtPvelClose(ii) = NaN;
        end
        
        if ~isnan(fRoff)
            T.GARoff(ii) = temp.GAxyz(fRoff);
        else
            T.GARoff(ii) = NaN;
        end
        
        T.GACloseMag(ii) = T.PGA(ii) - T.GARoff(ii);
        
        
        % Compute SPARC and LDJ for early aperture opening interval: ft0->fRon,
        %             T.LDJ_Early(ii) = LogDimensionlessJerk(diff( temp.GAxyz( ft0:fRon ) ), 20);
        %             T.SPARC_Early(ii) = SpectralArcLength(diff( temp.GAxyz( ft0:fRon ) ), 0.05);
        %
        %             % Compute SPARC and LDJ for GA Velocity intervals opening: fRon->fPGA, close: fPGA->fRoff
        %
        %             % Smoothness for opening grip aperture
        %             T.LDJ_GAVelOpen(ii) = LogDimensionlessJerk(diff( temp.GAxyz( fRon:fPGA ) ), 20);
        %             T.SPARC_GAVelOpen(ii) = SpectralArcLength(diff( temp.GAxyz( fRon:fPGA ) ), 0.05);
        %
        %             % Smoothness for closing grip aperture
        %             T.LDJ_GAVelClose(ii) = LogDimensionlessJerk(diff( temp.GAxyz( fPGA:fRoff ) ), 20);
        %             T.SPARC_GAVelClose(ii) = SpectralArcLength(diff( temp.GAxyz( fPGA:fRoff ) ), 0.05);
        %
        
        
        % Compute SPARC and LDJ for early aperture opening interval: ft0->fRon,
        T.LDJ_Early(ii) = LogDimensionlessJerk(temp.GAxyz_vel( ft0:fRon ), SampleRate);
        T.SPARC_Early(ii) = SpectralArcLength(temp.GAxyz_vel( ft0:fRon ), 1/SampleRate);
        
        % Compute SPARC and LDJ for GA Velocity intervals opening: fRon->fPGA, close: fPGA->fRoff
        
        % Smoothness for opening grip aperture
        T.LDJ_GAVelOpen(ii) = LogDimensionlessJerk(temp.GAxyz_vel( fRon:fPGA ), SampleRate);
        if T.LDJ_GAVelOpen(ii) > 0
            T.LDJ_GAVelClose(ii) = NaN;
        end
        
        if isnan(T.LDJ_GAVelOpen(ii))
            T.SPARC_GAVelOpen(ii) = NaN;
        else
            T.SPARC_GAVelOpen(ii) = SpectralArcLength(temp.GAxyz_vel( fRon:fPGA ), 1/SampleRate);
        end
        
        if ~isnan(T.fPeakGAVelOpen(ii))
            T.LDJ_GAVelOpen2(ii) = LogDimensionlessJerk(temp.GAxyz_vel( T.fPeakGAVelOpen(ii):fPGA ), SampleRate);
        else
            T.LDJ_GAVelOpen2(ii) = NaN;
        end
        
        if T.LDJ_GAVelOpen2(ii) > 0
            T.LDJ_GAVelOpen2(ii) = NaN;
        end
        
        if isnan(T.LDJ_GAVelOpen2(ii))
            T.SPARC_GAVelOpen2(ii) = NaN;
        else
            T.SPARC_GAVelOpen2(ii) = SpectralArcLength(temp.GAxyz_vel( T.fPeakGAVelOpen(ii):fPGA ), 1/SampleRate);
        end
        
        try
            % Smoothness for closing grip aperture
            T.LDJ_GAVelClose(ii) = LogDimensionlessJerk(temp.GAxyz_vel( fPGA:fRoff ), SampleRate);
            if T.LDJ_GAVelClose(ii) > 0
                T.LDJ_GAVelClose(ii) = NaN;
            end
            
        catch
            T.LDJ_GAVelClose(ii) = NaN;
        end
        
        
        if isnan(T.LDJ_GAVelClose(ii))
            T.SPARC_GAVelClose(ii) = NaN;
        else
            T.SPARC_GAVelClose(ii) = SpectralArcLength(temp.GAxyz_vel( fPGA:fRoff ), 1/SampleRate);
        end
        
        
        if VDon ~= VDonDefault
            VDon = VDonDefault;
        end
        
    end
    
    MetricData = T;

end

