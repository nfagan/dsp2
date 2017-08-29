%%  RUN_NULL_GRANGER -- initialize, setup paths, etc.

import dsp2.util.cluster.tmp_write;

dsp2.cluster.init();
conf = dsp2.config.load();
%   setup mvgc toolbox
run( fullfile(conf.PATHS.repositories, 'mvgc_v1.0', 'startup.m') );
%   get signals
io = dsp2.io.get_dsp_h5();
epoch = 'reward';
tmp_fname = sprinttf( 'null_granger_%s.txt', epoch );
tmp_write( '-clear', tmp_fname );
P = io.fullfile( 'Signals/none/complete', epoch );
tmp_write( {'Loading %s ... ', epoch}, tmp_fname );
signals = io.read( P );
tmp_write( 'Done\n', tmp_fname );
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

detrend_func = @dsp2.process.reference.detrend;

signals_ = signals_.parfor_each( {'channels', 'days'}, detrend_func );

tmp_write( 'Done\n', tmp_fname );

%%  run null granger

import dsp2.analysis.playground.run_granger;

signals_ = signals_.require_fields( 'context' );
signals_( 'context', signals_.where({'self', 'both'}) ) = 'context__selfboth';
signals_( 'context', signals_.where({'other', 'none'}) ) = 'context__othernone';

days = signals_( 'days' );
n_perms = 100;
n_perms_in_granger = 1; % only calculate granger once
n_trials = Inf; % use all trials for that distribution
max_lags = 1e3;
dist_type = 'ev';

shuffle_within = { 'context' };

for i = 1:numel(days)

  tmp_write( {'Processing %s (%d of %d)\n', days{i}, i, numel(days)}, tmp_fname );

  tic;
  one_day = signals_.only( days{i} );

  cmbs = one_day.pcombs( shuffle_within );
  conts = cell( size(cmbs, 1), 1 );

  for j = 1:size(cmbs, 1)
    iters = cell( 1, n_perms );
    parfor k = 1:n_perms
      ctx = one_day.only( cmbs(j, :) );
      chans = ctx.labels.flat_uniques( 'channels' );
      n_trials_this_context = sum( ctx.where(chans{1}) );
      ind = randperm( n_trials_this_context );
      %   shuffle
      ctx = ctx.for_each( {'days', 'channels', 'regions'}, @numeric_index, ind );
      G = dsp2.analysis.playground.run_granger( ...
        ctx, 'bla', 'acc', n_trials, n_perms_in_granger ...
        , 'dist', dist_type ...
        , 'max_lags', max_lags ...
        , 'do_permute', false ...
      );
      iters{k} = G;
    end
    conts{j} = extend( iters{:} );
  end
  toc;

  fname = sprintf( 'granger_segment_%d', i );

  save( fullfile(save_path, fname), 'G' );
end
