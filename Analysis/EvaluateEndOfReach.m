 f.Position = [350,300,800,400];
 t = tiledlayout(2,4);
 title(t,str);
 
 % Plot 3D trajectory of IDX/THMB
 nexttile([2,2]);
 hold on;
 
Ron = fwdReachStart(trial, VTon, VToff, VDon, VDoff);
Roff1 = max(fFwdOffI,fFwdOffT);
Roff2 = fFwdOff

 % Plot full IDX trajectory in blue
 plot3(trial.mkr5X,trial.mkr5Y,trial.mkr5Z,'Color',"#0072BD",'DisplayName', 'Index');
 % Plot reach interval in orange
 plot3(trial.mkr5X(fFwdOn:max(fFwdOffI,fFwdOffT)),trial.mkr5Y(Ron:Roff1),trial.mkr5Z(Ron:Roff1),'Color',"#D95319",'DisplayName', 'Reach Interval');
 % Plot moment of PGA with red *
 plot3(trial.mkr5X(PGAFrame),trial.mkr5Y(PGAFrame),trial.mkr5Z(PGAFrame),'*r','DisplayName', 'PGA');
 % Plot missing data points in magenta
 mkr5_missing = trial.mkr5_intrp;
 mkr5_missing(trial.mkr5_intrp == 0) = NaN;
 plot3(trial.mkr5X.*mkr5_missing,trial.mkr5Y.*mkr5_missing,trial.mkr5Z.*mkr5_missing,'Color',"#FF00FF",'LineWidth',1,'DisplayName', 'Interpolated');
 
 % Plot full THMB trajectory in blue
 plot3(trial.mkr4X,trial.mkr4Y,trial.mkr4Z,'Color',"#4DBEEE",'DisplayName', 'Thumb');
 % Plot reach interval in orange
 plot3(trial.mkr4X(Ron:Roff1),trial.mkr4Y(Ron:Roff1),trial.mkr4Z(Ron:Roff1),'Color',"#D95319", 'HandleVisibility','off');
 % Plot moment of PGA with red *
 plot3(trial.mkr4X(PGAFrame),trial.mkr4Y(PGAFrame),trial.mkr4Z(PGAFrame),'*r', 'HandleVisibility','off');
 % Plot missing data points in magenta
 mkr4_missing = trial.mkr4_intrp;
 mkr4_missing(trial.mkr4_intrp == 0) = NaN;
 plot3(trial.mkr4X.*mkr4_missing,trial.mkr4Y.*mkr4_missing,trial.mkr4Z.*mkr4_missing,'Color',"#FF00FF",'LineWidth',1, 'HandleVisibility','off');