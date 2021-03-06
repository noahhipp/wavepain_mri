function eda_write_bestshifts
% Writes best shifts as obtained by wavecorr to table for later access

% Constants
[~,~,~,EDA_DIR] = wave_ghost('behav');
NAME_OUT        = 'eda_bestshifts.csv';
FILE_OUT        = fullfile(EDA_DIR, NAME_OUT);

% 
shift = table;
shift.fmri_all = -7.9250;
shift.fmri_wm = -7.4250;
shift.fmri_online = -8.6;

shift.behav_all = -4.72;
shift.behav_wm = -5.12;
shift.behav_online = -3.88;

writetable(shift,FILE_OUT);
fprintf('best shifts written to %s\n', FILE_OUT);

