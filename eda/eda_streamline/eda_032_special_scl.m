function eda_032_special_scl
% detrend seems to make more sense for online data. so lets try the
% following: WM: s_zt_scl, ONLINE: s_zt_dtt_scl --> DONE and

% and also add baseline col for special col

behav = 1;

% Constants
EDA_NAME_IN     = 'all_eda_behav_downsampled01_collapsed.csv';
[~,~,~,EDA_DIR] = wave_ghost('behav');
EDA_FILE_IN     = fullfile(EDA_DIR, EDA_NAME_IN);
[~,NAME, SUFFIX]= fileparts(EDA_FILE_IN);
EDA_FILE_OUT    = EDA_FILE_IN;

CHECK_NAME = [NAME, '_has_special_scl.bin'];
CHECK_FILE = fullfile(EDA_DIR, CHECK_NAME);

if exist(CHECK_FILE,'file')
    fprintf('to run this function again\ndelete %s\n',CHECK_FILE);
    return
end

col_wm      = 's_zt_scl'; % Take values for wm conditions from this column..
col_online  = 's_zt_dtt_scl'; % for ONLINE conditions use this column...
special_col = 'special_scl'; % and merge them into this one.

DATA=readtable(EDA_FILE_IN); % debatable whether this is a constant as we manipulate it quite a bit...
fprintf('Read in %s\ncontaining %d lines\n', EDA_FILE_IN, height(DATA));

% Make special col
idx_wm = DATA.condition < 5;
idx_online = DATA.condition > 4;

DATA{:,special_col}             = nan(height(DATA),1);
DATA{idx_wm,special_col}        = DATA{idx_wm, col_wm};
DATA{idx_online, special_col}   = DATA{idx_online, col_online};

% Make special baseline col
bl_col = strcat(special_col, '_bl');
DATA{:,bl_col}                  = nan(height(DATA),1);

% for behav sample we have to exclude some subs cause they did not receive
% any online or wm ratings yet
if behav
    DATA_without_online = DATA(DATA.ID < 15,:);
    DATA(DATA.ID < 15,:) = [];
end

% Ms
DATA{DATA.condition == 1, bl_col} = DATA{DATA.condition == 1, special_col}...
    - DATA{DATA.condition == 5, special_col};
DATA{DATA.condition == 2, bl_col} = DATA{DATA.condition == 2, special_col}...
    - DATA{DATA.condition == 5, special_col};
DATA{DATA.condition == 5, bl_col} = DATA{DATA.condition == 5, special_col}...
    - DATA{DATA.condition == 5, special_col};

% Ws
DATA{DATA.condition == 3, bl_col} = DATA{DATA.condition == 3, special_col}...
    - DATA{DATA.condition == 6, special_col};
DATA{DATA.condition == 4, bl_col} = DATA{DATA.condition == 4, special_col}...
    - DATA{DATA.condition == 6, special_col};
DATA{DATA.condition == 6, bl_col} = DATA{DATA.condition == 6, special_col}...
    - DATA{DATA.condition == 6, special_col};

% reconcatenate if we have to
if behav
    DATA = vertcat(DATA_without_online, DATA);
end

% Write output
writetable(DATA, EDA_FILE_OUT);
fprintf('Rewrote %s\ncontaining %d lines\n', EDA_FILE_OUT, height(DATA));

% Write check file
f = fopen(CHECK_FILE, 'w');
fclose(f);


