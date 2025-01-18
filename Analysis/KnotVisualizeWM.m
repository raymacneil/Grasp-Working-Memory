function values = KnotVisualizeWM(optkTFdata_cleaned)
    
    mkr6idx = size(optkTFdata_cleaned,2);
    mkr5idx = mkr6idx - 3;
    mkr4idx = mkr5idx - 3;
    
    % Find NaN values for markers 4-6
    AreNAN = isnan(optkTFdata_cleaned(:,[mkr4idx,mkr5idx,mkr6idx]));
    
    % Get knot interval indices, store as 'values' table
    BlockNum = optkTFdata_cleaned(1,1);
    TrialNum = optkTFdata_cleaned(1,2);
    values = missingIntervals(AreNAN,BlockNum,TrialNum);

    % Find knot intervals for plotting
    data = single(~AreNAN);
    data(data == 0) = NaN;
    missing = single(AreNAN);
    missing(missing == 0) = NaN;
    
    x = linspace(0,1,length(AreNAN));
    
    % Plot knot visualization
    hold on;
    for i = 1:3
        gscale = 0.1*BlockNum;
        stairs(x,data(:,i)*i,'Color',[gscale,gscale,gscale],'LineWidth',10);
        stairs(x,missing(:,i)*i,'r','LineWidth',10);
    end
    yticks([1,2,3]);
    yticklabels({'HND(4)', 'IDX(5)', 'TMB(6)'});
    ylim([0.9,3.2])
    set(gca,'TickLabelInterpreter', 'tex');
    pbaspect([6,1,1]);
    title('Block ' + string(BlockNum) + ' - Trial ' + string(TrialNum));
    %hold off

end


function tab = missingIntervals(missing,BlockNum,TrialNum)
    MarkerNames = {'Hand (4)','Index (5)','Thumb (6)'};

    % Initialize table columns
    Block = [];
    Trial = [];
    Marker = {};
    Knot = [];
    Knot_Start = [];
    Knot_End = [];
    Knot_Size = [];
    
    j = 1;

    % Pair start/stop indices for knot intervals and associate with
    %   marker number
    for ii = 1:3
        KnotCount = 1;
        % MKRnumber = ii + 3;
        MKRCol = find(abs(diff([0;missing(:,ii)])));
        if mod(length(MKRCol),2) ~= 0
            MKRCol = [MKRCol;size(missing,1)];
        end
        for i = 1:2:length(MKRCol)
            Block(j,1) = BlockNum;
            Trial(j,1) = TrialNum;
            Marker(j,1) = MarkerNames(ii);
            Knot(j,1) = KnotCount;
            Knot_Start(j,1) = MKRCol(i);
            Knot_End(j,1) = MKRCol(i+1)-1;
            Knot_Size(j,1) = MKRCol(i+1)-1 - MKRCol(i);
            KnotCount = KnotCount + 1;
            j = j + 1;
        end
    end

    if ~isempty(Marker)
        tab = table(Block,Trial,Marker,Knot,Knot_Start,Knot_End,Knot_Size);
    else
        tab = table;
    end

end



