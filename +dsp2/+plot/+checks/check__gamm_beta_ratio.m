conf = dsp2.config.load();

meas = 'coherence';
epochs = { 'targacq', 'targon', 'reward' };
manips = { 'drug_post_v_pre' };
clpses = { {'trials', 'monkeys'} };
kind = 'nanmedian_2';
is_pro_v_antis = { false, true };
is_post_minus_pres = { true };
is_new_data_sets = { false, true };

C = allcomb( {epochs, clpses, manips, is_pro_v_antis, is_post_minus_pres} );

for idx = 1:size(C, 1)

fprintf( '\n\t %d of %d', idx, size(C, 1) );
  
epoch = C{idx, 1};
clpse = C{idx, 2};
manip = C{idx, 3};
is_pro_v_anti = C{idx, 4};
is_post_minus_pre = C{idx, 5};

is_drug = false;

if ( ~isempty(strfind(manip, 'drug')) )
  is_drug = true;
end

coh = dsp2.io.get_processed_measure( {meas, epoch, manip, clpse}, kind );

% coh = coh.only( 'cued' );

if ( isempty(coh) ), continue; end

meaned = coh.each1d( {'days', 'sites', 'outcomes', 'administration', 'trialtypes'}, @rowops.nanmean );

date_dir = dsp2.process.format.get_date_dir();
save_p = fullfile( conf.PATHS.plots, 'gamma_beta_ratio', date_dir, manip );
% save_p = fullfile( conf.PATHS.plots, 'behavior', 'coherence_preference_over_trials', date_dir, 'drug' );

%%%  ratio

if ( strcmp(epoch, 'reward') )
  time_roi = [ 50, 250 ];
elseif ( strcmp(epoch, 'targacq') )
  time_roi = [ -200, 0 ];
elseif ( strcmp(epoch, 'targon') )
  time_roi = [ 0, 200 ];
else
  error( 'Unrecognized epoch ''%s''.', epoch );
end

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

if ( is_pro_v_anti )
  ratio = dsp2.process.manipulations.pro_v_anti( ratio );
end

if ( is_drug && is_post_minus_pre )
  ratio = dsp2.process.manipulations.post_minus_pre( ratio );
end

% ratio = freq_meaned.only( 'gamma' );
% ratio = freq_meaned;

% ratio.data = 10 .* log10( ratio.data );

% ratio.data = 10 * log10( ratio.data );


%%%  plot

DO_SAVE = true;

pl = ContainerPlotter();
figure(1); clf(); colormap( 'default' );

pl.x_tick_rotation = 0;
pl.y_lim = [];

if ( is_pro_v_anti )
  pl.order_by = { 'otherMinusNone', 'selfMinusBoth' };
else
  pl.order_by = { 'self', 'both', 'other', 'none' };
end

if ( ~is_pro_v_anti && ~is_post_minus_pre )
  panels_are = { 'epochs', 'drugs', 'bands', 'trialtypes', 'monkeys', 'administration' };
else
  panels_are = { 'epochs', 'bands', 'trialtypes', 'monkeys', 'administration' };
end

plt = ratio;

if ( is_drug )
  plt = plt.rm( 'unspecified' );
end

% plt = plt.collapse( 'monkeys' );

if ( ~is_pro_v_anti && ~is_post_minus_pre )
  h = plt.bar( pl, 'outcomes', {'administration'}, panels_are );
else
  h = plt.bar( pl, 'outcomes', {'drugs'}, panels_are );
end

if ( ~is_pro_v_anti && ~is_post_minus_pre )
  set( h, 'YScale','log' );
%   set( h, 'ylim', [.92, .99] );
  set( h, 'ylim', [0.938, 0.96] );
end

if ( DO_SAVE )
  filenames_are = union( panels_are, {'outcomes'} );
  fname = sprintf( 'coherence_ratio_%s', epoch );
  fname = dsp2.util.general.append_uniques( plt, fname, filenames_are );
  dsp2.util.general.require_dir( save_p );
  dsp2.util.general.save_fig( gcf(), fullfile(save_p, fname), {'epsc', 'fig', 'png'} );
end

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



