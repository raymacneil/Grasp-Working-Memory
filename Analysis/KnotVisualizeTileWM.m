% KnotVisualizeTileWM is intended to be used on data in tsfdat immediately after 
% batchimp3WM has been run (after trailing NaNs are removed at end of
% batchimp but before missing data is interpolated). It is intended to show
% at a glance the data quality of many trials at once.
% 
% INPUT: 'data' here would be a column of cells of optotrak data from tfsdat
% e.g. data = tfsdat(2:end, 1, 1)
%   - this would pull all Natural Grasp Single trials from participant 1
% 
% NOTE: tiledlayout is set to 'flow' to accomodate arbitrary number of
% trials. Plotting more than 40 trials can lead to legibility issues

function KnotVisualizeTileWM(data)
    t = tiledlayout('flow');
    %t.TileIndexing = 'columnmajor';
    A = table;
    eIdx = find(~cellfun('isempty',data), 1, 'last' );
    for i=1:eIdx
        nexttile
        A = [A;KnotVisualizeWM(data{i,1})];
    end
    t.TileSpacing = 'none';
    % [row,col] = tilerowcol(t.Children);
    % yticklabels(t.Children(col>1),"");
    xticklabels(t.Children(:),"")
end