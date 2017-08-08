function run(measure_type, varargin)

%   RUN -- Calculate coherence, normalized power, or raw power
%     trial-by-trial, day-by-day according to the current config options.
%
%     If unspecified, the config file dsp2/+config/config.mat will be
%     loaded.
%
%     run( measure_type ) runs the analysis for the given
%     `measure_type`.
%     
%     run( ..., 'config', conf ) runs the analysis using the config `conf`
%     instead of the saved config file.
%
%     run_coherence( ..., 'sessions', sessions ) runs the analysis using
%     the sessions in `sessions`. 
%
%     run_coherence( ..., 'sessions', 'new' ) runs the analysis on the
%     sessions in the pre-processed signals folder for which there is no
%     data in the analysis folder; i.e., only on the newly added sessions.
%     If there are no new sessions, the function will return early. This is
%     the default behavior.
%
%     IN:
%       - `measure_type` (char) -- 'coherence', 'normalized_power',
%         'raw_power'
%       - `varargin` ('name', value)

import dsp2.analysis.util.*;
import dsp2.process.reference.*;

defaults.config = dsp2.config.load();
defaults.sessions = 'new';

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

io = dsp2.io.get_dsp_h5( 'config', conf );

signal_container_params = conf.SIGNALS.signal_container_params;

ref_type = conf.SIGNALS.reference_type;

baseline_epoch = conf.SIGNALS.baseline_epoch;

mua_cutoffs = conf.SIGNALS.mua_filter_frequencies;
mua_devs = conf.SIGNALS.mua_std_threshold;

if ( isequal(measure_type, 'normalized_power') )
  is_norm_power = true;
else
  is_norm_power = false;
end

if ( strcmp(measure_type, 'sfcoherence') )
  is_sfcoherence = true;
else
  is_sfcoherence = false;
end

if ( strcmp(ref_type, 'none') || strcmp(ref_type, 'non_common_averaged') )
  load_reftype = 'none';
else
  load_reftype = ref_type;
end

h5_path = conf.PATHS.H5.signals;

load_path = io.fullfile( h5_path, load_reftype, 'complete' );
load_path_wideband = io.fullfile( h5_path, load_reftype, 'wideband' );

save_path = io.fullfile( conf.PATHS.H5.measures, 'Signals', ref_type ...
  , measure_type, 'complete' );

epochs = dsp2.config.get.active_epochs( 'config', conf );
epochs = cellfun( @(x) conf.SIGNALS.epoch_mapping.(x), epochs, 'un', false );

for i = 1:numel(epochs)
  fprintf( '\n Processing ''%s'' (%d of %d)', epochs{i}, i, numel(epochs) );
  
  full_savepath =           io.fullfile( save_path, epochs{i} );
  full_loadpath =           io.fullfile( load_path, epochs{i} );
  full_loadpath_wideband =  io.fullfile( load_path_wideband, epochs{i} );
  full_loadpath_baseline =  io.fullfile( load_path, baseline_epoch );

  if ( isequal(params.sessions, 'new') )
    if ( io.is_group(full_savepath) )
      if ( io.is_container_group(full_savepath) )
        current_days = io.get_days( full_savepath );
      else
        current_days = {};
      end
    else
      io.create_group( full_savepath );
      current_days = {};
    end
    all_days = io.get_days( full_loadpath );
    new_days = setdiff( all_days, current_days );
  else
    new_days = dsp2.util.general.ensure_cell( params.sessions );
  end
  
  if ( isempty(new_days) )
    fprintf( '\n No new days to add ...' );
    continue;
  end
  
  for k = 1:numel(new_days)
    fprintf( '\n\t Processing ''%s'' (%d of %d)', new_days{k}, k, numel(new_days) );
    fprintf( '\n\t Loading ... ' );
    
    signals = io.read( full_loadpath, 'only', new_days{k} );
    
    if ( is_norm_power )
      baseline = io.read( full_loadpath_baseline, 'only', new_days{k} );
    end
    if ( is_sfcoherence )
      wideband = io.read( full_loadpath_wideband, 'only', new_days{k} );
    end
    
    fprintf( 'Done' );
    
    switch ( ref_type )
      case 'non_common_averaged'
        signals = update_min( update_max(signals) );
        signals = reference_subtract_within_day( signals );
        signals = signals.filter();
        signals = signals.update_range();
        if ( is_norm_power )
          baseline = update_min( update_max(baseline) );
          baseline = reference_subtract_within_day( baseline );
          baseline = baseline.filter();
          baseline = baseline.update_range();
        end
      case { 'common_averaged', 'none' }
        signals = update_min( update_max(signals) );
        signals = signals.filter();
        signals = signals.update_range();
        if ( is_norm_power )
          baseline = update_min( update_max(baseline) );
          baseline = baseline.filter();
          baseline = baseline.update_range();
        end
      otherwise
        error( 'Unrecognized reference type ''%s''', reference_type );
    end
    
    signals.params = signal_container_params;
    
    fprintf( '\n\t Calculating ''%s'' ... ', measure_type );
    
    switch ( measure_type )
      case 'coherence'
        if ( strcmp(ref_type, 'none') )
          A = signals.run_coherence( 'reg1', 'bla', 'reg2', 'acc' );
          B = signals.run_coherence( 'reg1', 'bla', 'reg2', 'ref' );
          C = signals.run_coherence( 'reg1', 'acc', 'reg2', 'ref' );
          measure = A.extend( B, C );
        else
          measure = signals.run_coherence();
        end
      case 'sfcoherence'
        assert( strcmp(ref_type, 'non_common_averaged') ...
          , 'Only non_common_averaged has been implemented.' );
        
        wideband.params = signal_container_params;
        
        wideband = update_min( update_max(wideband) );
        wideband = wideband.filter( 'cutoffs', mua_cutoffs );
        wideband = wideband.update_range();

        spikes = dsp2.process.spike.get_mua_psth( wideband, mua_devs );

        measure = Container();
        regs = { 'bla'; 'acc' };
        reg_combs = dsp2.util.general.allcomb( {regs, regs} );
        dups = strcmp( reg_combs(:, 1), reg_combs(:, 2) );
        reg_combs( dups, : ) = [];

        for j = 1:size(reg_combs, 1)
          spike = only( spikes, reg_combs{j, 1} );
          signal = only( signals, reg_combs{j, 2} );
          sfcoh = spike.run_sfcoherence( signal );
          measure = measure.append( sfcoh );
        end
      case 'raw_power'
        measure = signals.run_raw_power();
      case 'normalized_power'
        baseline.params = signal_container_params;
        %   run normalized power separately for each unique combination of
        %   labels in `conf.SIGNALS.normalized_power_within` fields, or
        %   across all fields if `conf.SIGNALS.normalized_power_within` is
        %   isempty.
        norm_within = conf.SIGNALS.normalized_power_within;
        if ( ~isempty(norm_within) )
          signals_ = signals.enumerate( norm_within );
          baseline_ = baseline.enumerate( norm_within );
          assert( numel(signals_) == numel(baseline_), ['Number of' ...
            , ' baseline and %s items must match.'], epochs{i} );
          measure = Container();
          for j = 1:numel(signals_)
            sig = signals_{j};
            base = baseline_{j};
            measure_ = sig.run_normalized_power( base );
            measure = measure.append( measure_ );
          end
        else
          measure = signals.run_normalized_power( baseline );
        end
    end
    
    fprintf( 'Done' );
    
    measure = measure.keep_within_freqs( [0, 250] );
    
    dsp2.util.assertions.assert__enough_space( 'E:\', 150 );
    
    %   remove days that exist already, if we manually specified days.
    if ( io.is_container_group(full_savepath) )
      if ( io.contains_labels(new_days{k}, full_savepath) )
        fprintf( '\n\t Removing expired data from ''%s'' ... ', full_savepath );
        io.remove( new_days{k}, full_savepath );
        fprintf( 'Done' );
      end
    end
    fprintf( '\n\t Saving ... ' );
    %   add in the data.
    io.add( measure, full_savepath );
    fprintf( 'Done' );
  end
end

end