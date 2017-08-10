io = dsp2.io.get_dsp_h5();
P = 'Signals/none/complete/targacq';
% day = { 'day__01302017', 'day__01282017' };
signals = io.read( P );
% signals = io.read( P, 'only', day );

%%
signals_ = signals.rm( 'cued' );

signals_ = update_min( update_max(signals_) );
signals_ = dsp2.process.reference.reference_subtract_within_day( signals_ );
signals_ = signals_.filter();
signals_ = signals_.rm( 'errors' );
signals_.data = signals_.data(:, 301:500 );
signals_ = signals_.parfor_each( {'channels', 'days'}, @dsp2.process.reference.detrend );

%%

days = signals_( 'days' );

for i = 54:numel(days)

fprintf( '\n Processing ''%s'' (%d of %d)', days{i}, i, numel(days) );

signals2 = signals_.only( days{i} );
G = signals2.for_each( {'outcomes', 'days'} ...
  , @dsp2.analysis.playground.run_granger ...
  , 'bla', 'acc', 100, 'dist', 'ev' ...
  , 'max_lags', [] ...
);

save( sprintf('granger_segment_%d', i), 'G' );

end

%%

G2 = G.parfor_each( {'outcomes', 'days', 'channels'}, @dsp2.analysis.playground.convert_granger );

%%

% G3 = dsp2.process.manipulations.pro_v_anti( G2 );

g_days = G2( 'days' );

% G3 = G2.parfor_each( {'outcomes', 'days', 'kind', 'regions'}, @mean );
G3 = G2;

% G3 = G3.rm( 'null_distribution' );

G3.plot( 'kind', {'outcomes', 'regions'} ...
  , 'shape', [4, 2] ...
  , 'add_ribbon', true ...
  , 'main_line_width', 1.5 ...
  , 'x', G2.frequencies ...
  , 'x_lim', [0 80] ...
  , 'y_lim', [] ...
);