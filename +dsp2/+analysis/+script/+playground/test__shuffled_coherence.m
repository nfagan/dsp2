io = dsp2.io.get_dsp_h5();
P = 'Signals/none/complete/targacq';
days = io.get_days( P );

for i = 1:numel(days)
  fprintf( '\n Processing %d of %d', i, numel(days) );
  
  signals = io.read( P, 'only', days{i} );
  
  dsp2.analysis.playground.test__shuffled_coherence( signals, i );
end