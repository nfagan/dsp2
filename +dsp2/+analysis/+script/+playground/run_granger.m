%%  load
io = dsp2.io.get_dsp_h5();
P = dsp2.io.get_path( 'signals', 'complete', 'reward' );
days = io.get_days( P );
day = days{end};
signals = io.read( P, 'only', day );

%%  get one channel per region

signals_ = signals.only( {'bla', 'acc'} );
per_channel = signals_.enumerate( 'regions' );
chans = cellfun( @(x) x('channels'), per_channel, 'un', false );
for i = 1:numel(chans)
  per_channel{i} = per_channel{i}.only( chans{i}(1:2) );
end

signals_ = extend( per_channel{:} );

%%  get granger

import dsp2.analysis.playground.*;

signals_.data = signals_.data(:, 1:300);
[granger, fitted, freqs, ids, C] = permuted_granger( signals_, 'regions', 100, 2 );

%%  plot

dsp2.plot.playground.plot_granger( granger, fitted, freqs, ids, C );