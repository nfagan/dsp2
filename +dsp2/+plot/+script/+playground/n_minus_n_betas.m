%%  LOAD

conf = dsp2.config.load();
subdir = '082517';
basep = fullfile( conf.PATHS.analyses, 'n_minus_n', subdir );

all_mdls = dsp2.util.general.load_mats( basep );
all_mdls = extend( all_mdls{:} );

betas = Container( arrayfun(@(x) x.betas(2, 1), all_mdls.data), all_mdls.labels );
ps = Container( arrayfun(@(x) x.betas(2, 2), all_mdls.data), all_mdls.labels );
perc_sig = ps.for_each( {'band', 'previous_was', 'epochs'}, @row_op, @(x) perc(x <= .05) );

%%

plt = betas;
% plt = betas.keep( ps.data <= .05 );

plt = plt.only( 'shuffled__false' );

plt.bar( 'band', 'previous_was', 'epochs' );
