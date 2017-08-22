%%  initialize, setup paths, etc.

import dsp2.util.cluster.tmp_write;

dsp2.cluster.init();
conf = dsp2.config.load();
%   setup mvgc toolbox
run( fullfile(conf.PATHS.repositories, 'mvgc_v1.0', 'startup.m') );
%   get signals
io = dsp2.io.get_dsp_h5();
epoch = 'targacq';
P = io.fullfile( 'Signals/none/complete', epoch );
signals = io.read( P );
%   set up save paths
save_path = fullfile( conf.PATHS.analyses, 'granger', epoch );
dsp2.util.general.require_dir( save_path );
conf.PATHS.dynamic.granger = save_path;
dsp2.config.save( conf );

%%  preprocess signals
tmp_write( '-clear' );
tmp_write( 'Preprocessing signals ... ' );

signals_ = signals.rm( 'cued' );

signals_ = update_min( update_max(signals_) );
signals_ = dsp2.process.reference.reference_subtract_within_day( signals_ );
signals_ = signals_.filter();
signals_ = signals_.rm( 'errors' );
signals_.data = signals_.data(:, 301:500 );
signals_ = signals_.parfor_each( {'channels', 'days'}, @dsp2.process.reference.detrend );

tmp_write( 'Done\n' );

%%  run analysis

days = signals_( 'days' );

for i = 55:numel(days)

tmp_write( {'Processing %s (%d of %d)\n', days{i}, i, numel(days)} );

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