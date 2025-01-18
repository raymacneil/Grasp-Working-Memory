


function LDJ = LogDimensionlessJerk(movement, fs)

    % """
    % Copyright (c) 2015, Sivakumar Balasubramanian <siva82kb@gmail.com>
    % 
    % Calculates the smoothness metric for the given speed profile using the
    % dimensionless jerk metric.
    % 
    % Parameters
    % ----------
    % movement : np.array
    %            The array containing the movement speed profile.
    % fs       : float
    %            The sampling frequency of the data.
    % 
    % Returns
    % -------
    % dl       : float
    %            The dimensionless jerk estimate of the given movement's
    %            smoothness.
    % 
    % Notes
    % -----
    % 
    % 
    % Examples
    % --------
    % >>> t = np.arange(-1, 1, 0.01)
    % >>> move = np.exp(-5*pow(t, 2))
    % >>> ldl = log_dimensionless_jerk(move, fs=100.)
    % >>> '%.5f' % ldl
    % '-5.81636'
    % 
    % """
    try
        
        % calculate the scale factor and jerk.
        movement_peak = max(abs(movement));
        dt = 1 ./ fs;
        movement_dur = length(movement) * dt;
        jerk = diff(movement, 2) ./ (dt.^2);
        scale = movement_dur.^3 ./ movement_peak.^2;
        
        % estimate dj
        DJ = scale * sum(jerk.^2) * dt;
        
        % take log of dj
        LDJ =  -log(abs(DJ));
        
        if isequal(LDJ,inf) || isempty(LDJ)
            LDJ = NaN;
        end
    
    catch
        LDJ = NaN;
        warning("Error finding LDJ: trial should be examined.\n")
    end
end

