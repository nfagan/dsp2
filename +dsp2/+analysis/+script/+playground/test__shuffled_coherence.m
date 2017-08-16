%%  load signals
io = dsp2.io.get_dsp_h5();
epoch = 'reward';
P = io.fullfile( 'Signals/none/complete/', epoch );
signals = io.read( P );
conf = dsp2.config.load();
date_dir = datestr( now, 'mmddyy' );
save_path = fullfile( conf.PATHS.analyses, datedir, 'signals', 'shuffled_coherence' );

%%  coh for each day

days = signals( 'days' );
for i = 1:numel(days)
  fprintf( '\n Processing ''%s'' (%d of %d)', days{i}, i, numel(days) );
  signal = only( signals, days{i} );
  dsp2.analysis.playground.test__shuffled_coherence( signal, i, save_path );
end

%%  load .mats

coh = dsp2.util.general.load_mats( save_path );
coh = extend( coh{:} );

%%  avg

m_within = { 'outcomes', 'trialtypes', 'days', 'sites', 'regions' };
medianed = coh.parfor_each( m_within, @nanmedian );
medianed = dsp2.process.manipulations.pro_v_anti( medianed );

m_within2 = setdiff( m_within, {'days', 'sites'} );

medianed = medianed.parfor_each( m_within2, @nanmean );

%%

plt = medianed;
plt = plt.rm( {'cued', 'errors'} );

plt.spectrogram( {'outcomes', 'trialtypes', 'monkeys'} ...
  , 'frequencies', [0, 100] ...
  , 'time', [-350, 300] ...
  , 'clims', [-.01 .01] ...
  , 'shape', [1, 2] ...
);