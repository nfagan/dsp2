dsp2.cluster.init();
conf = dsp2.config.load();
io = dsp2.io.get_dsp_h5();
P = 'Signals/none/complete/targacq';
signals = io.read( P );
date_dir = dsp2.process.format.get_date_dir();
save_path = fullfile( conf.PATHS.analyses, 'granger', date_dir );
dsp2.util.general.require_dir( save_path );
conf.PATHS.dynamic.granger = save_path;
dsp2.config.save( conf );

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

for i = 1:numel(days)

fprintf( '\n Processing ''%s'' (%d of %d)', days{i}, i, numel(days) );

signals2 = signals_.only( days{i} );
G = signals2.for_each( {'outcomes', 'days'} ...
  , @dsp2.analysis.playground.run_granger ...
  , 'bla', 'acc' ...
  , 100 ...
  , 'dist', 'ev' ...
  , 'max_lags', [] ...
);

fname = sprintf( 'granger_segment_%d', i );

save( fullfile(save_path, fname), 'G' );

end