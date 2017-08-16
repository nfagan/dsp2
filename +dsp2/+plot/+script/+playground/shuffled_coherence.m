%%  load .mats

save_path = fullfile( conf.PATHS.analyses, date_dir, 'signals', 'shuffled_coherence' );

coh = dsp2.util.general.load_mats( save_path );
coh = extend( coh{:} );

%%  avg

m_within = { 'outcomes', 'trialtypes', 'days', 'sites', 'regions' };
medianed = coh.parfor_each( m_within, @nanmedian );
medianed = dsp2.process.manipulations.pro_v_anti( medianed );

m_within2 = setdiff( m_within, {'days', 'sites'} );

medianed = medianed.parfor_each( m_within2, @nanmean );

%%  spectra

plt = medianed;
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

freq_roi = [ 15, 30 ];

plt = plt.freq_mean( freq_roi );

pl = ContainerPlotter();

plt.plot( pl, 'outcomes', 'trialtypes' )