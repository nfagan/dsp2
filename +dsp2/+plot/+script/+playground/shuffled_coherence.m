%%  load .mats

date_dir = datestr( now, 'mmddyy' );

load_path = fullfile( conf.PATHS.analyses, '072617', 'signals', 'shuffled_coherence' );
save_path_l = fullfile( conf.PATHS.plots, date_dir, 'lines', 'shuffled_coherence' );
save_path_s = fullfile( conf.PATHS.plots, date_dir, 'spectra', 'shuffled_coherence' );

dsp2.util.general.require_dirs( {save_path_l, save_path_s} );

coh = dsp2.util.general.load_mats( load_path );
coh = extend( coh{:} );

%%  avg

m_within = { 'outcomes', 'trialtypes', 'days', 'sites', 'regions' };
medianed = coh.parfor_each( m_within, @nanmedian );
medianed = dsp2.process.manipulations.pro_v_anti( medianed );
medianed = dsp2.process.manipulations.pro_minus_anti( medianed );

m_within2 = setdiff( m_within, {'days', 'sites'} );

meaned = medianed.parfor_each( m_within2, @nanmean );

%%  spectra

figure(1); clf();

plt = meaned;
plt = plt.rm( {'cued', 'errors'} );

plt.spectrogram( {'outcomes', 'trialtypes', 'monkeys'} ...
  , 'frequencies', [0, 100] ...
  , 'time', [-350, 300] ...
  , 'clims', [-.01 .01] ...
  , 'shape', [1, 2] ...
);

kind = 'pro_minus_anti';

fname = dsp2.util.general.append_uniques( plt, kind, {'epochs'} );
fname = fullfile( save_path_s, fname );

dsp2.util.general.save_fig( gcf, fname, {'fig', 'png', 'epsc'} );

%%  lines

plt = medianed;
plt = plt.rm( {'cued', 'errors'} );

time_roi = [ -200, 0 ];

plt = plt.time_mean( time_roi );
plt.data = squeeze( plt.data );

figure(1); clf();

pl = ContainerPlotter();
pl.add_ribbon = true;
pl.x = plt.frequencies;
pl.compare_series = true;

plt.plot( pl, 'outcomes', {'trialtypes', 'epochs'} );

fname = 'pro_anti_lines';
fname = dsp2.util.general.append_uniques( plt, fname, {'epochs'} );
fname = fullfile( save_path_l, fname );

dsp2.util.general.save_fig( gcf, fname, {'fig', 'png', 'epsc'} );

% saveas( gcf, 'pro_anti', 'fig' );
% saveas( gcf, 'pro_anti', 'eps' );

