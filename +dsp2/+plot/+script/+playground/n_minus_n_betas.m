%%  LOAD

conf = dsp2.config.load();
subdir = '082517';
basep = fullfile( conf.PATHS.analyses, 'n_minus_n', subdir );

% all_mdls = dsp2.util.general.load_mats( basep );
% all_mdls = extend( all_mdls{:} );

files = dsp2.util.general.dirnames( basep, '.mat' );
file = files{1};

all_mdls = dsp2.util.general.fload( fullfile(basep, file) );

%%

betas = Container( arrayfun(@(x) x.betas(2, 1), all_mdls.data), all_mdls.labels );
ps = Container( arrayfun(@(x) x.betas(2, 2), all_mdls.data), all_mdls.labels );
perc_sig = ps.for_each( {'band', 'previous_was', 'epochs', 'shuffled'}, @row_op, @(x) perc(x <= .05) );

%%

neg_beta_beta_ind = betas.keep( betas.where( {'shuffled__false', 'beta'} ) & betas.data < 0 & ps.data <= .05 );
pos_beta_beta_ind = betas.keep( betas.where( {'shuffled__false', 'beta'} ) & betas.data > 0 & ps.data <= .05 );

neg_days = neg_beta_beta_ind( 'days' );
pos_days = pos_beta_beta_ind( 'days' );

% betas = betas.require_fields( 'beta_band_sign' );
% betas( 'beta_band_sign', neg_beta_beta_ind ) = 'negative';
% betas( 'beta_band_sign', pos_beta_beta_ind ) = 'positive';
% sig_beta = betas.keep( sig_beta );

%%

figure(1); clf();

plt = betas;
% plt = betas.keep( ps.data <= .05 );

plt = plt.only( 'shuffled__false' );

ind = plt.where( {'previous_was__none', 'gamma'} );
plt = plt.keep( ~ind );

pl = ContainerPlotter();
pl.y_lim = [-5, 10];

plt.bar( pl, 'band', 'previous_was', 'epochs' );
