function [fileName] = pipeline4WM(selectIDs, saveFigures, Mkrs, Dims, datadir, VToff, VDoff)
% Raymond MacNeil, Vision Lab, 2021-2024
% LAST UPDATED: Jan 29, 2025 - Ray MacNeil
% The primary use of pipeline4WM is pipeline4WM(1) for multiselect or pipeline(0) for bulk
% select. 

% INPUTS:
% selectIDs <BOOL> Whether to select IDs from GUI -- defaults to TRUE
% saveFigures <BOOL> Whether to save figures of reacg trajectory and
% landmarks -- defaults to FALSE
% marks <DBL> A vector reprenting any value(s) of 1-6. 
% Determines for which markers (1-6) time-series data will be
% imported. Markers 1-3: Reference; Marker 4: Index 1 
% Marker 5: Index 2; Marker 6: Thumb
% Dims <CHR> Any permutation (of any size) of 'xyz'. Specifies the
% dimensions associated with the markers for data import. 
% datadir <CHR>: One of either 'Digits' or 'Motor'
% VToff <INT>; % Velocity threshold for event offset(off)
% VDoff <INT>; % Duration that VToff must be met to define event offset (off)

% 

% OUTPUTS:
% tfsdat <CELL ARRAY> Contains time-series data of OptoTrak data
% tparams <STRUCT> Represents the trial summary data, e.g., trial order
% expinfo <CELL ARRAY> Summarizes some information stored by tparams, such as the
% number of trials, number of missing trials, number of trials per "block", etc. 
% Last Updated Jan 30, 2024

defaultDataDir = '~/Nextcloud/Grasp-Working-Memory/Data';

if nargin < 1
    selectIDs = true; saveFigures = false; Mkrs = 4:6; Dims = 'xyz'; datadir = defaultDataDir; VToff = 75; VDoff = 5;
elseif nargin < 2
    saveFigures = false; Mkrs = 4:6; Dims = 'xyz'; datadir = defaultDataDir; VToff = 75; VDoff = 5;
elseif nargin < 3
    Mkrs = 4:6; Dims = 'xyz'; datadir = defaultDataDir; VToff = 75; VDoff = 5;
elseif nargin < 4
    Dims = 'xyz'; datadir = defaultDataDir; VToff = 75; VDoff = 5;
elseif nargin < 5
    datadir = defaultDataDir; VToff = 75; VDoff = 5;
elseif nargin < 6
    VToff = 75; VDoff = 5;
elseif nargin < 7
    VDoff = 5;    
end


[tfsdat, tparams, expinfo] = batchimp4WM(Mkrs, Dims, selectIDs, datadir);
expinfo = sortrows(expinfo,{'exp','mode'},{'ascend','descend'});


expinfo.id = categorical(expinfo.id);
expinfo.exp = categorical(expinfo.exp);

Cutoff = 20; % lowpass
Order = 2;
SampRate = 200;
SecsPerSamp = 1/SampRate; 
ProgLabels = ["Natural Single","Natural Dual",...
              "Pantomime Single","Pantomime Dual"];
nDims = numel(Dims);


%%%%%%%%%%%%%%%%%%%%%%% GRASP-TYPE LEVEL LOOP %%%%%%%%%%%%%%%%%%%%%%%        
for ii = 1:size(tfsdat, 3) % loop through task type, dim 3 
    % ii = 1 means Natural Grasps Single, ii = 2 means Natural Grasps Dual
    % ii = 3 means Pantomime Grasps Single, ii = 4 means Pantomime Grasps Dual
    
    % Make sure page isn't empty (e.g only NG or PG participants selected)
    if ~isempty(tfsdat{1,1,ii})

        %%%%%%%%%%%%%%%%%%%%%%% SUBJECT LEVEL LOOP %%%%%%%%%%%%%%%%%%%%%%%
        for jj = 1:nnz(~cellfun('isempty', tfsdat(1,:,ii))) % Participant level loop

            % Get the starting index to index into and loop through
            % the expinfo table (i.e. represents trial variables)
            if ii == 2
                % this is because the expinfo table is grouped by
                % task type, THEN participant ID
                idx = jj + nnz(~cellfun('isempty', tfsdat(1,:,1))); % participants in tfsdat are organized columnwise
            elseif ii == 3
                idx = jj + 2 * nnz(~cellfun('isempty', tfsdat(1,:,2)));
            elseif ii == 4
                idx = jj + 2 * nnz(~cellfun('isempty', tfsdat(1,:,2))) + nnz(~cellfun('isempty', tfsdat(1,:,3)));
            else
                idx = jj;
            end


            % Account for varying trial numbers among participants
            endIdx = find(~cellfun('isempty',tfsdat(:,jj,ii)), 1, 'last');

            % Account for absence of trials among participants
            if endIdx == 1
                continue
            end

            % N.B. Marker 5 is the index; Marker 6 is the thumb
            % DECLARE INDICES FOR EACH MARKER AND MARKER DIMENSION
            % FOR THE TRIAL TIME-SERIES DATA
            HeaderNames = expinfo.headNames{idx};
            MkrIndices = find(~cellfun('isempty', regexp(HeaderNames,...
                'Mkr\d(?=_[xyz])', 'match', 'noemptymatch')));


            % Index into TRIALS to EXTRACT KEY PARAMETERS from
            % the expinfo table (i.e. the TRIAL PARAMETERS: induce angle,
            % bar angle, etc.)

            %%%%%%%%%%%%%%%%%%%%%%% TRIAL LEVEL LOOP %%%%%%%%%%%%%%%%%%%%%%%%%
            for kk = 2:endIdx % starting index = 2 because the first row contans the ID label

                fprintf('Processing %s Grasps for %s: Trial %d of %d \n',...
                    ProgLabels(ii), tfsdat{1,jj,ii}, kk-1, endIdx-1);
                Trial = tfsdat{kk,jj,ii};
                NumSamples = size(Trial, 1);
                Time = transpose(0:SecsPerSamp:(NumSamples - 1)*SecsPerSamp);

                % Preallocate a matrix for interpolation tracking and kinematic
                % parameters, e.g., displacement, velocity, grip aperture, grip angle
                Metrics = [false(NumSamples,3), NaN(NumSamples,7)];
                MkrArray = Trial(:,MkrIndices);

                MkrValidFrames = GetValidFrames(MkrArray, nDims);
                [InterpData, TrackInterpFrames] = InterpMkrFramesPP(MkrArray, nDims, MkrValidFrames, Time);
                FiltMkrArray = OptkLowPassDigital(InterpData, SampRate, Cutoff, Order, MkrValidFrames, nDims);
                Trial(:,MkrIndices) = FiltMkrArray;
                Metrics(:,1:3) = TrackInterpFrames;

%                 

                % This just copies the same scaler value for each frame (i.e. sample)
                BarAngle = repelem(expinfo.barAngles{idx}(kk-1), NumSamples); % Samples = Frames, synonyms
                Metrics(:,4) = BarAngle;
                BarLength = repelem(expinfo.barLengths{idx}(kk-1), NumSamples); % Samples = Frames, synonyms
                Metrics(:,5) = BarLength;

                % Now we just put these parameters into our 'Metrics' matrix,
                % which we will eventually concatenate with the trial time
                % series data stored in each cell of the tfsdat matrix

                % Loop through TRIAL SAMPLES to define key metrics
                idxMkr4 = find(contains(HeaderNames, {'Mkr4_x', 'Mkr4_y', 'Mkr4_z'}));
                idxMkr5 = find(contains(HeaderNames, {'Mkr5_x', 'Mkr5_y', 'Mkr5_z'}));
                idxMkr6 = find(contains(HeaderNames, {'Mkr6_x', 'Mkr6_y', 'Mkr6_z'}));
                % idxKinMkrs = [idxMkr5, idxMkr6];

                % WE NEED TO DETERMINE THE START POINT WHEN BOTH INDEX AND
                % THUMB MARKER DATA ARE AVAILABLE; Unfortunately, many trials
                % were missing data at the beginning of the reach, especially
                % for early participants; there is a subtelty in how the start
                % position influences marker capture

                % Finding start/end point for combined IDX/THB is useful
                % for metrics that require both (GripAper/Angle). However, for individual
                % velocities this is unnecessary so I've updated the code
                % accordingly - Edwin

                IDXMkrStart = find(sum(~isnan(Trial(:,idxMkr5)),2) == 3,...
                    1, 'first');
                THBMkrStart = find(sum(~isnan(Trial(:,idxMkr6)),2) == 3,...
                    1, 'first');
                HNDMkrStart = find(sum(~isnan(Trial(:,idxMkr4)),2) == 3,...
                    1, 'first');
                IDXMkrEnd = find(sum(~isnan(Trial(:,idxMkr5)),2) == 3,...
                    1, 'last');
                THBMkrEnd = find(sum(~isnan(Trial(:,idxMkr6)),2) == 3,...
                    1, 'last');
                HNDMkrEnd = find(sum(~isnan(Trial(:,idxMkr4)),2) == 3,...
                    1, 'last');
                BothMkrsStart = find(sum(~isnan(Trial(:,[idxMkr5,idxMkr6])),2) == 6,...
                    1, 'first');
                BothMkrsEnd = find(sum(~isnan(Trial(:,[idxMkr5,idxMkr6])),2) == 6,...
                    1, 'last');

                % Pull useful marker position data
                posDataTHBIDX = Trial(BothMkrsStart:BothMkrsEnd,MkrIndices(4):MkrIndices(end));
                posDataHND = Trial(HNDMkrStart:HNDMkrEnd,MkrIndices(1):MkrIndices(3));
                posDataIDX = Trial(IDXMkrStart:IDXMkrEnd,MkrIndices(4):MkrIndices(6));
                posDataTHB = Trial(THBMkrStart:THBMkrEnd,MkrIndices(7):MkrIndices(9));
%                 GripAper = sqrt(sum((posDataTHBIDX(:,1:3) - posDataTHBIDX(:,4:6)).^2,2));

                % Find grasp aperture metrics: GAxyz and GAvel
                Metrics(BothMkrsStart:BothMkrsEnd,6) = GA(posDataTHBIDX);
                Metrics(BothMkrsStart:BothMkrsEnd,7) = [NaN; diff(Metrics(BothMkrsStart:BothMkrsEnd,6))] * SampRate; 

                % Find velocity metrics: mkrHXYZ_vel, mkrIXYZ_vel, mkr_TXYZ_vel
                IDX_vXYZ = MarkerSpeedCols(posDataIDX,SampRate);
                THB_vXYZ = MarkerSpeedCols(posDataTHB,SampRate);
                HND_vXYZ = MarkerSpeedCols(posDataHND,SampRate);
                Metrics(HNDMkrStart+1:HNDMkrEnd,8) = HND_vXYZ;
                Metrics(IDXMkrStart+1:IDXMkrEnd,9) = IDX_vXYZ;
                Metrics(THBMkrStart+1:THBMkrEnd,10) = THB_vXYZ;
                
                Trial = [Trial(:,1:MkrIndices(1) - 1), Time, Trial(:,MkrIndices)];
                Trial = [Trial, Metrics]; %#ok<AGROW>

                varHeadNames = {'block', 'trial','TrialCount','RepeatFlag', 'srate', 'time', 'mkr4X',...
                    'mkr4Y', 'mkr4Z', 'mkr5X', 'mkr5Y', 'mkr5Z', 'mkr6X', 'mkr6Y',...
                    'mkr6Z', 'mkr4_intrp', 'mkr5_intrp', 'mkr6_intrp' 'barAng','barLen','GAxyz', 'GAxyz_vel',...
                    'mkrHXYZ_vel', 'mkrIXYZ_vel', 'mkrTXYZ_vel'};
                Trial = cell2table(num2cell(Trial),'VariableNames', varHeadNames);
                tfsdat{kk,jj,ii} = Trial;

            end


        end
    end

end

% Velocity (mm/s) and duration (# frames) thresholds to be used for defining events and calculating metrics
VTon = 50; % Velocity threshold for event onset (on)
VDon = 60; % Duration that VTon must be met to define event onset (on)
% VToff = 75; % Velocity threshold for event offset(off)
% VDoff = 10; % Duration that VToff must be met to define event offset (off)

% Find landmarks and metrics
AllMetrics = GetMetricsWM(tfsdat,tparams,SampRate,VTon,VToff,VDon,VDoff);

% SAVE THE FILE
dt = char(datetime('now', 'Format','yyyy-MMM-dd-HH:mm'));
dt = strrep(dt, ':', '');
fileName = strcat('GraspWM-Data-', dt, '.mat');
OutPath = '~/Nextcloud/Grasp-Working-Memory/Analysis/Output/';
filePath = strcat(OutPath, fileName);
save(filePath ,'AllMetrics', 'tparams', 'expinfo', 'tfsdat');
WriteAllMetrics(AllMetrics, fullfile(OutPath, ['grasp-wm-metrics-', dt, '.csv']));   

if saveFigures
    IDs = tfsdat(1,:,:);
    tfsdatIDs = unique(IDs(~cellfun('isempty',IDs)));
    SavePlotReachWM(tfsdat,tfsdatIDs);
end
    
end


