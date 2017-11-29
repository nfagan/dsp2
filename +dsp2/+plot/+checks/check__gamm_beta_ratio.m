conf = dsp2.config.load();

meas = 'coherence';
epoch = 'targon';
manip = 'standard';
clpse = { 'trials', 'monkeys' };
kind = 'nanmedian_2';

coh = dsp2.io.get_processed_measure( {meas, epoch, manip, clpse}, kind );

meaned = coh.each1d( {'days', 'sites', 'outcomes', 'administration'}, @rowops.nanmean );

date_dir = dsp2.process.format.get_date_dir();
save_p = fullfile( conf.PATHS.plots, 'gamma_beta_ratio', date_dir, manip );
% save_p = fullfile( conf.PATHS.plots, 'behavior', 'coherence_preference_over_trials', date_dir, 'drug' );

%%  ratio
% time_roi = [ -250, 0 ];
time_roi = [ 50, 250 ];
freq_rois = { [15, 30], [45, 60] };
% freq_rois = { [15, 25], [30, 45] };
band_names = { 'beta', 'gamma' };

freq_meaned = Container();

for i = 1:numel(freq_rois)
  freq_meaned_one = meaned.time_freq_mean( time_roi, freq_rois{i} );
  freq_meaned_one = freq_meaned_one.require_fields( 'bands' );
  freq_meaned_one( 'bands' ) = band_names{i};
  freq_meaned = freq_meaned.append( freq_meaned_one );
end

ratio = freq_meaned.only( 'gamma' ) ./ freq_meaned.only( 'beta' );
% ratio = freq_meaned.only( 'gamma' );
% ratio = freq_meaned;

% ratio.data = 10 .* log10( ratio.data );

% ratio.data = 10 * log10( ratio.data );


%%  plot

DO_SAVE = true;

pl = ContainerPlotter();
figure(1); clf();

pl.x_tick_rotation = 0;
pl.y_lim = [];
pl.order_by = { 'self', 'both', 'other', 'none' };

h = ratio.bar( pl, 'outcomes', {'administration'}, {'epochs', 'drugs', 'bands'} );

set( h, 'YScale','log' );
set( h, 'ylim', [.94, .96] );

if ( DO_SAVE )
  fname = sprintf( 'coherence_ratio_%s', epoch );
  dsp2.util.general.require_dir( save_p );
  dsp2.util.general.save_fig( gcf(), fullfile(save_p, fname), {'epsc', 'fig', 'png'} );
end

%%  plot log scale


means = ratio.each1d( {'outcomes'}, @rowops.nanmean );
devs = ratio.each1d( {'outcomes'}, @rowops.sem );

mean_array = [get_data(means({'self'})), get_data(means({'both'})), get_data(means({'other'})), get_data(means({'none'}))];
dev_array = [get_data(devs({'self'})), get_data(devs({'both'})), get_data(devs({'other'})), get_data(devs({'none'}))];

figure(1); clf();
semilogy( 1:numel(mean_array), mean_array );
hold on;
semilogy( 1:numel(mean_array), mean_array-dev_array, 'k' );
semilogy( 1:numel(mean_array), mean_array+dev_array, 'k' );



