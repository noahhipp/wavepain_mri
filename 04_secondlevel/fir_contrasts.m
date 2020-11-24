function fir_contrasts
% Defines all the contrasts for 60*2s FIR analysis of wavepain mri data

% Makes 3 Parametric contrasts for second_level_anova of wavepain:
% 1. "heat": z_scored waveit2 wave for each stimulus [M M W W M W]
% 2. "working_memory": box car function encoding wm_task (1 --> 2back aka
% high wm load, -1--> 1 back aka low wm load)
% 3. "heat_x_wm" --> interaction of the two


% House keeping
hostname =  char(getHostName(java.net.InetAddress.getLocalHost));
switch hostname
    case 'DESKTOP-3UBJ04S'
        base_dir          = 'C:\Users\hipp\projects\WavePain\data\fmri\fmri_temp\';
        n_proc            = 2;
    case 'revelations'
        base_dir          = '/projects/crunchie/hipp/wavepain/';
        n_proc            = 4;
    otherwise
        error('Only hosts noahs isn laptop accepted');
end

% Settings
do_plot = 1;
do_cons = 0;

% Housekeeping
skern               = 6;
addon               = 'anova';
anadirname         = 'fir';
out_dir             = [base_dir 'second_Level' filesep anadirname '_' addon '_' num2str(skern)];
parametric_contrasts    = plot_parametric_contrasts(0); % arithmetic for parametric contrasts is done in plot_parametric_contrasts


%%%%%%%%%%%%%%%%%%%%%%
fcon_i = 1;         %%
fconmat= [];        %% each fcon is a matrix!!!
%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%
tcon_i = 1;         %%
tconvec= [];        %% each tcon is a row!!!
%%%%%%%%%%%%%%%%%%%%%%


% Eoi contrasts
eoi_names       = {'eoi_all', 'eoi_m21', 'eoi_m12', 'eoi_w21', 'eoi_w12', 'eoi_monline', 'eoi_wonline'};
fconmat(:,:,fcon_i) = [eye(60), eye(60), eye(60), eye(60),eye(60),eye(60)]; fcon_i = fcon_i+1; 
fconmat(:,:,fcon_i) = [zeros(60,0), eye(60),   zeros(60,300)]; fcon_i = fcon_i+1; 
fconmat(:,:,fcon_i) = [zeros(60,60), eye(60),  zeros(60,240)]; fcon_i = fcon_i+1; 
fconmat(:,:,fcon_i) = [zeros(60,120), eye(60), zeros(60,180)]; fcon_i = fcon_i+1; 
fconmat(:,:,fcon_i) = [zeros(60,180), eye(60), zeros(60,120)]; fcon_i = fcon_i+1; 
fconmat(:,:,fcon_i) = [zeros(60,240), eye(60), zeros(60,60)]; fcon_i = fcon_i+1; 
fconmat(:,:,fcon_i) = [zeros(60,300), eye(60), zeros(60,0)]; fcon_i = fcon_i+1; 


% Online aka (baseline) difference contrasts
baseline_difference_names = {'m21_vs_monline', 'm12_vs_monline', 'w21_vs_wonline', 'w12_vs_wonline',...
                            'm21_vs_m12', 'w21_vs_w12'};                        
fconmat(:,:,fcon_i) = [zeros(60,0),   eye(60), zeros(60,180), -eye(60), zeros(60,60)]; fcon_i = fcon_i +1;                       
fconmat(:,:,fcon_i) = [zeros(60,60),  eye(60), zeros(60,120), -eye(60), zeros(60,60)]; fcon_i = fcon_i +1;                        
fconmat(:,:,fcon_i) = [zeros(60,120), eye(60), zeros(60,120), -eye(60), zeros(60,0)]; fcon_i = fcon_i +1;                        
fconmat(:,:,fcon_i) = [zeros(60,180), eye(60), zeros(60,60),  -eye(60), zeros(60,0)]; fcon_i = fcon_i +1;                        
fconmat(:,:,fcon_i) = [zeros(60,0),   eye(60), zeros(60,0),   -eye(60), zeros(60,240)]; fcon_i = fcon_i +1;                        
fconmat(:,:,fcon_i) = [zeros(60,120), eye(60), zeros(60,0),   -eye(60), zeros(60,120)]; fcon_i = fcon_i +1;                        


% Working memory contrasts
obtb            = parametric_contrasts.obtb;
tbob            = parametric_contrasts.tbob;
ob              = -ones(1,17);
tb              =  ones(1,17);
nb              = zeros(1,17);
lead_in         = zeros(1,11);
lead_out        = zeros(1,15);
working_memory_names = {'working_memory', 'working_memory_up_slope', 'working_memory_down_slope', ...
                        'working_memory_m', 'working_memory_w'};
tconvec(tcon_i, :) = [tbob obtb tbob obtb, zeros(1,120)]; tcon_i = tcon_i + 1;
tconvec(tcon_i, :) = [lead_in, nb, ob, lead_out, lead_in, nb, tb, lead_out, lead_in, tb, nb, lead_out, lead_in, ob, nb, lead_out, zeros(1,120) ]; tcon_i = tcon_i + 1;
tconvec(tcon_i, :) = [lead_in, tb, nb, lead_out, lead_in, ob, nb, lead_out, lead_in, nb, ob, lead_out, lead_in, nb, tb, lead_out, zeros(1,120) ]; tcon_i = tcon_i + 1;
tconvec(tcon_i, :) = [lead_in, tb, ob, lead_out, lead_in, ob, tb, lead_out, zeros(1,240) ]; tcon_i = tcon_i + 1;
tconvec(tcon_i, :) = [zeros(1,120), lead_in, tb, ob, lead_out, lead_in, ob, tb, lead_out, zeros(1,120)]; tcon_i = tcon_i + 1;


% Parametric heat contrasts
m                   = parametric_contrasts.m;
w                   = parametric_contrasts.w;
dm                  = parametric_contrasts.dm; % dm = m' aka the first temporal derivative of m
dw                  = parametric_contrasts.dw;
heat_names          = {'heat', 'dheat', 'dunsigned_heat'};
tconvec(tcon_i,:)   = [m, m, w, w, m, w]; tcon_i = tcon_i + 1;
tconvec(tcon_i,:)   = [dm, dm, dw, dw, dm, dw]; tcon_i = tcon_i + 1;
tconvec(tcon_i,:)   = zscore(abs([dm, dm, dw, dw, dm, dw])); tcon_i = tcon_i + 1;


% Interactions a_X_b
m21                 = parametric_contrasts.m21;
m12                 = parametric_contrasts.m12;
w21                 = parametric_contrasts.w21;
w12                 = parametric_contrasts.w12;
interaction_names   = {'heat_X_working_memory','heat_X_working_memory_flipped',...
                    'down_slope_2back_>_1back', 'down_slope_2back_<_1back',...
                    'down_slope_2back_>_1back2', 'down_slope_2back_<_1back2'}; % contrasts shifted completely
                
tconvec(tcon_i,:)   =  [m, m, w, w, m, w].*[tbob obtb tbob obtb, zeros(1,120)]; tcon_i = tcon_i + 1;
tconvec(tcon_i,:)   = -[m, m, w, w, m, w].*[tbob obtb tbob obtb, zeros(1,120)]; tcon_i = tcon_i + 1;                
tconvec(tcon_i,:)   =  [m21(1:28), zeros(1,32),... % show areas where 2back > 1back
                        m12(1:28), zeros(1,32),...
                        zeros(1,28), w21(29:end),...
                        zeros(1,28), w12(29:end), zeros(1,120)]; tcon_i = tcon_i + 1;
tconvec(tcon_i,:)   = -[m21(1:28), zeros(1,32),... % show areas where 2back < 1back
                        m12(1:28), zeros(1,32),...
                        zeros(1,28), w21(29:end),...
                        zeros(1,28), w12(29:end), zeros(1,120)]; tcon_i = tcon_i + 1;                    
                    
tconvec(tcon_i,:)   =   [m21(1:11),(m21(12:28) - min(m21(12:28))), zeros(1,32),... % 2back sections completely shifted above x axis. 1back sections shifted belowe
                        m12(1:11), (m12(12:28) - max(m12(12:28))), zeros(1,32),...
                        zeros(1,28), (w21(29:45)-max(w21(29:45))), w21(46:end),...
                        zeros(1,28), (w12(29:45)-min(w12(29:45))), w12(46:end), zeros(1,120)]; tcon_i = tcon_i + 1;                                                                                                                        
tconvec(tcon_i,:)   =   -[m21(1:11),(m21(12:28) - min(m21(12:28))), zeros(1,32),... % 2back sections completely shifted above x axis. 1back sections shifted belowe
                        m12(1:11), (m12(12:28) - max(m12(12:28))), zeros(1,32),...
                        zeros(1,28), (w21(29:45)-max(w21(29:45))), w21(46:end),...
                        zeros(1,28), (w12(29:45)-min(w12(29:45))), w12(46:end), zeros(1,120)]; tcon_i = tcon_i + 1;


% SPM code
matlabbatch                                                 = [];

% Do F-Contrasts
fcon_names                          = [eoi_names, baseline_difference_names];
matlabbatch{1}.spm.stats.con.spmmat = {fullfile(out_dir, 'SPM.mat')};
matlabbatch{1}.spm.stats.con.delete = 1; % we want a clean slate
for i = 1:size(fcon_names,2)
    matlabbatch{1}.spm.stats.con.consess{i}.fcon.name       = fcon_names{i};
    matlabbatch{1}.spm.stats.con.consess{i}.fcon.convec     = fconmat(:,:,i);
    matlabbatch{1}.spm.stats.con.consess{i}.fcon.sessrep    = "none";
end

% Do T-Contrasts
tcon_names                          = [working_memory_names, heat_names, interaction_names];
matlabbatch{2}.spm.stats.con.spmmat = {fullfile(out_dir, 'SPM.mat')};
matlabbatch{2}.spm.stats.con.delete = 0; % already cleaned during fcon defitnion
for i = 1:size(tcon_names,2)
    matlabbatch{2}.spm.stats.con.consess{i}.tcon.name       = tcon_names{i};
    matlabbatch{2}.spm.stats.con.consess{i}.fcon.convec     = tconvec(i,:);
    matlabbatch{2}.spm.stats.con.consess{i}.fcon.sessrep    = "none";
end



if do_plot        
    % F Contrasts
    figure('Name','F-Contrasts', 'Color', [1 1 1]);
    sgtitle('F-CONTRASTS', 'FontSize', 24, 'FontWeight', 'bold');
    for i = 1:size(fcon_names,2)
        subplot(size(fcon_names,2), 1, i);       
        fcon_plot(fconmat(:,:,i));
        title(fcon_names{i}, 'interpreter','none')
    end
    
    % T Contrasts
    figure('Name','T-Contrasts', 'Color', [1 1 1]);
    sgtitle('T-CONTRASTS', 'FontSize', 24, 'FontWeight', 'bold');
    for i = 1:size(tcon_names,2)
        subplot(size(tcon_names,2), 1, i);       
        tcon_plot(tconvec(i,:));
        title(tcon_names{i}, 'interpreter','none')
    end        
    
    % Check
    check = input('press y and enter to proceed, else just hit enter\n', 's');
    if ~strcmp(check,'y')
        close F-Contrasts T-Contrasts
        fprintf('ABORTING\n\n')
        return
    end
end

if do_cons
    spm_jobman('run', matlabbatch);
end

% Subfunctions
function fcon_plot(M)
% receives matrix and plots it as greyscaled image to current axis with
% some special wavepain customization
imagesc(M);
colormap(flipud(gray(256)));
cond_sep = vline(60:60:360, 'r-');
for i = 1:size(cond_sep,2)
    cond_sep(i).LineWidth = 2;
end
xticks(60:60:360);

function tcon_plot(v)
% receives vector and plots it to current axis wiht some special wavepain
% customization
plot(v, 'k-');
cond_sep = vline(60:60:360, 'r-');
for i = 1:size(cond_sep,2)
    cond_sep(i).LineWidth = 2;
end
xticks(60:60:360);



