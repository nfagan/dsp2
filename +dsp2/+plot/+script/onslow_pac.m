%%  LOAD

conf = dsp2.config.load();
epoch = 'targacq';
load_path = fullfile( conf.PATHS.analyses, 'onslow_pac', 'cfc', epoch );
mats = dsp2.util.general.load_mats( load_path );
pac = dsp2.util.general.concat( mats );

base_save_path = fullfile( conf.PATHS.plots, 'onslow_pac', dsp2.process.format.get_date_dir() );
save_path = fullfile( base_save_path, epoch );
dsp2.util.general.require_dir( save_path );

%%

do_save = true;

each_plot = { 'outcomes', 'trialtypes', 'epochs', 'regions' };
append_to_fname = { 'epochs', 'trialtypes', 'regions' };
formats = { 'epsc', 'fig', 'png' };

meaned_ = pac.each1d( each_plot, @rowops.nanmean );

% meaned_ = meaned_.only( 'acc_bla' );

regions = meaned_( 'regions' );

% meaned_ = meaned_.only( 'cued' );

for i = 1:numel( regions )

%   meaned = meaned_.only( {'choice', regions{i}} );
  meaned = meaned_.only( regions{i} );

  meaned = dsp2.process.manipulations.pro_v_anti( meaned );

  figure(i); clf();
  meaned.spectrogram( each_plot, 'shape', [1, 2], 'colorMap', 'default' ...
    , 'time', [0, 30], 'frequencies', [0, 100], 'clims', [-.015, .015]);

  f = FigureEdits( gcf );
  f.ylabel( 'Amplitude frequency (hz)' );
  f.xlabel( 'Phase frequency (hz)' );
  % f.clim( [0.1, 1] );

  fname = dsp2.util.general.append_uniques( meaned, 'heatmap', append_to_fname );

  if ( do_save )
    dsp2.util.general.save_fig( gcf, fullfile(save_path, fname), formats );
  end
end

%%  BAR plot

phase_rois = { [1, 20] };
amp_rois = { [1, 20], [55, 85] };

cmbs = dsp2.util.general.allcomb( {phase_rois, amp_rois } );

bands = Container();

for i = 1:size(cmbs, 1)
  
  phase_roi = cmbs{i, 1};
  amp_roi = cmbs{i, 2};
  
  meaned = pac.time_freq_mean( phase_roi, amp_roi );
  meaned = meaned.require_fields( {'phase_freq', 'amp_freq'} );
  meaned( 'phase_freq' ) = sprintf( '%d-%dhz (phase)', phase_roi(1), phase_roi(2) );
  meaned( 'amp_freq' ) = sprintf( '%d-%dhz (amp)', amp_roi(1), amp_roi(2) );
  
  bands = bands.append( meaned );
  
end

proanti = dsp2.process.manipulations.pro_v_anti( bands );
%%

fname = sprintf( 'choice_cued_targacq_targon_1_20' );

plt = proanti;
figure(1); clf();
plt.bar( 'regions', {'trialtypes'}, {'phase_freq', 'amp_freq', 'outcomes'} );

dsp2.util.general.save_fig( gcf, fullfile(base_save_path, 'combined', fname), {'epsc', 'fig', 'png'} );

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

