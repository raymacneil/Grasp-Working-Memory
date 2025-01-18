function BarImg = readBarImg(imgFname, mirrorDisp)
    [BarImg, ~, alpha] = imread(imgFname);
%     incorrect_alpha_value = mode(alpha(:,1));
%     H = find(alpha == incorrect_alpha_value);
%     alpha(H) = 0; %#ok<FNDSB>
    BarImg(:, :, 4) = alpha;
        if mirrorDisp
            BarImg = imrotate(flip(BarImg ,1), -90);
        end
end