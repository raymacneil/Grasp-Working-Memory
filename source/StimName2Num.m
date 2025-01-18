function stim_num = StimName2Num(stim_strings_in)

exp = '[a-zA-Z]*(?=-)';
stim_digits_tag = regexp(stim_strings_in, exp, 'match');
stim_digits_tag = vertcat(stim_digits_tag{:});
[~, stim_num] = ismember(stim_digits_tag, {'Two', 'Three', 'Four'});
stim_num = stim_num + 1;

end