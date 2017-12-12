%%  LOAD

import dsp2.util.general.percell;
import dsp2.util.general.flatten;
import dsp2.util.general.load_mats;

m_within = { 'outcomes', 'trialtypes', 'regions', 'permuted', 'channels' ...
  , 'epochs', 'days', 'administration' };

COLLAPSE_DRUGS = true;

DO_SAVE = false;

if ( COLLAPSE_DRUGS )
%   subdir = 'null';
  subdir = fullfile( '121117', 'non_drug_null' );
else
  subdir = 'drug_effect_null';
end
conf = dsp2.config.load();
load_p = fullfile( conf.PATHS.analyses, 'granger', subdir );
% epochs = dsp2.util.general.dirnames( load_p, 'folders' );
epochs = { 'reward' };
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
    if ( COLLAPSE_DRUGS )
      current = current.collapse( {'drugs', 'administration'} );
    end
    current = current.for_each_1d( m_within, @Container.nanmean_1d );
    loaded{k} = current;
  end
  per_epoch{i} = loaded;
end

per_epoch = flatten( per_epoch );

per_epoch = per_epoch.add_field( 'max_lags', '5e3' );

%%  keep within n deviations

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

means = band_means.for_each_1d( band_mean_within, mean_func );
devs = band_means.for_each_1d( band_mean_within, std_func );

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

kept2 = dsp2.util.general.require_labels( kept, require_per, required_labs );

%%  MAKE PRO V ANTI

% proanti = kept2.keep_within_freqs( [0, 100] );
proanti = per_epoch.keep_within_freqs( [0, 100] );

% proanti = per_epoch.keep_within_freqs( [0, 100] );
proanti = dsp2.process.manipulations.pro_v_anti( proanti );
proanti = proanti.collapse( {'sessions','blocks','recipients','magnitudes'} );
proanti = dsp2.process.manipulations.post_minus_pre( proanti );

%%
proanti = per_epoch;
proanti = dsp2.process.manipulations.pro_v_anti( proanti );
% proanti = proanti.each1d( {'drugs', 'outcomes', 'regions', 'permuted', 'administration'}, @rowops.nanmean );
% subbed = dsp2.process.manipulations.oxy_minus_sal( proanti );
subbed = proanti;

subbed = subbed.only( {'permuted__false', 'post', 'oxytocin', 'saline'} );

subbed = subbed.keep_within_freqs( [0, 100] );

pl = ContainerPlotter();
pl.x = subbed.frequencies;
pl.add_ribbon = true;

figure(1); clf();

subbed.plot( pl, {'drugs'}, {'administration', 'outcomes', 'regions'} );

%%  MAKE POST - PRE

% proanti = kept2.keep_within_freqs( [0, 100] );
proanti = per_epoch.keep_within_freqs( [0, 100] );
proanti = proanti.collapse( {'blocks', 'sessions'} );
proanti = dsp2.process.manipulations.post_minus_pre( proanti );
proanti = dsp2.process.manipulations.pro_v_anti( proanti );

proanti = proanti.rm( {'day__05172016', 'day__05192016' 'day__02142017', 'day__06022017' } );

%%  MAKE POST ONLY

proanti = per_epoch.keep_within_freqs( [0, 100] );
proanti = dsp2.process.manipulations.pro_v_anti( proanti );
proanti = proanti.only( 'post' );
proanti = proanti.rm( {'day__05172016', 'day__05192016' 'day__02142017', 'day__06022017' } );

%%  STATS - across outcomes

to_stats = proanti;
compare_within = { 'trialtypes', 'epochs', 'drugs', 'regions' };
[I, C] = to_stats.get_indices( compare_within);

assert( numel(to_stats('outcomes')) == 2 );

PS = Container();

for i = 1:numel(I)
  pro = to_stats.keep( to_stats.where('otherMinusNone') & I{i} );
  anti = to_stats.keep( to_stats.where('selfMinusBoth') & I{i} );
  
  ps = zeros( 1, shape(pro, 2) );
  extr = pro.one();
  extr( 'outcomes' ) = 'pro_v_anti';
  for j = 1:shape(pro, 2)
    [~, ps(j)] = ttest2( pro.data(:, j), anti.data(:, j) );
  end
  ps = ContainerPlotter.fdr_bh( ps );
  extr.data = ps;
  PS = PS.append( extr );
end

%%  STATS - first test null

meaned2 = cellfun( @(x) proanti.freq_mean(x), bands, 'un', false );
dat = cell2mat( cellfun( @(x) get_data(x), meaned2, 'un', false) );
meaned2 = proanti;
meaned2.data = dat;

thresh = any( meaned2.data < -.5 | meaned2.data > .5, 2 );

% to_stats = proanti.rm( {'day__02142017', 'day__02132017'} );
% to_stats = proanti.keep( ~thresh );
to_stats = proanti;

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
[I, C] = non_permuted.get_indices( compare_within);

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
pl.y_lim = [-.03, .03];
pl.y_label = 'Granger difference';
% pl.x_label = 'hz';
pl.order_by = { 'real', 'permuted' };
axs = non_permuted.plot( pl, {'outcomes', 'trialtypes', 'administration'}, {'drugs', 'regions'} );

stp = 1;
for i = 1:numel(axs)
% for i = 1:numel(axs)  
  current_ax = axs(i);
  for j = 1:size(sig_ind.data, 2)
    if ( sig_ind.data(stp, j) )
      plot( current_ax, pl.x(j), 0.02, '*', 'markersize', 15 );
    end
  end
  stp = stp + 1;
end

if ( DO_SAVE )
  save_path = fullfile( conf.PATHS.plots, 'granger', dsp2.process.format.get_date_dir() );
  dsp2.util.general.require_dir( save_path );
  fname = fullfile( save_path, base_fname );
  dsp2.util.general.save_fig( figure(1), fname, {'fig', 'png', 'epsc'} );
end

%%  PLOT
% meaned = proanti.only( 'saline' );
% meaned = proanti.only( {'oxytocin', 'post'} );
% meaned = proanti.rm( 'unspecified' );
% meaned = proanti.keep( ~thresh );
% meaned = meaned.rm( 'permuted__true' );
% meaned = proanti.keep( ~bad_site_ind );
% meaned = proanti.only_not( {'day__02142017', 'otherMinusNone'} );

meaned = proanti.rm( 'unspecified' );
% meaned = proanti.keep( ~bad_site_ind );
% meaned = meaned.only( {'saline', 'post'} );

% meaned = orig_dev_thresholded.only( {'oxytocin', 'post'} );

% meaned = meaned.rm( {'day__02142017', 'iteration__101', 'oth );
% meaned = meaned.only_not( b.flat_uniques({'outcomes', 'days', 'trialtypes'}) );

scale_name = 'rescaled_pre';
% dat = meaned.data;
% 
% for i = 1:size(meaned.data, 1)
%   dat(i, :) = smooth( dat(i, :), 30 );
% end
% meaned.data = dat;

base_fname = dsp2.util.general.append_uniques( meaned, 'rescaled', {'epochs', 'drugs', 'administration'} );

% meaned = meaned.keep_within_freqs( [4, 12] );

pl = ContainerPlotter();
pl.compare_series = true;
pl.marker_size = 2;
pl.add_ribbon = true;
pl.add_legend = true;
pl.main_line_width = 1;
pl.x = meaned.frequencies;
pl.shape = [4, 2];
pl.y_lim = [];
pl.y_label = 'Grnger difference';
% pl.x_label = 'hz';
pl.order_by = { 'real', 'permuted' };

figure(2); clf();

meaned.plot( pl, {'permuted', 'trialtypes', 'administration'}, {'outcomes', 'drugs', 'regions'} );
% meaned.plot( pl, {'outcomes', 'trialtypes', 'administration'}, {'drugs', 'regions'} );

f = FigureEdits( gcf );
f.one_legend();

if ( DO_SAVE )
  save_path = fullfile( conf.PATHS.plots, 'granger', dsp2.process.format.get_date_dir() ...
    , char(meaned('epochs')), 'drug', 'smoothed');
  dsp2.util.general.require_dir( save_path );
  fname = fullfile( save_path, base_fname );
  dsp2.util.general.save_fig( figure(1), fname, {'fig', 'png', 'epsc'} );
end

%%

meaned = proanti.rm( 'unspecified' );
meaned = meaned.freq_mean( [35, 50] );


figure(1); clf(); 
meaned.hist( 100, [], {'outcomes', 'regions'} );

%%  PLOT PER DAY AND SAVE

save_path = fullfile( conf.PATHS.plots, 'granger', dsp2.process.format.get_date_dir() );

meaned = proanti.keep_within_freqs( [0, 100] );
meaned = meaned.replace( {'targOn', 'targAcq'}, 'choice+cue' );
meaned = meaned.rm( 'permuted__true' );

days = meaned( 'days' );

for i = 1:numel(days)
  
  extr = meaned.only( days{i} );

  pl = ContainerPlotter();
  pl.add_legend = false;
  pl.add_ribbon = true;
  pl.main_line_width = 1;
  pl.x = extr.frequencies;
  pl.shape = [4, 2];
  pl.y_lim = [];
  pl.y_label = 'Granger difference';
  pl.x_label = 'hz';
  pl.order_by = { 'real', 'permuted' };

  figure(1); clf();

  extr.plot( pl, {'permuted', 'trialtypes', 'max_lags'}, {'regions', 'outcomes', 'epochs', 'days'} );
  
  dsp2.util.general.save_fig( gcf, fullfile(save_path, days{i}), {'png'} );

end

%%  IDENTIFY BAD SITES

bad_thresh = 2;
meaned2 = cellfun( @(x) proanti.freq_mean(x), bands, 'un', false );
dat = cell2mat( cellfun( @(x) get_data(x), meaned2, 'un', false) );
meaned2 = proanti;
meaned2.data = dat;
thresh = any( meaned2.data < -bad_thresh | meaned2.data > bad_thresh, 2 );

bad_data = proanti( thresh );
bad_sites = bad_data.pcombs( {'days', 'channels', 'sites'} );

bad_site_ind = proanti.logic( false );
for i = 1:size( bad_sites, 1 )
  bad_site_ind  = bad_site_ind  | proanti.where( bad_sites(i, :) );
end

%%  STATS -- rois

DO_SAVE = true;

plot_bands = { [4, 8], [15, 25], [30, 50] };
band_names = { 'theta', 'beta', 'gamma' };

% mean_within_band = proanti.only_not( {'day__02142017'} );
mean_within_band = proanti;
% mean_within_band = proanti.keep( ~bad_site_ind );
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
plt = plt.each1d({'drugs','bands','trialtypes','administration','regions','outcomes'},@rowops.nanmean);
plt = plt({'oxytocin'}) - plt({'saline'});

null_orig = drug_only.only( 'permuted__true' );
null_orig = null_orig.each1d({'drugs','bands','trialtypes','administration','regions','outcomes'},@rowops.mean);
null_orig = null_orig({'oxytocin'}) - null_orig({'saline'});
plt = append( plt, null_orig );

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
    , char(plt('epochs')), 'drug', 'minus_null' );
  dsp2.util.general.require_dir( save_path );
  fname = fullfile( save_path, base_fname );
  dsp2.util.general.save_fig( gcf, fname, {'fig', 'png', 'epsc'} );
end

%%

stats_for_each = { 'bands', 'regions' };
C = all_bands.pcombs( stats_for_each );
all_stats = Container();
for i = 1:size(C, 1)
  pro = all_bands.only( [C(i ,:), 'otherMinusNone'] );
  anti = all_bands.only( [C(i, :), 'selfMinusBoth'] );
  assert( ~isempty(pro) && ~isempty(anti) );
  
  [~, p] = ttest2( pro.data, anti.data );
  all_stats = all_stats.append( set_data(one(pro), p) );
end

if ( DO_SAVE )
  base_fname = dsp2.util.general.append_uniques( all_bands, 'rescaled', {'epochs', 'drugs', 'administration'} );
  save_path = fullfile( conf.PATHS.plots, 'granger', dsp2.process.format.get_date_dir() );
  dsp2.util.general.require_dir( save_path );
  fname = fullfile( save_path, base_fname );
  writetable( all_stats.table(), [fname, '.csv'], 'WriteVariableNames', true, 'WriteRowNames', true );
end
