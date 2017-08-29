%%  RUN_NULL_GRANGER -- initialize, setup paths, etc.

import dsp2.util.cluster.tmp_write;

dsp2.cluster.init();
conf = dsp2.config.load();
%   setup mvgc toolbox
run( fullfile(conf.PATHS.repositories, 'mvgc_v1.0', 'startup.m') );
%   get signals
io = dsp2.io.get_dsp_h5();
epoch = 'reward';
tmp_fname = sprintf( 'null_granger_%s.txt', epoch );
tmp_write( '-clear', tmp_fname );
P = io.fullfile( 'Signals/none/complete', epoch );
tmp_write( {'Loading %s ... ', epoch}, tmp_fname );
signals = io.read( P );
tmp_write( 'Done\n', tmp_fname );
%   set up save paths
save_path = fullfile( conf.PATHS.analyses, 'granger', 'null', epoch );
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

signals_ = signals_.require_fields( {'context', 'iteration'} );
signals_( 'context', signals_.where({'self', 'both'}) ) = 'context__selfboth';
signals_( 'context', signals_.where({'other', 'none'}) ) = 'context__othernone';

granger_fname = 'granger_segment_';

current_files = dsp2.util.general.dirnames( save_path, '.mat' );
current_days = cellfun( @(x) x(numel(granger_fname)+1:end-4), current_files, 'un', false );

days = signals_( 'days' );
n_perms = 100;
n_perms_in_granger = 1; % only calculate granger once
n_trials = Inf; % use all trials for that distribution
max_lags = 1e3;
dist_type = 'ev';

shuffle_within = { 'context' };

days = setdiff( days, current_days );

for i = 1:numel(days)

  tmp_write( {'Processing %s (%d of %d)\n', days{i}, i, numel(days)}, tmp_fname );

  one_day = signals_.only( days{i} );

  cmbs = one_day.pcombs( shuffle_within );
  conts = cell( size(cmbs, 1), 1 );

  for j = 1:size(cmbs, 1)
    iters = cell( 1, n_perms );
    parfor k = 1:n_perms+1
      ctx = one_day.only( cmbs(j, :) );
      chans = ctx.labels.flat_uniques( 'channels' );
      n_trials_this_context = sum( ctx.where(chans{1}) );
      if ( k < n_perms+1 )
        ind = randperm( n_trials_this_context );
      else
        %   don't permute the last subset
        ind = 1:n_trials_this_context;
      end
      %   shuffle
      shuff_func = @(x) n_dimension_op(x, @(y) y(ind, :));
      ctx = ctx.for_each( {'days', 'channels', 'regions'}, shuff_func );
      outs = ctx.labels.flat_uniques( 'outcomes' );
      out_cont = Container();
      for h = 1:numel(outs)
        G = dsp2.analysis.playground.run_granger( ...
          ctx.only(outs{h}), 'bla', 'acc', n_trials, n_perms_in_granger ...
          , 'dist', dist_type ...
          , 'max_lags', max_lags ...
          , 'do_permute', false ...
        );
        G.labels = G.labels.set_field( 'iteration', sprintf('iteration__%d', k) );
        out_cont = out_cont.append( G );
      end
      out_cont = out_cont.require_fields( 'permuted' );
      if ( k < n_perms+1 )
        out_cont( 'permuted' ) = 'permuted__true';
      else
        out_cont( 'permuted' ) = 'permuted__false';
      end
      iters{k} = out_cont;
    end
    conts{j} = extend( iters{:} );
  end
  
  conts = extend( conts{:} );
  conts = dsp2.analysis.granger.convert_null_granger( conts );

  fname = sprintf( granger_fname, days{i} );

  save( fullfile(save_path, fname), 'conts' );
end
