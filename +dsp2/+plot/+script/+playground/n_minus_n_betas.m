%%  LOAD

conf = dsp2.config.load();
subdir = '082517';
basep = fullfile( conf.PATHS.analyses, 'n_minus_n', subdir );

% all_mdls = dsp2.util.general.load_mats( basep );
% all_mdls = extend( all_mdls{:} );

files = dsp2.util.general.dirnames( basep, '.mat' );
file = files{1};

all_mdls = dsp2.util.general.fload( fullfile(basep, file) );

behav = dsp2.io.get_processed_behavior( {'preference_index', 'standard', {'monkeys', 'trials'}} );

%%

betas = Container( arrayfun(@(x) x.betas(2, 1), all_mdls.data), all_mdls.labels );
ps = Container( arrayfun(@(x) x.betas(2, 2), all_mdls.data), all_mdls.labels );
perc_sig = ps.for_each( {'band', 'previous_was', 'epochs', 'shuffled'}, @row_op, @(x) perc(x <= .05) );

behav = behav.require_fields( 'median_split' );
med = behav.for_each( {'outcomes', 'trialtypes'}, @median );
[objs, ~, C] = behav.enumerate( {'outcomes', 'trialtypes'} );
splt = behav;
for i = 1:numel(objs)
  unqs = C(i, :);
  matched = med.only( unqs );
  assert( numel(matched.data) == 1 );
  ind = behav.where( unqs );
  abv = ind & behav.data >= matched.data;
  bel = ind & behav.data < matched.data;
  behav( 'median_split', abv ) = 'above_median';
  behav( 'median_split', bel ) = 'below_median';
end

high_days = unique( behav('days', behav.where({'choice', 'otherMinusNone', 'above_median'})) );
low_days = unique( behav('days', behav.where({'choice', 'otherMinusNone', 'below_median'})) );

name = 'median_split_prosocial_behavior';
betas = betas.require_fields( name );
betas( name, betas.where(high_days) ) = 'above_median_prosocial';
betas( name, betas.where(low_days) ) = 'below_median_prosocial';

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

% plt = betas;
plt = betas.keep( ps.data <= .05 );

plt = plt.only( 'shuffled__false' );
% 
% ind = plt.where( {'previous_was__none', 'gamma'} );
% plt = plt.keep( ~ind );

pl = ContainerPlotter();
pl.y_lim = [];

plt.bar( pl, 'band', 'previous_was', {'epochs', name} );
