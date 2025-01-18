function out = rotateFillRect(window, xPos, yPos    
    Screen('glPushMatrix', window)
    Screen('glTranslate', window, xPos, yPos)
    Screen('glRotate', window, angle, 0, 0);
    Screen('glTranslate', window, -xPos, yPos)
        Screen('FillRect', window, [0 0 0],...
            CenterRectOnPoint(baseRect, xPos, yPos));
        Screen('glPopMatrix', window)