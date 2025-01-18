% SmoothCorrelationsWM finds the Pearson correlation coefficients for all
% smoothness metrics vs interval size in AllMetrics from WM experiment data. 
% Uses MATLAB function 'corrcoef' for computing coefficients.
% Outputs a table summarizing results

function CorrelationsTable = SmoothCorrelationsWM(AllMetrics)
    variableNames = ["Participant","Grasp","LDJ_Early_Corr","SPARC_Early_Corr",...
                "LDJ_Mid_Corr","SPARC_Mid_Corr","LDJ_Late_Corr","SPARC_Late_Corr",...
                "LDJ_GAVelOpen_Corr","SPARC_GAVelOpen_Corr","LDJ_GAVelClose_Corr","SPARC_GAVelClose_Corr"];
    T = table('Size',[2*size(AllMetrics,2),length(variableNames)],'VariableTypes',...
        ["categorical","categorical",repelem("single",length(variableNames)-2)],...
        'VariableNames',variableNames);
    Tidx = 1;

    for ii = 1:4
        for jj = 1:size(AllMetrics,2)
           T(Tidx,:) = ExperimentCorrelation2(AllMetrics{2,jj,ii}); 
           Tidx = Tidx + 1;
        end
    end

    CorrelationsTable = T;

end


function CorrelationTable = ExperimentCorrelation2(ParticipantMetrics)
    temp = ParticipantMetrics;
    
    % Reach intervals - Early: ft0->fRon, Mid: fRon->fPGA, Late: fPGA->fRoff
    Early = temp.fRon - temp.ft0;
    Mid = temp.fPGA - temp.fRon;
    Late = temp.fAdjusted_Roff - temp.fPGA;
    T = table;
    T.Participant = temp.participant(1);
    T.Grasp = temp.Grasp(1);

    try
        [T.LDJ_Early_Corr, T.SPARC_Early_Corr] = CorrelationSub(temp.LDJ_Early,temp.SPARC_Early,Early);
    catch
        T.LDJ_Early_Corr = nan;
        T.SPARC_Early_Corr = nan;
    end
    
    [T.LDJ_Mid_Corr, T.SPARC_Mid_Corr] = CorrelationSub(temp.LDJ_Mid,temp.SPARC_Mid,Mid);
    [T.LDJ_Late_Corr, T.SPARC_Late_Corr] = CorrelationSub(temp.LDJ_Late,temp.SPARC_Late,Late);
    [T.LDJ_GAVelOpen_Corr, T.SPARC_GAVelOpen_Corr] = CorrelationSub(temp.LDJ_GAVelOpen,temp.SPARC_GAVelOpen,Mid);
    [T.LDJ_GAVelClose_Corr, T.SPARC_GAVelClose_Corr] = CorrelationSub(temp.LDJ_GAVelClose,temp.SPARC_GAVelClose,Late);
    
    CorrelationTable = T;

end


function [R1,R2] = CorrelationSub(smooth1,smooth2,interval)

    valid = ~isnan(smooth1) & ~isnan(smooth2);
    R1 = (corrcoef(smooth1(valid),interval(valid)));
    R1 = R1(1,2);
    R2 = corrcoef(smooth2(valid),interval(valid));
    R2 = R2(1,2);

end