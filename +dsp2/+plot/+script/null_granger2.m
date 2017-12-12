%%  LOAD

import dsp2.util.general.percell;
import dsp2.util.general.flatten;
import dsp2.util.general.load_mats;

m_within = { 'outcomes', 'trialtypes', 'regions', 'permuted', 'channels' ...
  , 'epochs', 'days', 'administration' };

is_drug = false;
DO_SAVE = false;

if ( ~is_drug )
%   subdir = 'null';
%   subdir = fullfile( '121117', 'non_drug_null' );
  subdir = fullfile( '120717', 'non_drug_null' );
else
  subdir = 'drug_effect_null';
end
conf = dsp2.config.load();
load_p = fullfile( conf.PATHS.analyses, 'granger', subdir );
% epochs = dsp2.util.general.dirnames( load_p, 'folders' );
epochs = { 'targacq' };
per_epoch = cell( 1, numel(epochs) );
names = cell( 1, numel(epochs) );
for i = 1:numel( epochs )
  fprintf( '\n - Processing %s (%d of %d)', epochs{i}, i, numel(epochs) );
  fullp = fullfile( load_p, epochs{i} );
  mats = dsp2.util.general.dirnames( fullp, '.mat' );
  loaded = cell( 1, numel(mats) );
  parfor k = 1:numel(mats)
    warning( 'off', 'all' );
    fprintf( '\n\t - Processing %s (%d of %d)', mats{k}, k, numel(mats) );
    current = dsp2.util.general.fload( fullfile(fullp, mats{k}) );
    current.data = real( current.data );
    %
    %   get rid of drug / administration
    %
    if ( ~is_drug )
      current = current.collapse( {'drugs', 'administration'} );
    end
    current = current.for_each_1d( m_within, @Container.nanmean_1d );
    loaded{k} = current;
  end
  per_epoch{i} = loaded;
end

per_epoch = flatten( per_epoch );

per_epoch = per_epoch.add_field( 'max_lags', '5e3' );

%%  MAKE PRO V ANTI

kept = per_epoch.keep_within_freqs( [0, 100] );
kept = dsp2.process.manipulations.pro_v_anti( kept );

kept = kept.collapse( {'sessions','blocks','recipients','magnitudes'} );
if ( is_drug )
  kept = dsp2.process.manipulations.post_minus_pre( kept );
end


%%

DO_SAVE = true;

bands = { [4, 8], [8, 13], [13, 30], [30, 60], [60, 100] };
band_names = { 'theta', 'alpha', 'beta', 'gamma', 'high_gamma' };

meaned2 = cellfun( @(x) kept.freq_mean(x), bands, 'un', false );
dat = cell2mat( cellfun( @(x) get_data(x), meaned2, 'un', false) );
meaned2 = kept;
meaned2.data = dat;
to_stats = kept({'choice'});
to_stats = to_stats.rm( dsp2.process.format.get_bad_days() );

compare_within = { 'trialtypes', 'outcomes', 'epochs', 'drugs', 'regions' };
[I, C] = to_stats.get_indices( compare_within);

assert( numel(to_stats('permuted')) == 2 );

PS = Container();

for i = 1:numel(I)
  real_data = to_stats.keep( to_stats.where('permuted__false') & I{i} );
  null_dist = to_stats.keep( to_stats.where('permuted__true') & I{i} );
  
  ps = zeros( 1, shape(real_data, 2) );
  extr = real_data.one();
  extr( 'permuted' ) = 'permuted__false__permuted__true';
  for j = 1:shape(real_data, 2)
    [~, ps(j)] = ttest2( real_data.data(:, j), null_dist.data(:, j) );
  end
  ps = ContainerPlotter.fdr_bh( ps );
  extr.data = ps;
  PS = PS.append( extr );
end

non_permuted = to_stats.only( 'permuted__false' );
compare_within = { 'trialtypes', 'epochs', 'drugs', 'regions' };
[I, C] = non_permuted.get_indices( compare_within );

assert( numel(to_stats('outcomes')) == 2 );
adjusted_ps = Container();
sig_ind = Container();

for i = 1:numel(I)
  pro = non_permuted.keep( non_permuted.where('otherMinusNone') & I{i} );
  anti = non_permuted.keep( non_permuted.where('selfMinusBoth') & I{i} );
  
  ps = zeros( 1, shape(pro, 2) );
  extr = pro.one();
  extr( 'outcomes' ) = 'pro_v_anti';
  for j = 1:shape(pro, 2)
    [~, ps(j)] = ttest2( pro.data(:, j), anti.data(:, j) );
  end
  ps = ContainerPlotter.fdr_bh( ps );
  extr.data = ps;
  adjusted_ps = adjusted_ps.append( extr );
  
  matching_ps_ind = PS.where( C(i, :) );
  matching_data = PS.data( matching_ps_ind, : );
  below_thresh = matching_data <= .05;
  below_thresh = all( below_thresh, 1 );
  below_thresh = all( below_thresh, 1 ) & ps <= .05;
  
  sig_ind_ = extr;
  sig_ind_.data = below_thresh;
  sig_ind = sig_ind.append( sig_ind_ );
end

figure(1); clf();

pl = ContainerPlotter();
pl.compare_series = false;
pl.marker_size = 2;
pl.add_ribbon = true;
pl.add_legend = true;
pl.main_line_width = 1;
pl.x = non_permuted.frequencies;
pl.shape = [1, 2];
pl.y_lim = [-.06, .06];
pl.y_label = 'Granger difference';
% pl.x_label = 'hz';
pl.order_by = { 'real', 'permuted' };
axs = non_permuted.plot( pl, {'outcomes', 'trialtypes', 'administration'} ...
  , {'drugs', 'regions', 'epochs'} );

stp = 1;
for i = 1:numel(axs)
% for i = 1:numel(axs)  
  current_ax = axs(i);
  for j = 1:size(sig_ind.data, 2)
    if ( sig_ind.data(stp, j) )
      plot( current_ax, pl.x(j), 0.1, '*', 'markersize', 15 );
    end
  end
  stp = stp + 1;
end

if ( DO_SAVE )
  save_path = fullfile( conf.PATHS.plots, 'granger', dsp2.process.format.get_date_dir() );
  save_path = fullfile( save_path, char(to_stats('epochs')), 'lines' );
  if ( is_drug )
    save_path = fullfile( save_path, 'drug' );
  else
    save_path = fullfile( save_path, 'nondrug' );
  end
  dsp2.util.general.require_dir( save_path );
  fname = fullfile( save_path, base_fname );
  dsp2.util.general.save_fig( gcf, fname, {'fig', 'png', 'epsc'} );
end

%%  STATS -- rois

DO_SAVE = true;

plot_bands = { [4, 8], [15, 25], [30, 50] };
band_names = { 'theta', 'beta', 'gamma' };

mean_within_band = kept.rm( dsp2.process.format.get_bad_days() );
mean_within_band = mean_within_band.require_fields( 'bands' );
all_bands = Container();
for i = 1:numel(band_names)
  one_mean = mean_within_band.freq_mean( plot_bands{i} );
  one_mean( 'bands' ) = band_names{i};
  all_bands = append( all_bands, one_mean );
end

drug_only = all_bands.rm( 'unspecified' );
% plt = plt.only( {'post'} );
plt = drug_only.only( 'permuted__false' ) - drug_only.only( 'permuted__true' );
plt = plt.each1d({'drugs','bands','trialtypes','administration','regions','outcomes'}, @rowops.nanmean);
if ( is_drug )
  plt = plt({'oxytocin'}) - plt({'saline'});
end

null_orig = drug_only.only( 'permuted__true' );
null_orig = null_orig.each1d({'drugs','bands','trialtypes','administration','regions','outcomes'}, @rowops.mean);

if ( is_drug )
  null_orig = null_orig({'oxytocin'}) - null_orig({'saline'});
  plt = append( plt, null_orig );
end

figure(1); clf(); colormap( 'default' );
set( figure(1), 'units', 'normalized' );
set( figure(1), 'position', [0, 0, 1, 1] );

pl = ContainerPlotter();
pl.y_lim = [];
pl.x_tick_rotation = 0;
pl.shape = [3, 2];
pl.order_by = { 'theta_alpha', 'beta', 'gamma' };
pl.order_groups_by = { 'permuted__false_minus_permuted__true', 'permuted__true' };

plt.bar( pl, 'outcomes', {'trialtypes', 'drugs', 'permuted'}, {'bands', 'regions', 'administration'} );

f = FigureEdits( gcf );
f.one_legend();

if ( DO_SAVE )
  base_fname = dsp2.util.general.append_uniques( plt, 'rescaled', {'epochs', 'drugs', 'administration'} );
  save_path = fullfile( conf.PATHS.plots, 'granger', dsp2.process.format.get_date_dir() ...
    , char(plt('epochs')) );
  if ( is_drug )
    save_path = fullfile( save_path, 'drug', 'minus_null' );
  else
    save_path = fullfile( save_path, 'nondrug', 'minus_null' );
  end
  dsp2.util.general.require_dir( save_path );
  fname = fullfile( save_path, base_fname );
  dsp2.util.general.save_fig( gcf, fname, {'fig', 'png', 'epsc'} );
end



