% Uses PlotReachWM function to plot and save 3D Index/Thumb trajectories 
% and grip aperture for all trials for selected participants. After
% running, user will be asked to select multiple participant data folders
% which should be located in the Data directory. 
% All figures will be saved in a folder named 'participantID_plots' inside
% the selected participant data folder. Function may run fairly slow as
% hundreds of figures will be saved if multiple participants are selected.

function SavePlotReachWM(tfsdat,tfsdatIDs)
    
    while true
        fprintf("Available participants for visualization:\n")
        disp(tfsdatIDs);
        IDdataFolders = uigetdir2;

        if ~isempty(IDdataFolders)
            selectedIDs = cellfun(@(x) x(end-6:end), IDdataFolders,...
            'UniformOutput', false);
        else
            fprintf("No data drive selected, exiting...\n")
            return
        end
        
        if or(~all(ismember(selectedIDs,tfsdatIDs)),...
               length(selectedIDs) > length(tfsdatIDs)) 
            fprintf("Missing data for at least one selected participant.\n")
        else
            break
        end
    end
    
    graspNames = {'NaturalGraspSingle','NaturalGraspDual','PantomimeSingle','PantomimeDual'};

    for id = 1:numel(selectedIDs)
        ID = selectedIDs{id};
        matches = cellfun(@(x) strcmp(x, ID), tfsdat(1,:,:));
        if ~isempty(find(matches,1))
            [~, col, page] = ind2sub(size(matches), find(matches));
            figDir = string(strcat(IDdataFolders{id},'/',ID,'_plots'));
            if ~isfolder(figDir)
                mkdir(figDir)
            end
            for ii = 1:size(col,1)
                participantData = tfsdat(2:end,col(ii),page(ii));
                participantData = participantData(~cellfun('isempty',participantData));
                fprintf("Plotting %s data for participant %s\n",graspNames{page(ii)},ID);
                for trial = 1:size(participantData,1)
                    f = PlotReachWM(participantData{trial,1},5,ID,graspNames{page(ii)},0);
                    bnStr = strcat('_bn', string(participantData{trial,1}.block(1)));
                    tnStr = strcat('_tn', string(participantData{trial,1}.trial(1)));
                    tStr = strcat('_t',string(trial));
                    filename = strcat(figDir, '/', ID, '_', graspNames(page(ii)), bnStr, tnStr,tStr);
                    saveas(f, filename, 'png');
                end
            end
        else
            fprintf("Failed to find participant %s, skipping... \n",selectedIDs{id});
            continue
        end
    end

end