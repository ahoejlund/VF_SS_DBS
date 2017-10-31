%% Quick analysis run on VERBAL FLUENCY data from 0010_VJD

% Date: 2017-09-08

% Data have been maxfiltered and cleaned for EOG and ECG via ICA-routine in
% MNE-python. VENTRAL and DORSAL conditions have had their transformation
% matrices copied from immediately following dummy-recording

%% Load preprocessed data and analyze

% addpath('/projects/MINDLAB2011_39-STN-DBS-Effect-Cortex-MEG/scripts/MATLAB_codes')
% addpath('/projects/MINDLAB2011_39-STN-DBS-Effect-Cortex-MEG/scripts/fieldtrip-20161228/')

out = [];

addpath('/Users/au183362/Documents/MATLAB/scripts')
addpath('/Users/au183362/Documents/MATLAB/toolboxes/fieldtrip-20161228/')

ft_defaults;

proc                             = [];
proc.data_folder    = ...
    '/Users/au183362/Documents/MATLAB/VF_SS_DBS/MEG/VF/preproc/';
proc.save_folder = ...
    '/Users/au183362/Documents/MATLAB/VF_SS_DBS/MEG/VF/preproc/';

subjs = {'0005_FZU', '0006_VAZ', '0008_ATW', '0009_2QT', '0010_VJD', '0011_1I1'};
conds = {'OFF','DORSAL','VENTRAL'};
letters = {{'S','P','M','tools'}, {'F','B','L','anim'}, {'K','T','D','fruits'}};
vf = {'clus','switch','bsl'};


for sub = 1%length(subjs):-1:1
    for cond_loop = length(conds):-1:1
        load(fullfile(proc.save_folder,'pow',subjs{sub+4}, sprintf('%s-pow.mat',conds{cond_loop})))
        cfg = [];
        cfg.operation = 'divide';
        cfg.parameter = 'powspctrm';
        PD_pow_clus{sub,cond_loop} = ft_combineplanar([], ft_math(cfg,pow.clus,pow.bsl));
        PD_pow_switch{sub,cond_loop} = ft_combineplanar([], ft_math(cfg,pow.switch,pow.bsl));
    end
end

% cfg = [];
% cfg.parameter = 'powspctrm';
% for cond_loop = length(conds):-1:1
%     GM_PD_clus{cond_loop} = ft_grandaverage(cfg, PD_pow_clus{:,cond_loop});
%     GM_PD_switch{cond_loop} = ft_grandaverage(cfg, PD_pow_switch{:,cond_loop});
% end




    

