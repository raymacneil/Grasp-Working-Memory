
function f = PlotReachWM(trial, type, ID, grasp, visible)
    % trial must be a table with xyz mkr data, GAxyz, Idx/Thb velocity, etc
    % Type == 2 -> 2D plot of GA
    % Type == 3 -> 3D plot of Index XYZ
    % Type == 4 -> 2D plot of GA Velocity
    % Type == 5 -> Tiled plot of GA & 3D Index/Thumb XYZ (* primary plot *) 
    % Type == 6 -> Tiled plot of Index & Thumb Velocity
    % Type == 7 -> Tiled plot of GA, 3D Index XYZ, Index Z, Index & Thumb Velocity
    
    if nargin < 2
        str = "Block " + string(trial.block(1)) + " Trial " + string(trial.trial(1));
        type = 5;visible = 1;
    elseif nargin < 3
        str = "Block " + string(trial.block(1)) + " Trial " + string(trial.trial(1));
        visible = 1;
    elseif nargin < 4
        str = "ID: " + ID + " | Block " + string(trial.block(1)) + " Trial " + string(trial.trial(1));
        visible = 1;
    else
        str = "ID: " + ID + " | Block " + string(trial.block(1)) + " Trial " + string(trial.trial(1)) + " | " + grasp;
    end

    if visible
        f = figure;
    else
        f = figure('Visible','off');
    end
    hold on;

    Ron = fwdReachStart(trial);
    Roff = fwdReachEndVelocityThreshold(trial);
    PGAFrame = PeakGA2(trial);
    if isnan(Ron) || isnan(Roff)
        fprintf("Error finding reach interval, plotting Grip Aperture.\n");
        type = 1;
    end
    
    x = 1:length(trial.GAxyz);

    if type == 1
        PGAPeaks = find(islocalmax(trial.GAxyz,'MinSeparation',100));
        PGAPeaksValid = PGAPeaks(PGAPeaks > Ron);
        PGAFrame = PGAPeaksValid(1);
        plot(trial.GAxyz);
        xline(PGAFrame);
        xlabel("Sample 20Hz");
        ylabel("Grip Aperture");
        title("Grip Aperture | " + str);
    elseif type == 2
        plot(x,trial.GAxyz);
        plot(x(Ron:Roff),trial.GAxyz(Ron:Roff));
        xline(PGAFrame);
        xlabel("Sample 20Hz");
        ylabel("GAxyz");
        title("Grip Aperture | " + str);
    elseif type == 3
        plot3(trial.mkr5X,trial.mkr5Y,trial.mkr5Z);
        plot3(trial.mkr5X(RonI:RoffI),trial.mkr5Y(RonI:RoffI),trial.mkr5Z(RonI:RoffI));
        title("Index 3D trajectory | " + str);
        view([136,18]);
    elseif type == 4
        GAVel = [nan; diff(trial.GAxyz)];
        plot(x, GAVel);
        plot(x(Ron:Roff), GAVel(Ron:Roff));
        xline(PGAFrame);
        title("Grip Aperture Velocity | " + str);
        xlabel("Frame (200 Hz)");
        ylabel("GAVel");
    elseif type == 5
        f.Position = [350,300,800,400];
        t = tiledlayout(2,4);
        title(t,str);

        % Plot 3D trajectory of IDX/THMB
        nexttile([2,2]);
        hold on;
        
        % Plot full IDX trajectory in blue
        plot3(trial.mkr5X,trial.mkr5Y,trial.mkr5Z,'Color',"#0072BD",'DisplayName', 'Index');
        % Plot reach interval in orange
        plot3(trial.mkr5X(Ron:Roff),trial.mkr5Y(Ron:Roff),trial.mkr5Z(Ron:Roff),'Color',"#D95319",'DisplayName', 'Reach Interval');
        % Plot moment of PGA with red *
        plot3(trial.mkr5X(PGAFrame),trial.mkr5Y(PGAFrame),trial.mkr5Z(PGAFrame),'*r','DisplayName', 'PGA');
        % Plot missing data points in magenta
        mkr5_missing = trial.mkr5_intrp;
        mkr5_missing(trial.mkr5_intrp == 0) = NaN;
        plot3(trial.mkr5X.*mkr5_missing,trial.mkr5Y.*mkr5_missing,trial.mkr5Z.*mkr5_missing,'Color',"#FF00FF",'LineWidth',1,'DisplayName', 'Interpolated');
        
        % Plot full THMB trajectory in blue
        plot3(trial.mkr6X,trial.mkr6Y,trial.mkr6Z,'Color',"#4DBEEE",'DisplayName', 'Thumb');
        % Plot reach interval in orange
        plot3(trial.mkr6X(Ron:Roff),trial.mkr6Y(Ron:Roff),trial.mkr6Z(Ron:Roff),'Color',"#D95319", 'HandleVisibility','off');
        % Plot moment of PGA with red *
        plot3(trial.mkr6X(PGAFrame),trial.mkr6Y(PGAFrame),trial.mkr6Z(PGAFrame),'*r', 'HandleVisibility','off');
        % Plot missing data points in magenta
        mkr6_missing = trial.mkr6_intrp;
        mkr6_missing(trial.mkr6_intrp == 0) = NaN;
        plot3(trial.mkr6X.*mkr6_missing,trial.mkr6Y.*mkr6_missing,trial.mkr6Z.*mkr6_missing,'Color',"#FF00FF",'LineWidth',1, 'HandleVisibility','off');

        title("IDX/THMB trajectory");
        xlabel("X");
        ylabel("Y");
        zlabel("Z");
        legend();
        view([136,18]);
        
        nexttile([2,2]);
        hold on;
        plot(x,trial.GAxyz);
        plot(x(Ron:Roff),trial.GAxyz(Ron:Roff));
        any_missing = single(or(trial.mkr5_intrp, trial.mkr4_intrp));
        any_missing(any_missing == 0) = NaN;
        plot(x'.*any_missing,trial.GAxyz.*any_missing,'Color',"#FF00FF",'LineWidth',1);
        xline(PGAFrame);
        xlabel("Frame (200 Hz)");
        ylabel("Grip Aperture");
        xlim([0,length(trial.GAxyz)]);
        title("GA w/ Reach Interval/PGA");

        % nexttile([1,2]);
        % hold on;
        % plot(x,trial.mkr5Z);
        % plot(x(Ron:Roff),trial.mkr5Z(Ron:Roff));
        % xline(PGAFrame);
        % title("Index, Z component");
        % xlabel("Sample 20Hz");
        % ylabel("Z coordinate");
        % xlim([0,length(trial.GAxyz)]);
    elseif type == 6
        t = tiledlayout('flow');
        title(t,str);
        nexttile;
        hold on;
        plot(x,trial.mkrIXYZ_vel);
        plot(x(Ron:Roff),trial.mkrIXYZ_vel(Ron:Roff));
        xline(PGAFrame);
        title("Index Velocity");
        ylim([0,2000]);

        nexttile;
        hold on;
        plot(x,trial.mkrTXYZ_vel);
        plot(x(Ron:Roff),trial.mkrTXYZ_vel(Ron:Roff));
        xline(PGAFrame);
        title("Thumb Velocity");
        ylim([0,2000]);
    elseif type == 7
        f.Position = [180,250,1200,500];
        t = tiledlayout(2,6);
        title(t,str);
        nexttile([2,2]);
        hold on;
        plot3(trial.mkr5X,trial.mkr5Y,trial.mkr5Z);
        plot3(trial.mkr5X(Ron:Roff),trial.mkr5Y(Ron:Roff),trial.mkr5Z(Ron:Roff));
        plot3(trial.mkr5X(PGAFrame),trial.mkr5Y(PGAFrame),trial.mkr5Z(PGAFrame),'*r');
        title("Index 3D trajectory");
        view([136,18]);
        
        nexttile([1,2]);
        hold on;
        plot(x,trial.GAxyz);
        plot(x(Ron:Roff),trial.GAxyz(Ron:Roff));
        xline(PGAFrame);
        xlabel("Sample 20Hz");
        ylabel("GAxyz");
        xlim([0,length(trial.GAxyz)]);
        title("GA w/ Reach Interval/PGA");
        
        nexttile([1,2]);
        hold on;
        plot(x,trial.mkrIXYZ_vel);
        plot(x(Ron:Roff),trial.mkrIXYZ_vel(Ron:Roff));
        xline(PGAFrame);
        xlim([0,length(trial.mkrIXYZ_vel)]);
        title("Index Velocity");
        % ylim([0,1500]);
        xlabel("Sample 20Hz");
        ylabel("mkrIXYZ Vel");

        nexttile([1,2]);
        hold on;
        plot(x,trial.mkr5Z);
        plot(x(Ron:Roff),trial.mkr5Z(Ron:Roff));
        xline(PGAFrame);
        xlim([0,length(trial.mkr5Z)]);
        title("Index, Z component");
        xlabel("Frame (200 Hz)");
        ylabel("Z coordinate");

        nexttile([1,2]);
        hold on;
        plot(x,trial.mkrTXYZ_vel);
        plot(x(Ron:Roff),trial.mkrTXYZ_vel(Ron:Roff));
        xline(PGAFrame);
        xlim([0,length(trial.mkrTXYZ_vel)]);
        title("Thumb Velocity");
        % ylim([0,1500]);
        xlabel("Frame (200 Hz)");
        ylabel("mkrTXYZ Vel");

    else
        fprintf("Type must be member of [1 2 3 4 5 6 7].\n");
    end

end
