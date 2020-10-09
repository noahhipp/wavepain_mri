function firstlevel_parallel_FIR

hostname = char(getHostName(java.net.InetAddress.getLocalHost));
switch hostname
    case 'mahapralaya'
        base_dir          = 'd:\offhum_cb\';
        n_proc            = 4;
    case 'CB2'
        base_dir          = 'c:\Users\buechel\data\hista\';
        n_proc            = 4;
    otherwise
        error('Only hosts CB2 and mahapralaya accepted');
end



% matlabbatch{1}.cfg_basicio.run_ops.call_matlab.inputs{1}.string = '--------------\ndoing Volunteer 42\n--------------\n';
% matlabbatch{1}.cfg_basicio.run_ops.call_matlab.outputs = {};
% matlabbatch{1}.cfg_basicio.run_ops.call_matlab.fun = 'fprintf';






%user specified variables
all_subs = [6:9 11:18 21:29 31:44];
%all_subs = [6];
%all_subs = [7:9 11:18 21:29 31:44];


fourier           = 0; %if 1 hanning windowed fourier, else FIR


TR                = 1.599;
epi_folders       = {'s1','s2','s3','s4'}; % sessions


if fourier
    fourier_window    = 120;
    fourier_order     = 5;  %estimate precisely!!!
    basis_order       = 1+fourier_order*2;
    cond_use          = [1:(1+fourier_order*2)*numel(epi_folders)]; %order*2(sin/cos)+1(hanning window)
    anadirname        = ['5order_Fourier_N_physio_zan_mov'];
    addon             = 'ANOVA_FOURIER_N_NSPH'; %for second level
else    
    fir_window        = 120; % seconds
    %fir_res           = 4;  % seconds
    fir_res           = 2;  % seconds
    fir_order         = fir_window/fir_res;
    basis_order       = fir_order;
    cond_use          = [1:fir_order*numel(epi_folders)];
    %anadirname        = ['20bin_FIR_physio_zan_mov'];
    anadirname        = ['fir'];
    addon             = 'anova'; %for second level
end


shift             = 0; %no onset shift

skern             = 6;

out_dir           = [base_dir 'second_Level' filesep anadirname '_' addon '_' num2str(skern)];


skernel           = repmat(skern,1,3);

struc_templ       = '^sTRIO.*\.nii';

rfunc_file        = 'rfMRI.nii';
realign_str       =  '^rp_fMR.*\.txt';

epi_folders       = {'s1','s2','s3','s4'};
conditions        = {'Condition_1'}; % same same
anova_conditions  = {'Acq_Control','Acq_Dyspnea','Test_Control','Test_Dyspnea'}

to_warp           = 'con_%04.4d.nii'; %files to warp
% to_warp           = 'beta_%04.4d.nii'; %files to warp

n_sess            = size(epi_folders,2);
n_cond            = size(conditions,2);
dummies           = 0;

do_model    = 0;

do_cons     = 0;
do_warp     = 0;
do_smooth   = 0;
do_anova    = 0;
do_anovacon = 1;


spm_path          = fileparts(which('spm')); %get spm path
mat_name          = which(mfilename);
[~,mat_name,~]    = fileparts(mat_name);


%prepare for multiprocessing
if size(all_subs) < n_proc
    n_proc = size(all_subs,2);
end
subs              = splitvect(all_subs, n_proc);


i_sub = 0;

for np = 1:size(subs,2)
    matlabbatch = [];
    mbi   = 0;
    
    for g = 1:size(subs{np},2)
        %-------------------------------
        %House keeping stuff
        i_sub        = i_sub + 1;
        name         = sprintf('%02.2d',subs{np}(g));
        st_dir       = [base_dir name filesep 'fmri\mprage' filesep];
        struc_file   = spm_select('FPList', st_dir, struc_templ);
        u_rc1_file   = ins_letter(struc_file,'u_rc1');
        
        %reorder sessions here so that we have the same order cond
        %(CS+/CS-) and test (CS+/CS-)
        
        s_order = block_UR(subjects_P==subs{np}(g));
        
        % not necessary
        for l=1:n_sess      %l is session index for SPM, but s_order(l) is where we get our data from TAKE care!!!
            l_shuffle       = s_order(l);
            ind             = find((subjects_P==subs{np}(g)) & (block_P==l_shuffle));
            final_image     = image_count(ind);
            dummies         = dummy_count(ind);
            all_images      = 1:(final_image-dummies);
            epi_files{l}    = spm_select('ExtFPList', [base_dir filesep name filesep 'fmri\epi\' epi_folders{l_shuffle}], rfunc_file,all_images);
        end
        
        a_dir    = [base_dir name filesep anadirname];
        
        template = [];
        template.spm.stats.fmri_spec.timing.units   = 'scans';
        template.spm.stats.fmri_spec.timing.RT      = TR;
        template.spm.stats.fmri_spec.timing.fmri_t  = 16;
        template.spm.stats.fmri_spec.timing.fmri_t0 = 8;
        
        template.spm.stats.fmri_spec.fact           = struct('name', {}, 'levels', {});
        
        if fourier
            %template.spm.stats.fmri_spec.bases.fourier_han.length = fourier_window;
            %template.spm.stats.fmri_spec.bases.fourier_han.order  = fourier_order;              
            template.spm.stats.fmri_spec.bases.fourier.length = fourier_window;
            template.spm.stats.fmri_spec.bases.fourier.order  = fourier_order;              
        else
            template.spm.stats.fmri_spec.bases.fir.length = fir_window;
            template.spm.stats.fmri_spec.bases.fir.order  = fir_order;
        end
        template.spm.stats.fmri_spec.volt             = 1;
        template.spm.stats.fmri_spec.mthresh          = -Inf;
        template.spm.stats.fmri_spec.global           = 'None';
        template.spm.stats.fmri_spec.mask             = cellstr([st_dir 's3skull_strip.nii']);
        
        template.spm.stats.fmri_spec.cvi              = 'None';
        for l = 1:n_sess
            l_shuffle = s_order(l);
            s_dir     = [base_dir name filesep 'fmri\epi\' epi_folders{l_shuffle}];
            fm        = spm_select('FPList', s_dir, realign_str);
            movement  = normit(load(fm));
            
            
            
            %movement = [];
            all_nuis{l} = [movement];
            %all_nuis{sess} = [];
            n_nuis         = size(all_nuis{l},2);
            
            %n_nuis         = 0;
            
            % Loop through as 2 sess!
            z{l}        = zeros(1,n_nuis); %handy for contrast def
            
            template.spm.stats.fmri_spec.sess(l).scans = cellstr(epi_files{l}); %epi files are already reordered
            %template.spm.stats.fmri_spec.sess(sess).cond = struct('name', {}, 'onset', {}, 'duration', {}, 'tmod', {}, 'pmod', {});
            template.spm.stats.fmri_spec.sess(l).multi = {''};
            
            
            %now do conditions --> RES
            for conds = 1:numel(conditions)
                template.spm.stats.fmri_spec.sess(l).cond(conds).name     = conditions{conds};
                template.spm.stats.fmri_spec.sess(l).cond(conds).onset    = a.Time_Onset+shift;
                template.spm.stats.fmri_spec.sess(l).cond(conds).duration = 0;
            end
            
            
            template.spm.stats.fmri_spec.sess(l).multi_reg = {''};
            template.spm.stats.fmri_spec.sess(l).hpf = 360;
            for nuis = 1:n_nuis
                template.spm.stats.fmri_spec.sess(l).regress(nuis) = struct('name', cellstr(num2str(nuis)), 'val', all_nuis{l}(:,nuis));
            end
        end
        
        
        
        if do_model
            mbi = mbi + 1;
            matlabbatch{mbi} = template;
            mkdir(a_dir);
            copyfile(which(mfilename),a_dir);
            matlabbatch{mbi}.spm.stats.fmri_spec.dir = {[a_dir]};
            
            mbi = mbi + 1;
            matlabbatch{mbi}.spm.stats.fmri_est.spmmat           = {[a_dir filesep 'SPM.mat']};
            matlabbatch{mbi}.spm.stats.fmri_est.method.Classical = 1;
        end
        
        
        %%template for contrasts
        template = [];
        template.spm.stats.con.spmmat = {[a_dir filesep 'SPM.mat']};
        template.spm.stats.con.delete = 1;
        fco = 0;
        fco = fco + 1; %counter for f-contrasts
        template.spm.stats.con.consess{fco}.fcon.name   = 'eff_of_int';
        
        eoi_mat = [repmat([repmat([eye(basis_order)],1,n_cond) zeros(basis_order,n_nuis)],1,n_sess) zeros(basis_order,n_sess)];
        eoi_vec = sum(eoi_mat);
        eoi_ind = find(eoi_vec);
        template.spm.stats.con.consess{fco}.fcon.convec = {eoi_mat};
        co_i = 0;
        for co = 1:n_cond
            for i_fir = 1:basis_order
                tpl        = zeros(1,basis_order);
                tpl(i_fir) = 1;
                tpl        = [zeros(1,(co-1)*basis_order) tpl zeros(1,(n_cond-co)*basis_order)];
                convec = [];
                for i_sess = 1:n_sess
                    convec = [convec tpl z{i_sess}];
                end
                co_i = co_i + 1;
                template.spm.stats.con.consess{co_i+fco}.tcon.name    = [conditions{co} '_' num2str(i_fir)];
                template.spm.stats.con.consess{co_i+fco}.tcon.convec  = [convec zeros(1,size(epi_folders,2))];
                template.spm.stats.con.consess{co_i+fco}.tcon.sessrep = 'none';
            end
            
        end
        
        
        if do_cons
            mbi = mbi + 1;
            matlabbatch{mbi} = template; %now add constrasts
        end
        
        
        %prepare_warp
        template    = [];
        con_files   = '';
        
        all_warp = find(eoi_vec);
        
        for co = 1:numel(all_warp) %only those we need
            con_files(co,:) = [a_dir filesep sprintf(to_warp,all_warp(co))];
        end
        
        
        wcon_files             = ins_letter(con_files,'w');
        wcon_dartel_files      = ins_letter(con_files,'w_t1'); % or w_epi
        
        wcon_files             = chng_path(wcon_files, st_dir);    %wcon files still in t1 dir
        
        wcon_dartel_files      = chng_path(wcon_dartel_files, st_dir); %wcon files still in t1 dir
        wcon_dartel_files2     = chng_path(wcon_dartel_files, a_dir);  %wcon files still in ana dir
        
        
        template.spm.tools.dartel.crt_warped.flowfields = cellstr(repmat(u_rc1_file,size(con_files,1),1)); % either use u_rcl from t1 or from epis
        template.spm.tools.dartel.crt_warped.images = {cellstr(strvcat(con_files))};
        template.spm.tools.dartel.crt_warped.jactransf = 0;
        template.spm.tools.dartel.crt_warped.K = 6;
        template.spm.tools.dartel.crt_warped.interp = 1;
        
        
        if do_warp
            %T1 based dartel
            mbi = mbi + 1;
            matlabbatch{mbi} = template; %now add T1 dartel warp
            
            mbi = mbi + 1;
            matlabbatch{mbi}.cfg_basicio.file_dir.file_ops.file_move.files = cellstr(wcon_files);
            matlabbatch{mbi}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.moveto = cellstr(a_dir);
            matlabbatch{mbi}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.patrep.pattern = 'w';
            matlabbatch{mbi}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.patrep.repl    = 'w_dartel';
            matlabbatch{mbi}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.unique         = false;
            
        end
        
        if do_smooth
            mbi = mbi + 1;
            matlabbatch{mbi}.spm.spatial.smooth.data = cellstr(wcon_dartel_files2);
            matlabbatch{mbi}.spm.spatial.smooth.fwhm = skernel;
            matlabbatch{mbi}.spm.spatial.smooth.prefix = ['s' num2str(skern)];
        end
        
        if do_anova
            all_files = [];assemb_cons = [];
            for co = 1:size(eoi_ind,2)
                if skern == 0
                    sw_templ      = sprintf('w_dartelbeta_%0.4d.nii', eoi_ind(co));
                else
                    sw_templ      = sprintf('s%dw_dartelbeta_%0.4d.nii', skern, eoi_ind(co));
                end
                all_files = strvcat(all_files,[base_dir name filesep anadirname filesep sw_templ]);
                %assemb_cons = [assemb_cons eoi_ind(co)];
                assemb_cons = [assemb_cons co];
            end
            anovabatch{1}.spm.stats.factorial_design.des.anovaw.fsubject(i_sub).scans = cellstr(all_files);
            anovabatch{1}.spm.stats.factorial_design.des.anovaw.fsubject(i_sub).conds = assemb_cons;
        end
    end
    if ~isempty(matlabbatch)
        save([num2str(np) '_' mat_name],'matlabbatch');
        lo_cmd = ['clear matlabbatch;load(''' num2str(np) '_' mat_name ''');'];
        ex_cmd = ['addpath(''' spm_path ''');spm(''defaults'',''FMRI'');spm_jobman(''initcfg'');spm_jobman(''run'',matlabbatch);exit'];
        system(['matlab -nodesktop -nosplash  -logfile ' num2str(np) '_' mat_name '.log -r "' lo_cmd ex_cmd ';exit" &']); % check this one
    end
end
if do_anova
    
    anovabatch{1}.spm.stats.factorial_design.dir = {out_dir};
    anovabatch{1}.spm.stats.factorial_design.des.anovaw.dept = 0;
    anovabatch{1}.spm.stats.factorial_design.des.anovaw.variance = 0;
    anovabatch{1}.spm.stats.factorial_design.des.anovaw.gmsca = 0;
    anovabatch{1}.spm.stats.factorial_design.des.anovaw.ancova = 0;
    anovabatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
    anovabatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
    anovabatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    anovabatch{1}.spm.stats.factorial_design.masking.im = 1;
    anovabatch{1}.spm.stats.factorial_design.masking.em = {[base_dir 'AND_mask.nii']};
    anovabatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    anovabatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    anovabatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

    %% --------------------- MODEL ESTIMATION --------------------- %
    anovabatch{2}.spm.stats.fmri_est.spmmat = {[out_dir '\SPM.mat']};
    anovabatch{2}.spm.stats.fmri_est.method.Classical = 1;

    %need to estimate first, than load SPM.mat to use FcUtil!!!
    
    %matlabbatch = anovabatch;
    %save('anovabatch','matlabbatch')
    
    spm_jobman('initcfg');
    spm('defaults', 'FMRI');
    spm_jobman('run',anovabatch);
    copyfile(which(mfilename),out_dir);
end

if do_anovacon
    anovabatch = []
    
    sub_const = [size(cond_use,2)+1:size(cond_use,2)+size(all_subs,2)];
    clear SPM; load([out_dir '\SPM.mat']); %should exist by now
    anovabatch{1}.spm.stats.con.spmmat = {[out_dir '\SPM.mat']};
    anovabatch{1}.spm.stats.con.delete = 1;
    
    co = 1;
    anovabatch{1}.spm.stats.con.consess{co}.fcon.name   = 'eff_of_int';
    Fc = spm_FcUtil('Set','F_iXO_Test','F','iX0',sub_const,SPM.xX.X);
    anovabatch{1}.spm.stats.con.consess{co}.fcon.convec = {Fc.c'};
    co = co + 1; %increment by 1
    
    
    for con_i =1:size(anova_conditions,2)
        anovabatch{1}.spm.stats.con.consess{co}.fcon.name   = anova_conditions{con_i};
        all = 1:size(anova_conditions,2)*basis_order;
        all((con_i-1)*basis_order+1:con_i*basis_order) = [];
        Fc = spm_FcUtil('Set','F_iXO_Test','F','iX0',[all sub_const],SPM.xX.X);
        anovabatch{1}.spm.stats.con.consess{co}.fcon.convec = {Fc.c'};
        Fcc{con_i} = Fc.c';
        co = co + 1; %increment by 1
    end
      
    %diff_con = [1 2; 3 4];
    diff_con = [2 1; 4 3; 3 1; 4 2];
    
    for con_i =1:size(diff_con,1)
        anovabatch{1}.spm.stats.con.consess{co}.fcon.name   = [anova_conditions{diff_con(con_i,1)} '-' anova_conditions{diff_con(con_i,2)}];
        anovabatch{1}.spm.stats.con.consess{co}.fcon.convec = round(Fcc{diff_con(con_i,1)} - Fcc{diff_con(con_i,2)}); %dirty hack with round()
        co = co + 1; %increment by 1
    end
    
    
    
    spm_jobman('run',anovabatch);
end

function chuckCell = splitvect(v, n)
% Splits a vector into number of n chunks of  the same size (if possible).
% In not possible the chunks are almost of equal size.
%
% based on http://code.activestate.com/recipes/425044/

chuckCell = {};

vectLength = numel(v);


splitsize = 1/n*vectLength;

for i = 1:n
    %newVector(end + 1) =
    idxs = [floor(round((i-1)*splitsize)):floor(round((i)*splitsize))-1]+1;
    chuckCell{end + 1} = v(idxs);
end

function out = ins_letter(pscan,letter)
for a=1:size(pscan,1)
    [p , f, e] = fileparts(pscan(a,:));
    out(a,:) = [p filesep letter f e];
end

function out = chng_path(pscan,pa)
for a=1:size(pscan,1)
    [p , f, e] = fileparts(pscan(a,:));
    out(a,:) = [pa filesep f e];
end










