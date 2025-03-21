function SimpleFigureViewer()
    mainFig = figure('Name', 'Figure Viewer', ...
                     'WindowKeyPressFcn', @keyPress);
    
    [fileNames, pathName] = uigetfile({'*.fig'}, 'Select Figures', 'MultiSelect', 'on');
    if isequal(fileNames, 0)
        close(mainFig);
        return;
    end
    
    if ~iscell(fileNames)
        fileNames = {fileNames};
    end
    
    fileNames = fileNames';
    cstrsplit = @(x) strsplit(x, '-');
    fileNamesSplit = cellfun(cstrsplit, fileNames, 'UniformOutput', false);
    fileNamesSplit = vertcat(fileNamesSplit{:});
    [~, sortIndex] = sortrows(fileNamesSplit, [3,4,5,7],...
        [{'descend'},repelem({'ascend'},1,3)]);
    fileNames = fileNames(sortIndex);

    
    data.files = fullfile(pathName, fileNames);
    data.names = fileNames;
    data.idx = 1;
    setappdata(mainFig, 'data', data);
    
    showFigure(mainFig);
    
    function keyPress(src, evt)
        data = getappdata(src, 'data');
        switch evt.Key
            case 'rightarrow'
                if data.idx < length(data.files)
                    data.idx = data.idx + 1;
                    setappdata(src, 'data', data);
                    showFigure(src);
                end
            case 'leftarrow'
                if data.idx > 1
                    data.idx = data.idx - 1;
                    setappdata(src, 'data', data);
                    showFigure(src);
                end
            case 'escape'
                close(src);
        end
    end
    
    function showFigure(fig)
        data = getappdata(fig, 'data');
        clf(fig);
        
        temp = openfig(data.files{data.idx}, 'invisible');
        axesObjs = findall(temp, 'type', 'axes');
        copyobj(axesObjs, fig);
        close(temp);
        
        % Update figure name to show current file
        fig.Name = sprintf('Figure %d/%d: %s', ...
            data.idx, length(data.files), data.names{data.idx});
    end
end