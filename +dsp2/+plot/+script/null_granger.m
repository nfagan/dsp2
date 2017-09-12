%%  LOAD

import dsp2.util.general.percell;
import dsp2.util.general.flatten;
import dsp2.util.general.load_mats;

m_within = { 'outcomes', 'trialtypes', 'regions', 'permuted', 'channels' ...
  , 'epochs', 'days' };

conf = dsp2.config.load();
load_p = fullfile( conf.PATHS.analyses, 'granger', 'null' );
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
    current = current.for_each_1d( m_within, @Container.nanmean_1d );
    loaded{k} = current;
  end
  per_epoch{i} = loaded;
end

per_epoch = flatten( per_epoch );

per_epoch = per_epoch.add_field( 'max_lags', '5e3' );

%%  MAKE PRO V ANTI

proanti = per_epoch;
% proanti = dsp2.process.manipulations.pro_v_anti( proanti );

%%  PLOT

scale_name = 'rescaled';
base_fname = sprintf( '%s_%s', strjoin(meaned('epochs'), '_'), scale_name );

meaned = dsp2.process.manipulations.pro_v_anti( kept2.keep_within_freqs( [0, 100] ) );
% meaned = meaned.only( {'targOn', 'cued'} );
% meaned = meaned.except( {'targOn', 'choice'} );
% meaned = meaned.replace( {'targOn', 'targAcq'}, 'choice+cue' );
% meaned = meaned.rm( 'permuted__true' );

pl = ContainerPlotter();
pl.compare_series = false;
pl.marker_size = 2;
pl.add_ribbon = true;
pl.main_line_width = 1;
pl.x = meaned.frequencies;
pl.shape = [2, 2];
pl.y_lim = [-.02, .02];
pl.y_label = 'Granger difference';
pl.x_label = 'hz';
pl.order_by = { 'real', 'permuted' };

figure(1); clf();

meaned.plot( pl, {'permuted', 'trialtypes', 'max_lags'}, {'regions', 'outcomes', 'epochs'} );

save_path = fullfile( conf.PATHS.plots, dsp2.process.format.get_date_dir(), 'granger' );
dsp2.util.general.require_dir( save_path );
fname = fullfile( save_path, base_fname );
dsp2.util.general.save_fig( figure(1), fname, {'fig', 'png', 'epsc'} );

%%  keep within n deviations

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
band_mean_within = { 'band', 'outcomes', 'trialtypes' };

means = band_means.for_each_1d( band_mean_within, mean_func );
devs = band_means.for_each_1d( band_mean_within, std_func );

devs.data = devs.data * ndevs;

up_thresh = means + devs;
down_thresh = means - devs;

to_keep = band_means.logic( false );

within = { 'band', 'outcomes', 'trialtypes' };
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

check_sites_within = { 'outcomes', 'trialtypes', 'days', 'channels', 'regions' };

kept_cmbs = kept.pcombs( check_sites_within );
orig_cmbs = proanti.pcombs( check_sites_within );

kept_cmbs = dsp2.util.general.array_join( kept_cmbs );
orig_cmbs = dsp2.util.general.array_join( orig_cmbs );

missing = setdiff( orig_cmbs, kept_cmbs );

require_per = { 'days', 'channels', 'regions', 'permuted' };
required_labs = proanti.pcombs( {'outcomes', 'trialtypes'} );

kept2 = dsp2.util.general.require_labels( kept, require_per, required_labs );

%%  PLOT PER DAY AND SAVE

save_path = fullfile( conf.PATHS.plots, dsp2.process.format.get_date_dir(), 'granger' );

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