function [natural, panto] = fillvelWM(ngKeep, pgKeep)

grasps = ["Natural", "Panto"];
srate = 200;
fill = false;

for ii = 1:numel(grasps)
    
    for jj = 1:size(ngKeep,2)
        
        
        ID = ngKeep{1,jj};
        Grasp = grasps(ii);
        
        if ii == 1
            ntrials = nnz(~cellfun("isempty", (ngKeep(2:end,jj))));
        elseif ii == 2
            ntrials = nnz(~cellfun("isempty", (pgKeep(2:end,jj))));
        end
        
        for kk = 1:ntrials
            
            if ii == 1
                Trial = ngKeep{kk+1,jj};
            elseif ii == 2
                Trial = pgKeep{kk+1,jj};
            end
            
            fprintf("ID: %s, Grasp: %s, Trial Number: %d \n", ID, Grasp, kk)
            
            % Get instantaneous velocity values not previously claculated           
            noVelCheckI = and(~isnan(Trial.mkrIX), (isnan(Trial.mkrIXYZ_vel) | Trial.mkrIXYZ_vel == 0 ));
            
            
            if any(noVelCheckI)
                
                % 2D Velocity
                mkrI_rXY = [NaN,NaN; diff([Trial.mkrIX,Trial.mkrIY])]; % compute displacement
                mkrI_vXY = sqrt(sum((mkrI_rXY ./ (1/srate)).^2, 2)); % compute instantaneous velocity
                Trial.mkrIXY_vel(noVelCheckI) = mkrI_vXY(noVelCheckI); % fill missing values where able
                
                % 3D Velocity
                mkrI_rXYZ = [NaN,NaN,NaN; diff([Trial.mkrIX,Trial.mkrIY,Trial.mkrIZ])]; % compute displacement
                mkrI_vXYZ = sqrt(sum((mkrI_rXYZ ./ (1/srate)).^2, 2)); % compute instantaneous velocity
                Trial.mkrIXYZ_vel(noVelCheckI) = mkrI_vXYZ(noVelCheckI); % fill missing values where able
                
                % Tell MATLAB we need to update Trial
                fill = true; 
                
            end
          
                      
            noVelCheckT = and(~isnan(Trial.mkrTX), (isnan(Trial.mkrTXYZ_vel) | Trial.mkrTXYZ_vel == 0));
            zrVelCheckT = and(isnan(Trial.mkrTX), Trial.mkrTXYZ_vel == 0);
            
            if any(noVelCheckT)
                % 2D Velocity
                mkrT_rXY = [NaN,NaN; diff([Trial.mkrTX,Trial.mkrTY])]; % compute displacement
                mkrT_vXY = sqrt(sum((mkrT_rXY ./ (1/srate)).^2, 2)); % compute velocity
                Trial.mkrTXY_vel(noVelCheckT) = mkrT_vXY(noVelCheckT); % fill missing values where able
                
                % 3D Velocity
                mkrT_rXYZ = [NaN,NaN,NaN; diff([Trial.mkrTX,Trial.mkrTY,Trial.mkrTZ])]; % compute displacement
                mkrT_vXYZ = sqrt(sum((mkrT_rXYZ ./ (1/srate)).^2, 2)); % compute velocity
                Trial.mkrTXYZ_vel(noVelCheckT) = mkrT_vXYZ(noVelCheckT); % fill missing values where able
                
                % Tell MATLAB we need to update Trial
                fill = true;
            end 
            
            if any(zrVelCheckT)
                Trial.mkrTXY_vel(zrVelCheckT) = NaN;
                Trial.mkrTXYZ_vel(zrVelCheckT) = NaN;
                fill = true;
            end
            
            if fill
                if ii == 1
                    ngKeep(kk+1,jj) = {Trial};
                elseif ii == 2
                    pgKeep(kk+1,jj) = {Trial};
                end
            end
            
            fill = false;

        end
    end
                      
end

natural = ngKeep;
panto = pgKeep;

end