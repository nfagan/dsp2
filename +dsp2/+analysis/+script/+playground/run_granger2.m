%%  initialize, setup paths, etc.

import dsp2.util.cluster.tmp_write;

dsp2.cluster.init();
conf = dsp2.config.load();
%   setup mvgc toolbox
run( fullfile(conf.PATHS.repositories, 'mvgc_v1.0', 'startup.m') );
%   get signals
io = dsp2.io.get_dsp_h5();
epoch = 'reward';
tmp_fname = [ epoch, '.txt' ];
tmp_write( '-clear', tmp_fname );
P = io.fullfile( 'Signals/none/complete', epoch );
tmp_write( {'Loading ... %s', epoch}, tmp_fname );
signals = io.read( P );
tmp_write( 'Done loading\n', tmp_fname );
%   set up save paths
save_path = fullfile( conf.PATHS.analyses, 'granger', epoch );
dsp2.util.general.require_dir( save_path );

%%  preprocess signals
tmp_write( 'Preprocessing signals ... ', tmp_fname );

if ( strcmp(epoch, 'targacq') )
  signals_ = signals.rm( 'cued' );
else
  signals_ = signals;
end

signals_ = update_min( update_max(signals_) );
signals_ = dsp2.process.reference.reference_subtract_within_day( signals_ );
signals_ = signals_.filter();
signals_ = signals_.rm( 'errors' );

if ( strcmp(epoch, 'targacq') )
  % [ -200, 0 ]
  signals_.data = signals_.data(:, 301:500 );
elseif ( strcmp(epoch, 'reward') )
  % [ 50, 250 ]
  signals_.data = signals_.data(:, 1051:(1050+200));
else
  error( 'Script not defined for ''%s''.', epoch );
end

signals_ = signals_.parfor_each( {'channels', 'days'} ...
  , @dsp2.process.reference.detrend );

tmp_write( 'Done\n', tmp_fname );

%%  run analysis

days = signals_( 'days' );

for i = 1:numel(days)

tmp_write( {'Processing %s (%d of %d)\n', days{i}, i, numel(days)}, tmp_fname );

signals2 = signals_.only( days{i} );
G = signals2.for_each( {'outcomes', 'days', 'trialtypes'} ...
  , @dsp2.analysis.playground.run_granger ...
  , 'bla', 'acc' ...
  , 100 ...
  , 'dist', 'ev' ...
  , 'max_lags', [] ...
);

fname = sprintf( 'granger_segment_%d', i );

save( fullfile(save_path, fname), 'G' );

end