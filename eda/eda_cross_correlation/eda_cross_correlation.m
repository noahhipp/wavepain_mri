function best_lags = eda_cross_correlation
% Does the following cross correlation analyis with eda:
% 0. Most basic: Cross correlation across all data for all trials, online
% only, wm only

% 1. Cross correlation by trial: Does the cross correlation change
% throughout a the experiment?

% 2. Cross correlation change by trial for subjects: Do subjects show the
% same pattern of change over change over time? Is there a correlation
% between how big the lag is and how good the correlation is? -->
% firstlevel data quality does not seem to be good enough to do this


[~,~,~,EDA_DIR] = wave_ghost('behav');
NAME_IN         = 'all_eda_behav_downsampled10.csv';
% [~,~,~,EDA_DIR] = wave_ghost;
% NAME_IN         = 'all_eda_clean_downsampled10.csv';
FILE_IN         = fullfile(EDA_DIR, NAME_IN);
F = 10; % sampling freq of our data

% Grab data
DATA = readtable(FILE_IN);
fprintf('read in %s\n', FILE_IN);

% flags
do_ana0 = 0;
do_ana1 = 0;
do_ana2 = 1;
%=================== ANALYIS 0: SCL LAG BY TRIAL TYPE =====================
if do_ana0
    title_addons = {'',' ONLINE ONLY',' WM ONLY'};
    conds_to_include = {[1:6], [5,6],[1:4]};
    
    for i = 1:size(conds_to_include,2)
        
        % select data
        data = DATA(ismember(DATA.condition, conds_to_include{i}),:);
        
        % Calculate and plot wavecorr
        figure('Color', 'white')
        wavecorr(data.heat, data.zdt_scl, F);
        ylim([-.5,.5]);
        yticks([-.5:.1:.5]);
        grid on;
        title(strcat('Cross correlation of heat and scl',title_addons{i}));
    end
end

%=================== ANALYSIS0 end=========================================


%=================== ANALYIS 1: SCL LAG BY TRIALS =========================
if do_ana1
    figure('Color','white','Name','all wavecorrs');
    best_lags = [];
    for i = 1:max(DATA.trial)
        % Select subplot
        subplot(4,6,i);
        
        % Select data
        trial_data = DATA(DATA.trial <= i,:);
        
        % Calculate cross correlation and save result
        fprintf('Calculating cross correlation for first %02d trials...',...
            i);
        best_lags(i) = wavecorr(trial_data.heat, trial_data.scl, F);
        fprintf('done.\n');
        
        % Customize block
        title(sprintf('trials passed: %02d', i));
    end
    
    % Pver
    figure('Color','white','Name','scl lag vs trial');
    plot(best_lags);
    xlabel('Trials passed');
    ylabel('Best SCL Lag [s]');
end
%=================== ANALYIS 1 end: SCL LAG BY TRIALS =====================

%================== ANALYSIS 2: Individual cross correlation change========
if do_ana2
    NAME_OUT = 'all_behav_crosscorrelations.csv';
    FILE_OUT = fullfile(EDA_DIR, NAME_OUT);
    
    % Loop through subs
    cross_corr_data = [];
    subs = unique(DATA.ID);
    for i = 1:numel(subs)
        
        % Select data
        sub  = subs(i);
        fprintf('\nDoing sub%03d\n',sub);
        data = DATA(DATA.ID == sub,:);
        
        figure('Name',sprintf('sub%03d',sub), 'Color','white');
        
        trials = unique(data.trial);
        for j = 1:numel(trials)
            trial = trials(j);
            fprintf('    trial %02d\n',trial);
            trial_data = data(data.trial == trial,:);
            
            % Plot it
            subplot(4,6,trial)
            [best_lag, ~, best_corr]=...
                wavecorr(trial_data.heat, trial_data.zdt_scl, F,100);
            title(sprintf('trials passed: %02d', trial));
            
            % Save it
            cross_corr_data = vertcat(cross_corr_data,...
                [sub, trial, best_lag, best_corr]);
        end
    end
    
    % Write output
    data_out = array2table(cross_corr_data, 'VariableNames',...
        {'ID','trials_so_far', 'best_lag','best_corr'});
    writetable(data_out,FILE_OUT);
    fprintf('Wrote %s\n',FILE_OUT);
end
%====================================ANALYSIS 2 END========================