function AllMetrics = GetMetricsWM(tfsdat, tparams, SampleRate, VTon, VToff, VDon, VDoff)
% Update 2024-10-12, Raymond MacNeil
% Added an input for sample rate to GetMetrics and TrialMetrics so that the
% displacements of aperture adjustment can be scaled by time to get
% velocity in mm/s. 


% INPUTS:
% tfsdat <CELL ARRAY> Contains time-series data of OptoTrak data
% tparams <STRUCT> Represents the trial summary data, e.g., trial order
% 
% OPTIONAL INPUTS:
% VTon <DBL> Velocity onset threshold for start of reach (mm/s)
% VToff <DBL> Velocity offset threshold for end of reach (mm/s)
% VDon <DBL> Minimum velocity duration needed to count as reach onset (frames)
% VDoff <DBL> Minimum velocity duration needed to count as reach offset (frames)
% 
% OUTPUTS:
% AllMetrics <CELL ARRAY> Contains combined tparams data with calculated
% landmarks/metrics (using TrialMetricsWM function)

VTonDefault = 50;
VToffDefault = 75;
VDonDefault = 60;
VDoffDefault = 10;

% Assign default parameters if not given
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

graspNames = {'NaturalGrasp','NaturalGrasp',...
              'Pantomime','Pantomime'};
modeNames = {'Single','Dual',...
              'Single','Dual'};
fprintf("Getting metrics...\n");
AllMetrics = cell(2,size(tfsdat,2),length(graspNames));

for typ = 1:size(tfsdat,3)
    if ~isempty(tfsdat{1,1,typ})
        for jj = 1:nnz(~cellfun('isempty', tfsdat(1,:,typ)))

            fprintf("Analyzing %s data for participant %d | ID: %s:\n",...
                [graspNames{typ} modeNames{typ}], jj, string({tfsdat(1,jj,typ)}));
            ID = tfsdat(1,jj,typ);
            AllMetrics(1,jj,typ) = ID;

            tparamSorted = sortrows(tparams.(ID{1}).([graspNames{typ} modeNames{typ}]),{'BlockNum','TrialNum'},'ascend');
            graspCol = repelem(categorical(graspNames(typ)),size(tparamSorted,1))';
            modeCol = repelem(categorical(modeNames(typ)),size(tparamSorted,1))';
            tparamSorted = addvars(tparamSorted,graspCol,modeCol,'NewVariableNames',{'Grasp','Mode'},'After','participant');
%             metricsTemp = removevars(TrialMetricsWM(tfsdat(:,jj,typ),VTon,VToff,VDon,VDoff),...
%                 {'id','Block','Trial_id','barAngle','barLength'});
            %%%%% Cal metrics function %%%%%%
            metricsTemp = TrialMetricsWM(tfsdat(:,jj,typ),SampleRate, VTon, VToff, VDon, VDoff);
            
            %%%%% Remove duplicate variable
            metricsTemp = removevars(metricsTemp,...
                {'id'});

            % Take care of instances where practice rounds were skipped and
            % therefore no data exists
            if size(tparamSorted,1) ~= size(metricsTemp,1) &&...
                    any(contains(tparamSorted.Properties.VariableNames,'PracticeSkipped'))

                tparamSorted = tparamSorted(tparamSorted.PracticeSkipped ~= 1,:);
                tparamSorted.TrialCount = (1:size(tparamSorted,1))';

            end
            % Early trials had fewer columns in results_out.csv file. Add empty
            % columns for later combination
            if ~any(contains(tparamSorted.Properties.VariableNames, 'PracticeSkipped'))

                PracticeSkipped = nan(size(tparamSorted,1),1);
                tparamSorted = addvars(tparamSorted, PracticeSkipped,...
                    'NewVariableNames', 'PracticeSkipped', 'After', 'PracticeBlock');

            end
            if ~any(contains(tparamSorted.Properties.VariableNames, 'wmNBack'))

                wmNBack = nan(size(tparamSorted,1),1);
                tparamSorted = addvars(tparamSorted, wmNBack,...
                    'NewVariableNames', 'wmNBack', 'After', 'wmCorrect');

            end
            % Location of and name of 'TrialRepeat' changed after early trials
            wmTrialRepeat_Idx = find(strcmp(tparamSorted.Properties.VariableNames,'wmTrialRepeat'),1);
            if ~isempty(wmTrialRepeat_Idx)
                tparamSorted.Properties.VariableNames(wmTrialRepeat_Idx) = {'TrialRepeat'};
            end
            tparamSorted = movevars(tparamSorted, 'TrialRepeat', 'After', 'BadTrial');

            % AllMetrics(2,j,ii) = {sortrows([tparamSorted,metricsTemp],'TrialCount','ascend')};
            AllMetrics(2,jj,typ) = {[tparamSorted,metricsTemp]};
        end
    end
end


end









