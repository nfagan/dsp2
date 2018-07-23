%%  LOAD

m_within = { 'outcomes', 'trialtypes', 'regions', 'permuted', 'channels' ...
  , 'epochs', 'days', 'administration' };

is_drug = false;
use_sd_thresh = true;

if ( ~is_drug )
%   subdir = 'null';  % MAIN NON_DRUG RESULT 
%   subdir = fullfile( '121117', 'non_drug_null' ); % reward
%   subdir = fullfile( '120717', 'non_drug_null' ); % targacq
  subdir = fullfile( '071718_repl_350', 'non_drug_null' );
%   subdir = fullfile( '071618_fullfreqs', 'non_drug_null' );
%   subdir = fullfile( '071518', 'non_drug_null' );
%   subdir = fullfile( '071318', 'non_drug_null' ); % targacq, redux
%   subdir = fullfile( '121217', 'non_drug_null' ); % targon
%   subdir = 'null';
else
  subdir = 'drug_effect_null';
end

conf = dsp2.config.load();
load_p = fullfile( conf.PATHS.analyses, 'granger', subdir );

per_epoch = dsp2.analysis.granger.load_granger( load_p, 'targacq', is_drug, m_within );

%%

if ( use_sd_thresh )
  kept_sd = dsp2.analysis.granger.granger_sd_threshold( per_epoch, 1.5 );
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

%%  lines -- not minus null

kept_copy = rm( kept, dsp2.process.format.get_bad_days() );

labs = fcat.from( kept_copy.labels );
dat = kept_copy.data;
freqs = kept_copy.frequencies;

lines = { 'outcomes', 'administration', 'permuted' };
panels = { 'drugs', 'regions', 'epochs', 'trialtypes' };
lims = [ -0.03, 0.03 ];
mask = find( labs, 'choice' );

pl = plotlabeled.make_common( 'x', freqs );
pl.fig = figure(2);
% set_smoothing( pl, 5 );

axs = pl.lines( rowref(dat, mask), labs(mask), lines, panels );
shared_utils.plot.set_ylims( axs, lims );

%%  bar -- minus null

usedat = dat;
uselabs = labs';

bands = { [4, 8], [8, 13], [13, 30], [30, 60], [60, 100] };
bandnames = { 'theta', 'alpha', 'beta', 'gamma', 'high_gamma' };

[banddat, bandlabs] = dsp3.get_band_means( usedat, uselabs', freqs, bands, bandnames );

subeach = { 'drugs', 'regions', 'epochs', 'trialtypes', 'outcomes', 'administration' };
[sublabs, I] = keepeach( bandlabs', subeach );

for i = 1:numel(I)
  
  
  
end

%%  lines MINUS NULL

DO_SAVE = false;
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

%   only real data
to_stats = only( to_stats, 'permuted__false' );

fig = figure(1); clf();

set( fig, 'defaultLegendAutoUpdate', 'off');

pl = ContainerPlotter();
pl.compare_series = false;
pl.one_legend = true;
pl.marker_size = 2;
pl.add_ribbon = true;
pl.add_legend = true;
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


