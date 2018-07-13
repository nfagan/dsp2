%%  LOAD

import dsp2.util.general.percell;
import dsp2.util.general.flatten;
import dsp2.util.general.load_mats;

m_within = { 'outcomes', 'trialtypes', 'regions', 'permuted', 'channels' ...
  , 'epochs', 'days', 'administration' };

is_drug = false;
DO_SAVE = false;
use_sd_thresh = true;

if ( ~is_drug )
%   subdir = 'null';
%   subdir = fullfile( '121117', 'non_drug_null' ); % reward
  subdir = fullfile( '120717', 'non_drug_null' ); % targacq
%   subdir = fullfile( '071318', 'non_drug_null' ); % targacq, redux
%   subdir = fullfile( '121217', 'non_drug_null' ); % targon
%   subdir = 'null';
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
    
%     if ( ~contains(newer, current('days')) )
%       loaded{k} = SignalContainer( Container() );
%     end
  end
  per_epoch{i} = loaded;
end

per_epoch = flatten( per_epoch );

per_epoch = per_epoch.add_field( 'max_lags', '5e3' );

if ( is_drug )
  per_epoch = per_epoch.rm( 'unspecified' );
end

%%

if ( use_sd_thresh )

  proanti = per_epoch;

  ndevs = 1.5;

  bands = { [4, 8], [8, 13], [13, 30], [30, 60], [60, 100] };
  band_names = { 'theta', 'alpha', 'beta', 'gamma', 'high_gamma' };

  band_means = Container();

  for i = 1:numel(bands)
    meaned = proanti.freq_mean( bands{i} );
    meaned = meaned.add_field( 'band', band_names{i} );
    band_means = band_means.append( meaned );
  end

  mean_func = @Container.nanmean_1d;
  std_func = @Container.nanstd_1d;
  band_mean_within = { 'band', 'outcomes', 'trialtypes', 'drugs', 'administration' };

  means = band_means.each1d( band_mean_within, mean_func );
  devs = band_means.each1d( band_mean_within, std_func );

  devs.data = devs.data * ndevs;

  up_thresh = means + devs;
  down_thresh = means - devs;

  to_keep = band_means.logic( false );

  within = { 'band', 'outcomes', 'trialtypes', 'drugs', 'administration' };
  cmbs = band_means.pcombs( within );

  band_means_data = band_means.data;
  d_thresh_data = down_thresh.data;
  u_thresh_data = up_thresh.data;

  for i = 1:size(cmbs, 1 )
    current_band_data_index = band_means.where( cmbs(i, :) );
    current_band_u_thresh_index = up_thresh.where( cmbs(i, :) );
    current_band_l_thresh_index = down_thresh.where( cmbs(i, :) );
    good_data = band_means_data(current_band_data_index) > d_thresh_data(current_band_l_thresh_index) & ...
      band_means_data(current_band_data_index) < u_thresh_data(current_band_u_thresh_index);
    to_keep(current_band_data_index) = good_data;
  end

  all_keep = true( size(to_keep, 1) / numel(bands), 1 );

  for i = 1:numel(bands)
    all_keep = all_keep & to_keep(band_means.where(band_names{i}));
  end

  kept = proanti.keep( all_keep );

  check_sites_within = { 'outcomes', 'trialtypes', 'days', 'channels', 'regions', 'administration' };

  kept_cmbs = kept.pcombs( check_sites_within );
  orig_cmbs = proanti.pcombs( check_sites_within );

  kept_cmbs = dsp2.util.general.array_join( kept_cmbs );
  orig_cmbs = dsp2.util.general.array_join( orig_cmbs );

  missing = setdiff( orig_cmbs, kept_cmbs );

  require_per = { 'days', 'channels', 'regions', 'permuted' };
  required_labs = proanti.pcombs( {'outcomes', 'trialtypes', 'administration'} );

  kept_sd = dsp2.util.general.require_labels( kept, require_per, required_labs );
  
end

%%  MAKE PRO V ANTI

if ( use_sd_thresh )
  kept = kept_sd;
else
  kept = per_epoch;
end

kept = kept.keep_within_freqs( [0, 100] );
kept = dsp2.process.manipulations.pro_v_anti( kept );

kept = kept.collapse( {'sessions','blocks','recipients','magnitudes'} );
if ( is_drug )
  kept = dsp2.process.manipulations.post_minus_pre( kept );
end

%%  lines MINUS NULL

DO_SAVE = true;
subtract_null = false;
base_fname = 'no_bad_days';

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

figure(2); clf();

pl = ContainerPlotter();
pl.compare_series = false;
pl.marker_size = 2;
pl.add_ribbon = true;
pl.add_legend = false;
pl.main_line_width = 1;
pl.x = non_permuted.frequencies;
pl.shape = [1, 2];
pl.y_lim = [-.03, .03];
pl.y_label = 'Granger difference';
% pl.x_label = 'hz';
pl.order_by = { 'real', 'permuted' };
axs = to_stats.plot( pl, {'outcomes', 'trialtypes', 'administration', 'permuted'} ...
  , {'drugs', 'regions', 'epochs'} );

stp = 1;
for i = 1:numel(axs)
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
  if ( use_sd_thresh )
    save_path = fullfile( save_path, sprintf('sd_threshold_%0.2f', ndevs) );
  else
    save_path = fullfile( save_path, 'no_threshold' );
  end
  if ( is_drug )
    save_path = fullfile( save_path, 'drug' );
  else
    save_path = fullfile( save_path, 'nondrug' );
  end
  dsp2.util.general.require_dir( save_path );
  fname = fullfile( save_path, base_fname );
  dsp2.util.general.save_fig( gcf, fname, {'fig', 'png', 'epsc'} );
end

%%  BAR -- minus null

if ( ~use_sd_thresh )

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

  
end


