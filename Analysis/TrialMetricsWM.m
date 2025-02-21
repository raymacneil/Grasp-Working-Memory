function MetricData = TrialMetricsWM(ParticipantData, SampleRate, VTon, VToff, VDon, VDoff, graspTag, modeTag)

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
VDoffDefault = 5;

VToffPGA = 0;
VDoffPGA = 16;
VTonFwdPGA = 100;
VDonFwdPGA = 25;
ZLocalPromThreshold = 10; 
ZMinThreshold = 100;

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

expTag = 'Digits';

if strcmp(graspTag, 'NaturalGrasp')
    graspFigTag = 'ng';
else
    graspFigTag = 'pg';
end

if strcmp(modeTag, 'Single')
    modeFigTag = 'single';
else
    modeFigTag = 'dual';
end

idTag = ParticipantData{1,1,1};
figOutPathBase = ['C:\Users\Vision Lab\Desktop\Grasp-Working-Memory\Analysis\Output\LandmarkPlots\', expTag, '\', idTag];

if ~exist(figOutPathBase, 'dir')
   mkdir(figOutPathBase)
end


FigNamePrefix = [idTag, '-', graspFigTag, '-', modeFigTag, '-'];

varNames = ["id","Block","Trial_id","TrialCount_tfsdat",...
    "LMarkFigName","TimetoRon","TimetoPGA","TimetoPGAFlag","PeakVelH","PeakVelI","PeakVelTh","PeakVelAvg","PeakGAVelOpen","PeakGAVelClose"...
    "LDJ_GAVelOpen","SPARC_GAVelOpen","GAOpen_Interp_Flag", "GAOpen_Knot_Size","LDJ_GAVelOpen2","SPARC_GAVelOpen2", "LDJ_GAVelClose","SPARC_GAVelClose"...
    "GAClose_Interp_Flag", "GAClose_Knot_Size", "PGA","PGAadj","PGA_Interp_Flag",'GARon','GAAtPvelOpen','GAAtPvelClose','GARoff',"GACloseMag","barAngle","barLength",...
    "LDJ_Early","SPARC_Early", "ft0","fRonH","fRonT","fRonI","fRon","fPGA", "fPGAZBound", "fRoffH","fRoffT","fRoffI","fRoffIZMin","fRoffTZMin","fRoffVT","RoffVTVel","fRoffZMin","RoffZMinVel","fRoffVTorZMin",...
    "fPeakVelH","fPeakVelI","fPeakVelTh","fPeakVelAvg","fPeakGAVelOpen","fPeakGAVelClose","VTon","VToff","VDon","VDoff"];

varTypes = ["categorical", repelem("single",length(varNames)-1)];
T = table('Size',[(sum(~cellfun('isempty',ParticipantData))-1),length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);
T{:,5:end-1} = nan;

% flagNames = {'VelError','GAVelError','XYZVelSmoothError','GAVelSmoothError'};
trialCount = 0;

    for ii = 1:(sum(~cellfun('isempty',ParticipantData))-1)
        temp = ParticipantData{ii+1,1,1};
        % flagIdx = false(length(flagNames),1);
        trialCount = trialCount + 1;
        fprintf("Computing metrics for participant %s, block %d trial %d\n",ParticipantData{1,1,1}, temp.block(1), temp.trial(1));
        
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

        % Get tags for saving the landmark plots
        bnTag = ['bn', '0', num2str(temp.block(1))];
        tnTag = num2str(temp.trial(1));
        if numel(tnTag) < 2
           tnTag = ['tn0', tnTag];
        else
           tnTag = ['tn', tnTag];
        end
        rpTag = ['rp0', num2str(temp.RepeatFlag(1))];
        tcTag = num2str(temp.TrialCount(1));
        tcTagPads = {'00', '0', ''};
        tcTag = ['t', tcTagPads{numel(tcTag)}, tcTag]; 
        figNameSuffix = [bnTag, '-', tnTag, '-', rpTag, '-', tcTag, '.fig'];
        figName = [FigNamePrefix, figNameSuffix];
        figOutPath = fullfile(figOutPathBase, figName); 
        
        
        
        % Interpolation of frames for a single marker 
        interpolation_flag1_ref = find( ( sum([temp.mkr5_intrp,temp.mkr6_intrp],2) == 1 ) );
        % Interpolation of frames for two markers
        interpolation_flag2_ref = find(and(temp.mkr5_intrp,temp.mkr6_intrp));
        
        %             if strcmp(string(T.id(ii)),"zb9y474")
        %                 VDon = 40;
        %             end
        
        % PGA info
        try
            [T.fPGA(ii), T.fPGAZBound(ii)] = PeakGA2(temp, VTonFwdPGA, VDonFwdPGA, VToffPGA, VDoffPGA);
%             T.fPGA(ii) = PeakGA3(temp, VTon, VDon, 1);
        catch
            VDon = 40; % Reset VDon for this trial
            [T.fPGA(ii), T.fPGAZBound(ii)] = PeakGA2(temp, VTonFwdPGA, VDonFwdPGA, VToffPGA, VDoffPGA);
            T.VDon(ii) = VDon;
            
        end
        
        if ~isnan(T.fPGA(ii))
            T.PGA(ii) = temp.GAxyz(T.fPGA(ii));
        else
            T.PGA(ii) = NaN;
        end
        
        
        
        if any(T.fPGA(ii) == interpolation_flag2_ref)
            T.PGA_Interp_Flag(ii) = 2;
        elseif any(T.fPGA(ii) == interpolation_flag1_ref)
            T.PGA_Interp_Flag(ii) = 1;
        else
            T.PGA_Interp_Flag(ii) = 0;
        end
        
        % Reach onset frames info
        T.fRonI(ii) = fwdReachStart(temp.mkrIXYZ_vel, VTon, VDon); % Index
        T.fRonT(ii) = fwdReachStart(temp.mkrTXYZ_vel, VTon, VDon); % Thumb
        T.fRonH(ii) = fwdReachStart(temp.mkrHXYZ_vel, VTon, VDon); % Knuckle / Wrist
        T.fRon(ii) = min(T.fRonI(ii),T.fRonT(ii)); % Defining landmark frame for reach onsetr
     
        
        % REACH OFFSET DEFINED BY VELOCITY THRESHOLDS
            
        T.fRoffH(ii) = fwdReachEndVelocityThreshold(temp.mkrHXYZ_vel, T.fPGA(ii),... 
            VToff, VDoff);      
        T.fRoffVT(ii) = NaN;
        VToffPreLoop = VToff;
        while isnan(T.fRoffVT(ii)) && VToff <= 100
            T.VToff(ii) = VToff;
            T.fRoffI(ii) = fwdReachEndVelocityThreshold(temp.mkrIXYZ_vel, T.fPGA(ii),...
                VToff, VDoff);
            T.fRoffT(ii) = fwdReachEndVelocityThreshold(temp.mkrTXYZ_vel, T.fPGA(ii),... 
                VToff, VDoff);      
            [T.fRoffVT(ii), MkrIdx] = min([T.fRoffI(ii),T.fRoffT(ii)]);
            VToff = VToff + 1;
        end
        VToff = VToffPreLoop;    
        % Get flag to mark whether landmark is defined by index or thumb   
        if MkrIdx == 1 && ~isnan(T.fRoffVT(ii))
            T.RoffVTVel(ii) = temp.mkrIXYZ_vel(T.fRoffVT(ii));
        elseif MkrIdx == 2 && ~isnan(T.fRoffVT(ii))
            T.RoffVTVel(ii) = temp.mkrTXYZ_vel(T.fRoffVT(ii));
        else
            T.RoffVTVel(ii) = NaN;
        end
       
        
        % REACH OFFSET DEFINED BY ZMIN THRESHOLDS

        T.fRoffIZMin(ii) = fwdReachEndZMin(temp.mkr5Z, T.fPGA(ii), ZLocalPromThreshold, ZMinThreshold);
        T.fRoffTZMin(ii) = fwdReachEndZMin(temp.mkr6Z, T.fPGA(ii), ZLocalPromThreshold, ZMinThreshold);        
        [T.fRoffZMin(ii), MkrIdx] = min([T.fRoffIZMin(ii),T.fRoffTZMin(ii)]);
        
        if MkrIdx == 1 && ~isnan(T.fRoffZMin(ii))
            T.RoffZMinVel(ii) = temp.mkrIXYZ_vel(T.fRoffZMin(ii));
        elseif MkrIdx == 2 && ~isnan(T.fRoffZMin(ii))
            T.RoffZMinVel(ii) = temp.mkrTXYZ_vel(T.fRoffZMin(ii));
        else
            T.RoffZMinVel(ii) = NaN;
        end
        
        % Reach offset defined as which comes first, VT or ZMin
        T.fRoffVTorZMin(ii) = min([T.fRoffI(ii),T.fRoffT(ii),T.fRoffIZMin(ii),T.fRoffTZMin(ii)]);
        
        fRon = T.fRon(ii);
        fPGA = T.fPGA(ii);
        fPGAZBound =  T.fPGAZBound(ii);
        fRoffVT = T.fRoffVT(ii); 
        fRoffZMin = T.fRoffZMin(ii);
        
       
        t = tiledlayout(2,1, 'TileSpacing', 'compact');
        fig = gcf;
        fig.Position = [965,420,955,580];
        t = CheckLandmarksPlot(t, temp, fRon, fPGA, fPGAZBound, fRoffVT, fRoffZMin); %#ok<NASGU>
        title(figName)
        savefig(fig,figOutPath,'compact');
        
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
            [T.PeakVelTh(ii),T.fPeakVelTh(ii)] = max(temp.mkrTXYZ_vel(T.fRonT(ii):T.fRoffVTorZMin(ii)));
            T.fPeakVelTh(ii) = T.fPeakVelTh(ii) + T.fRonT(ii);
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
            warning("Error finding average peak velocity metrics: trial should be examined.\n");
        end
        
        % Grip Aperture Velocity info
        try
            [T.PeakGAVelOpen(ii),T.fPeakGAVelOpen(ii)] = max( abs( temp.GAxyz_vel(fRon:fPGA) ) );
            T.fPeakGAVelOpen(ii) = T.fPeakGAVelOpen(ii) + fRon;
        catch
            warning("Error finding GA Open Velocity metrics, trial should be examined.\n");
        end
        
        try
            [T.PeakGAVelClose(ii),T.fPeakGAVelClose(ii)] = max( abs( temp.GAxyz_vel(fPGA:fRoff) )  );
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

