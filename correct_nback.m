function T = correct_nback(fpath)
if nargin < 1
    [fname, path] = uigetfile('*.csv');
    fpath = fullfile(path, fname);
end
T = readtable(fpath);
numblocks = unique(T.BlockNum);


for ii = 1:numel(numblocks)
   block_dat = T(T.BlockNum == (ii - 1), :); 
   block_dat_copy = block_dat;
   bk_nback = unique(block_dat.wmNBack(~isnan(block_dat.wmNBack)));
   
   if ~(any(block_dat.PracticeSkipped == 1))
       responseIdx = find(~isnan(block_dat.wmRespDigits));
       refStim = block_dat.wmStimID(responseIdx - bk_nback);
       % Fill in missing StimRefIDs
%        tgtIdx = block_dat.Properties.VariableNames == "wmRefStimID";
       %    missing_stim_ref = strcmp(table2cell(block_dat(responseIdx, tgtIdx)), 'NA');
       block_dat.wmRefStimID(responseIdx) = refStim;
       % Fill in missing wmCorrect
%        missing_wm_correct = isnan(block_dat.wmCorrect(responseIdx));
       block_dat.wmCorrect(responseIdx) = StimName2Num(refStim);
   else
       bk_stim_digits_num = StimName2Num(block_dat.wmStimID);
       bk_nback_resp_trials = find(~isnan(block_dat.wmNBack));
       bk_correct_idx = bk_nback_resp_trials - bk_nback; % "Determine-if-correct reference" index
       
       % For Digits Task
       block_dat.wmCorrect(bk_nback_resp_trials) = bk_stim_digits_num(bk_correct_idx);
       % For Motor Task
       block_dat.wmRefStimID(bk_nback_resp_trials) = ...
           block_dat.wmStimID(bk_correct_idx);
   end
   

   T(T.BlockNum == (ii - 1), :) = block_dat;
end
   writetable(T,fpath) 
end