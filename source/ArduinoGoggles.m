classdef ArduinoGoggles < handle
    %ArduinoGoggles Controls occlusion goggles using state machine
    %   Goggles are configured using an OR gate for L/Both & R/Both, in
    %   order to allow for simultaneous opening and closing.
    %   This was necessary since writing to an Arduino pins sequentially
    %   causes a visible delay.
    
    properties (SetAccess = private)
        ard
        
        % Store logic states to ensure Arduino on/off msgs don't clash
        channels_on = [false;false;false]; % [Left,Right,Both]
        
        % Arduino Digital ports: must be chars with the name "Dxx", 
        % ex. 'D53'
        % Red wire = Right, Yellow wire = Left, White = Both
        left
        right
        both
        
        % Constants for open (0V) and close (5v) signal logic
        OPEN = 0;
        CLOSE = 1;
    end
    
    methods
        function AG = ArduinoGoggles(ard_com_port, ard_model, L, R, B)
            %ArduinoGoggles Construct an instance of this class
            %   Detailed explanation goes here
            try
                AG.ard = arduino(ard_com_port, ard_model);
            catch ArdErr
                rethrow(ArdErr)
            end
            
            if nargin < 3
                L = 'D50';
                R = 'D51';
                B = 'D53';
            end
            
            % Test for correct L, R, B channel strings
            swd_wrapper = @(x) startsWith(x, 'D');
            if ~all(cellfun(@ischar,{L,R,B}))
                error(['ERROR: L,R,B channels are not char vectors!',...
                       ' Please see ArduinoGoggles class description.']);
            elseif ~all(cellfun(swd_wrapper,{L,R,B}))
                error(['ERROR: L,R,B chans not in pin format ''Dxx''!',...
                       ' Please see ArduinoGoggles class description.']);            
            else
                AG.left = L;
                AG.right = R;
                AG.both = B;
            end
            
            AG.openBothEyes()
        end
        
        
        function is_open = leftEyeIsOpen(AG)
            %isLeftEyeOpen Is left eye open? (L & Both chs OFF)
            is_open = ~AG.channels_on(1) && ~AG.channels_on(3);
        end
        
        
        function is_open = rightEyeIsOpen(AG)
            %isLeftEyeOpen Is right eye open? (R & Both chs OFF)
            is_open = ~AG.channels_on(2) && ~AG.channels_on(3);
        end
        
        
        function is_open = bothEyesAreOpen(AG)
            %isLeftEyeOpen Are both eyes open? (All chs OFF)
            is_open = ~any(AG.channels_on);
        end
        
        function is_closed = bothEyesAreClosed(AG)
            %isLeftEyeOpen Are both eyes open? (All chs OFF)
            is_closed = (AG.channels_on(1) && AG.channels_on(2)) ...
                        || AG.channels_on(3);
        end
        
        
        function openRightEye(AG)
            % L off, B on  -> L on,  B off, R off
            % L off, B off -> L off, B off, R off
            % L on,  B on  -> L on,  B off, R off
            % L on,  B off -> L on,  B off, R off
            
            a = AG.ard;
            
            if AG.channels_on(1)
                if AG.channels_on(3)
                    % First open Right eye
                    writeDigitalPin(a, AG.right, AG.OPEN);
                    AG.channels_on(2) = false;
                    % Then open Both eyes
                    writeDigitalPin(a, AG.both, AG.OPEN);
                    AG.channels_on(3) = false;
                else
                    % No conflicts, open Right eye
                    writeDigitalPin(a, AG.right, AG.OPEN);
                    AG.channels_on(2) = false;
                end
            else
                if AG.channels_on(3)
                    % Close Left eye
                    writeDigitalPin(a, AG.left, AG.CLOSE);
                    AG.channels_on(1) = true;
                    % Then open Right eye
                    writeDigitalPin(a, AG.right, AG.OPEN);
                    AG.channels_on(2) = false;
                    % Then open Both eyes
                    writeDigitalPin(a, AG.both, AG.OPEN);
                    AG.channels_on(3) = false;
                else
                    % No conflicts, open Right eye
                    writeDigitalPin(a, AG.right, AG.OPEN);
                    AG.channels_on(2) = false;
                end
            end
        end
        
        
        function closeRightEye(AG)
            % L off, B on  -> L off, B on,  R on
            % L off, B off -> L off, B off, R on
            % L on,  B on  -> L on,  B on,  R on
            % L on,  B off -> L on,  B off, R on

            % No conflicts, close Right eye
            if ~AG.channels_on(2)
                writeDigitalPin(AG.ard, AG.right, AG.CLOSE);
                AG.channels_on(2) = true;
            end
        end
        
        
        function openLeftEye(AG)
            % R off, B on  -> R on,  B off, L off
            % R off, B off -> R off, B off, L off
            % R on,  B on  -> R on,  B off, L off
            % R on,  B off -> R on,  B off, L off

            a = AG.ard;
            
            if AG.channels_on(2)
                if AG.channels_on(3)
                    % First open Left eye
                    writeDigitalPin(a,AG.left,AG.OPEN);
                    AG.channels_on(1) = false;
                    % Then open Both eyes
                    writeDigitalPin(a,AG.both,AG.OPEN);
                    AG.channels_on(3) = false;
                else
                    % No conflicts, open Left eye
                    writeDigitalPin(a,AG.left,AG.OPEN);
                    AG.channels_on(1) = false;
                end
            else
                if AG.channels_on(3)
                    % Close Right eye
                    writeDigitalPin(a,AG.right,AG.CLOSE);
                    AG.channels_on(2) = true;
                    % Then open Left eye
                    writeDigitalPin(a,AG.left,AG.OPEN);
                    AG.channels_on(1) = false;
                    % Then open Both eyes
                    writeDigitalPin(a,AG.both,AG.OPEN);
                    AG.channels_on(3) = false;
                else
                    % No conflicts, open Left eye
                    writeDigitalPin(a,AG.left,AG.OPEN);
                    AG.channels_on(1) = false;
                end
            end
        end

        function closeLeftEye(AG)
            % R off, B on  -> R off, B on,  L on
            % R off, B off -> R off, B off, L on
            % R on,  B on  -> R on,  B on,  L on
            % R on,  B off -> R on,  B off, L on

            % No conflicts, close Right eye
            if ~AG.channels_on(1)
                writeDigitalPin(AG.ard, AG.left, AG.CLOSE);
                AG.channels_on(1) = true;
            end
        end

        
        function openBothEyes(AG)
            % L off, R on  -> R off, B off, L off
            % L off, R off -> R off, B off, L off
            % L on,  R on  -> R off, B off, L off
            % L on,  R off -> R off, B off, L off

            a = AG.ard;
            
            if AG.channels_on(3)
                % First open Left eye
                writeDigitalPin(a, AG.left, AG.OPEN);
                AG.channels_on(1) = false;
                % Then open Right eye
                writeDigitalPin(a, AG.right, AG.OPEN);
                AG.channels_on(2) = false;
                % Then open Both eyes
                writeDigitalPin(a, AG.both, AG.OPEN);
                AG.channels_on(3) = false;
            else
                if AG.channels_on(1) && AG.channels_on(2)
                    % Close Both eyes
                    writeDigitalPin(a, AG.both, AG.CLOSE);
                    AG.channels_on(3) = true;
                    % Open Left eye
                    writeDigitalPin(a, AG.left, AG.OPEN);
                    AG.channels_on(1) = false;
                    % Then open Right eye
                    writeDigitalPin(a, AG.right, AG.OPEN);
                    AG.channels_on(2) = false;
                    % Then open Both eyes
                    writeDigitalPin(a, AG.both, AG.OPEN);
                    AG.channels_on(3) = false;
                else
                    if AG.channels_on(1)
                        % Open Left eye
                        writeDigitalPin(a, AG.left, AG.OPEN);
                        AG.channels_on(1) = false;
                    end
                    if AG.channels_on(2)
                        % Open Right eye
                        writeDigitalPin(a, AG.right, AG.OPEN);
                        AG.channels_on(2) = false;
                    end
                end
            end
        end

        function closeBothEyes(AG)
            % L off, R on  -> L off, R on,  B on
            % L off, R off -> L off, R off, B on
            % L on,  R on  -> L on,  R on,  B on
            % L on,  R off -> L on,  R off, B on

            % No conflicts, close Both eyes
            if ~AG.channels_on(3)
                writeDigitalPin(AG.ard, AG.both, AG.CLOSE);
                AG.channels_on(3) = true;
            end
        end
    end
end

