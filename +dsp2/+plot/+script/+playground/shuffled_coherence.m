%%  load .mats

date_dir = datestr( now, 'mmddyy' );

load_path = fullfile( conf.PATHS.analyses, '072617', 'signals', 'shuffled_coherence' );
save_path = fullfile( conf.PATHS.plots, date_dir, 'lines', 'shuffled_coherence' );

dsp2.util.general.require_dir( save_path );

coh = dsp2.util.general.load_mats( load_path );
coh = extend( coh{:} );

%%  avg

m_within = { 'outcomes', 'trialtypes', 'days', 'sites', 'regions' };
medianed = coh.parfor_each( m_within, @nanmedian );
medianed = dsp2.process.manipulations.pro_v_anti( medianed );

m_within2 = setdiff( m_within, {'days', 'sites'} );

meaned = medianed.parfor_each( m_within2, @nanmean );

%%  spectra

plt = meaned;
plt = plt.rm( {'cued', 'errors'} );

plt.spectrogram( {'outcomes', 'trialtypes', 'monkeys'} ...
  , 'frequencies', [0, 100] ...
  , 'time', [-350, 300] ...
  , 'clims', [-.01 .01] ...
  , 'shape', [1, 2] ...
);

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

fname = fullfile( save_path, 'pro_anti_lines' );

dsp2.util.general.save_fig( gcf, fname, {'fig', 'png', 'epsc'} );

% saveas( gcf, 'pro_anti', 'fig' );
% saveas( gcf, 'pro_anti', 'eps' );

