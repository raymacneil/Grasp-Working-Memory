function CreationDate = getFileDate(filename)
    %DOS STRING FOR "FILE CREATION" DATE
    dosStr = char(strcat({'dir /s /tc '}, {'"'}, filename,{'"'}));
    
    % Reading DOS results
    [~,results] = dos(dosStr);
    c = textscan(results,'%s');
    % Extract file size (fileSize) and date created (dateCreated)
    i = 1;
    for k = 1:length(c{1})
        if (isequal(c{1}{k},'PM')||isequal(c{1}{k},'AM'))&&(~isequal(c{1}{k+1},'<DIR>'))
            dateCreated(i,1) = datetime(cell2mat(strcat(c{1}{k-2},{' '},c{1}{k-1},{' '},c{1}{k})),'InputFormat','uuuu-MM-ddhh:mm aa');
            n = length(str2num(c{1}{k+1}));
            fileSize(i,1) = sum(fliplr(str2num(c{1}{k+1})).*(10.^(3.*((0:n-1)))));
            i = i + 1;
        end
    end
    % Sort according to date of creation
    [dateCreated,id] = sort(dateCreated);

    CreationDate = dateCreated(1);
end