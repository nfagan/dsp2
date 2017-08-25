%%  LOAD

conf = dsp2.config.load();
subdir = '082517';
basep = fullfile( conf.PATHS.analyses, 'n_minus_n', subdir );

% all_mdls = dsp2.util.general.load_mats( basep );
% all_mdls = extend( all_mdls{:} );
all_mdls = dsp2.util.general.fload( fullfile(basep, 'n_minus_n_reward.mat') );

%%

betas = Container( arrayfun(@(x) x.betas(2, 1), all_mdls.data), all_mdls.labels );
ps = Container( arrayfun(@(x) x.betas(2, 2), all_mdls.data), all_mdls.labels );
perc_sig = ps.for_each( {'band', 'previous_was', 'epochs', 'shuffled'}, @row_op, @(x) perc(x <= .05) );

%%

figure(1); clf();

plt = betas;
% plt = betas.keep( ps.data <= .05 );

plt = plt.only( 'shuffled__false' );

ind = plt.where( {'previous_was__none', 'gamma'} );
plt = plt.keep( ~ind );

plt.bar( 'band', 'previous_was', 'epochs' );
