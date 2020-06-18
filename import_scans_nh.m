function import_scans_nh

base_dir          = 'C:\Users\hipp\projects\WavePain\data\fmri\fmri_temp\';
data_file         = 'C:\Users\hipp\projects\WavePain\code\matlab\fmri\cb_pipeline\data.mat';

check          = 0;

do_dcm_convert = 1;
do_move        = 1;

subs = [5:17];

dummies           = 5;

n_runs = 2;
data_names = {'epi', 'FM_2TE', 'FM_diff'};

for g = 1:size(subs,2)
    name = sprintf('sub-%02d',subs(g));
    %-------------------------------
    %Do DICOM convert
    if do_dcm_convert
        gi = 1;
        
        
        % Loop over runs (including epis and both fmaps)
        for run = 1:n_runs
            run_name = strcat('Run', num2str(run));
            
            % Loop over datatypes
            for i = 1:numel(data_names)
                data_name = data_names{i};
                
                files = spm_select('FPList', fullfile(base_dir, name, run_name, data_name), '^MR');
                matlabbatch{gi}.spm.util.import.dicom.data = cellstr(files);
                matlabbatch{gi}.spm.util.import.dicom.outdir = {fullfile(base_dir, name, run_name, data_name)};
                
                matlabbatch{gi}.spm.util.import.dicom.root             = 'flat';
                matlabbatch{gi}.spm.util.import.dicom.protfilter       = '.*';
                matlabbatch{gi}.spm.util.import.dicom.convopts.format  = 'nii';
                matlabbatch{gi}.spm.util.import.dicom.convopts.meta    = 0;
                matlabbatch{gi}.spm.util.import.dicom.convopts.icedims = 0;
                gi = gi + 1;
                % and delete DICOMs
                matlabbatch{gi}.cfg_basicio.file_dir.file_ops.file_move.files         =  cellstr(files);
                matlabbatch{gi}.cfg_basicio.file_dir.file_ops.file_move.action.delete = false;
                gi = gi + 1;
            end % datatype loop
        end % run loop
        
        % T1
        if ~ismember(subs(g),[5,13])
            
            files = spm_select('FPList', [base_dir name filesep 'T1'], '^MR');
            matlabbatch{gi}.spm.util.import.dicom.data = cellstr(files);
            matlabbatch{gi}.spm.util.import.dicom.outdir = {[base_dir name filesep 'T1']};
            matlabbatch{gi}.spm.util.import.dicom.root             = 'flat';
            matlabbatch{gi}.spm.util.import.dicom.protfilter       = '.*';
            matlabbatch{gi}.spm.util.import.dicom.convopts.format  = 'nii';
            matlabbatch{gi}.spm.util.import.dicom.convopts.meta    = 0;
            matlabbatch{gi}.spm.util.import.dicom.convopts.icedims = 0;
            gi = gi + 1;
            %and delete DICOMs
            matlabbatch{gi}.cfg_basicio.file_dir.file_ops.file_move.files         =  cellstr(files);
            matlabbatch{gi}.cfg_basicio.file_dir.file_ops.file_move.action.delete = false;
            gi = gi + 1;
        end
        
        save matlabbatch matlabbatch
        spm_jobman('run',matlabbatch);
        clear matlabbatch;
        
    end
    
    %-------------------------------
    %Do move dummies
    if do_move
        gi = 1;
        for run = 1:n_runs
            run_name = strcat('Run', num2str(run));
            % and move dummy scans
            files = spm_select('FPList', fullfile(base_dir, name, run_name, 'epi'),'^fPRISMA.*\.nii');
            mkdir(fullfile(base_dir, name, run_name, 'epi', 'dummy'));
            matlabbatch{gi}.cfg_basicio.file_dir.file_ops.file_move.files         = cellstr(files(1:dummies,:));
            matlabbatch{gi}.cfg_basicio.file_dir.file_ops.file_move.action.moveto = {fullfile(base_dir, name, run_name, 'epi', 'dummy')};
            gi = gi + 1;
        end
        save matlabbatch matlabbatch
        spm_jobman('run',matlabbatch);
        clear matlabbatch;
    end
end % subject loop