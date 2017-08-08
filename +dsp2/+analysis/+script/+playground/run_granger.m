%%  load
io = dsp2.io.get_dsp_h5();
P = 'Signals/none/complete/targacq/';
days = io.get_days( P );
day = days{end};
signals = io.read( P, 'only', day );

%%  get one channel per region

signals = update_min( update_max(signals) );
signals_ = dsp2.process.reference.reference_subtract_within_day( signals );
% signals_ = signals.only( {'bla', 'acc'} );
per_channel = signals_.enumerate( 'regions' );
chans = cellfun( @(x) x('channels'), per_channel, 'un', false );
for i = 1:numel(chans)
  per_channel{i} = per_channel{i}.only( chans{i}(1) );
end

signals_ = extend( per_channel{:} );

%%  get granger

import dsp2.analysis.playground.*;

signals = update_min( update_max(signals) );
signals_ = dsp2.process.reference.reference_subtract_within_day( signals );

signals_ = signals_.rm( 'errors' );

acc = signals_.only( 'acc' );
acc_chans = acc( 'channels' );
bla = signals_.only( 'bla' );
bla_chans = bla( 'channels' );

prod = dsp2.util.general.allcomb( {acc_chans, bla_chans} );

all_granger = cell( size(prod, 1), 1 );
all_fitted = cell( size(prod, 1), 1 );
%%
for i = 1:size(prod, 1)
  fprintf( '\n Processing %d of %d', i, size(prod, 1) );
  reg1 = signals_.only( prod{i, 1} );
  reg2 = signals_.only( prod{i, 2} );
  combined = append( reg1, reg2 );
  %   combined.data = combined.data(:, 1001:1500 );
  combined.data = combined.data(:, 501:1000 );
  combined = combined.for_each( 'channels', @dsp2.process.reference.detrend );
%   combined.data = detrend( combined.data', 'constant' )';
  combined = combined.rm( 'errors' );
  [granger, fitted, freqs, ids, C] = permuted_granger( combined, 'regions', 100, 100 );
  all_granger{i} = granger;
  all_fitted{i} = fitted;
end

%%  plot

ind = 5;
granger = all_granger{ind};
fitted = all_fitted{ind};

dsp2.plot.playground.plot_granger( granger, fitted, freqs, ids, C );

editor = FigureEdits( gcf );
editor.ylim([0, .2]);