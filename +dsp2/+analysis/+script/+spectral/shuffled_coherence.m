%%  load signals
io = dsp2.io.get_dsp_h5();
epoch = 'targon';
P = io.fullfile( 'Signals/none/complete/', epoch );
signals = io.read( P );
conf = dsp2.config.load();
date_dir = datestr( now, 'mmddyy' );
save_path = fullfile( conf.PATHS.analyses, date_dir, 'signals', 'shuffled_coherence' );
dsp2.util.general.require_dir( save_path );

%%  coh for each day

days = signals( 'days' );
N = numel( days );
for i = 1:numel(days)
  signal = only( signals, days{i} );
  dsp2.analysis.playground.test__shuffled_coherence( signal, i, save_path );
end