%%  LOAD

conf = dsp2.config.load();
epoch = 'targacq';
load_path = fullfile( conf.PATHS.analyses, 'onslow_pac', 'cfc', epoch );
mats = dsp2.util.general.load_mats( load_path );
pac = dsp2.util.general.concat( mats );

save_path = fullfile( conf.PATHS.plots, 'onslow_pac', dsp2.process.format.get_date_dir(), epoch );
dsp2.util.general.require_dir( save_path );

%%

do_save = true;

each_plot = { 'outcomes', 'trialtypes', 'epochs', 'regions' };
append_to_fname = { 'epochs', 'trialtypes', 'regions' };
formats = { 'epsc', 'fig', 'png' };

meaned_ = pac.each1d( each_plot, @rowops.nanmean );

% meaned_ = meaned_.only( 'acc_bla' );

regions = meaned_( 'regions' );

for i = 1:numel( regions )

  meaned = meaned_.only( {'choice', regions{i}} );

  meaned = dsp2.process.manipulations.pro_v_anti( meaned );

  figure(i); clf();
  meaned.spectrogram( each_plot, 'shape', [1, 2], 'colorMap', 'default' ...
    , 'time', [0, 100], 'frequencies', [0, 100], 'clims', [-.015, .015]);

  f = FigureEdits( gcf );
  f.ylabel( 'Amplitude frequency (hz)' );
  f.xlabel( 'Phase frequency (hz)' );
  % f.clim( [0.1, 1] );

  fname = dsp2.util.general.append_uniques( meaned, 'heatmap', append_to_fname );

  if ( do_save )
    dsp2.util.general.save_fig( gcf, fullfile(save_path, fname), formats );
  end
end

%% AREA subtraction

each_plot = { 'outcomes', 'trialtypes', 'epochs', 'regions' };
append_to_fname = { 'epochs', 'trialtypes', 'regions' };
formats = { 'epsc', 'fig', 'png' };

meaned_ = pac.each1d( each_plot, @rowops.nanmean );

% meaned = meaned_.only( {'choice', regions{i}} );
meaned = meaned_({'bla_acc'}) - meaned_({'acc_bla'});

meaned = dsp2.process.manipulations.pro_v_anti( meaned );

figure(i); clf();
meaned.spectrogram( each_plot, 'shape', [1, 2], 'colorMap', 'default' ...
  , 'time', [30, 100], 'frequencies', [0, 100], 'clims', [-.006, .008]);


f = FigureEdits( gcf );
f.ylabel( 'Amplitude frequency (hz)' );
f.xlabel( 'Phase frequency (hz)' );
f.clim( [-.002, .0035] );

fname = dsp2.util.general.append_uniques( meaned, 'heatmap', append_to_fname );

% dsp2.util.general.save_fig( gcf, fullfile(save_path, fname), formats );
% dsp2.util.general.save_fig( gcf, fullfile(save_path, fname), formats );


%%

each_plot = { 'outcomes', 'trialtypes' };

meaned = pac;

% meaned = meaned.each1d( each_plot, @rowops.nanmean );
meaned = meaned.each1d( {'days', 'outcomes', 'trialtypes'}, @rowops.nanmean );

meaned = meaned.freq_mean( [30, 50] );
meaned = meaned.time_mean( [4, 8] );

meaned.data = squeeze( meaned.data );

figure(1); clf();

meaned.bar( 'outcomes', 'trialtypes', [], 'y_lim', [0, .4] );

