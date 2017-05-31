function run(varargin)

%   RUN -- Calculate coherence, normalized power, or raw power
%     trial-by-trial, day-by-day according to the current config options.
%
%     If unspecified, the config file dsp2/+config/config.mat will be
%     loaded.
%
%     run( 'measure_type', measure_type ) runs the analysis for the given
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

import dsp2.analysis.util.*;
import dsp2.process.reference.*;

io = dsp2.io.get_dsp_h5();

defaults.config = dsp2.config.load();
defaults.sessions = 'new';
defaults.measure_type = 'coherence';

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

signal_container_params = conf.SIGNALS.signal_container_params;
ref_type = conf.SIGNALS.reference_type;
measure_type = params.measure_type;
baseline_epoch = conf.SIGNALS.baseline_epoch;

if ( isequal(measure_type, 'normalized_power') )
  is_norm_power = true;
else
  is_norm_power = false;
end

load_path = io.fullfile( conf.PATHS.H5.signals, ref_type, 'complete' );
save_path = io.fullfile( conf.PATHS.H5.measures, 'Signals', ref_type ...
  , measure_type, 'complete' );

epochs = dsp2.config.get.active_epochs( 'config', conf );
epochs = cellfun( @(x) conf.SIGNALS.epoch_mapping.(x), epochs, 'un', false );

for i = 1:numel(epochs)  
  full_savepath = io.fullfile( save_path, epochs{i} );
  full_loadpath = io.fullfile( load_path, epochs{i} );
  full_loadpath_baseline = io.fullfile( load_path, baseline_epoch );

  if ( isequal(params.sessions, 'new') )
    if ( io.is_group(full_savepath) )
      current_days = io.get_days( full_savepath );
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
    fprintf( '\n Processing ''%s'' (%d of %d)', new_days{k}, k, numel(new_days) );
    
    signals = io.read( full_loadpath, 'only', new_days{k} );
    if ( is_norm_power )
      baseline = io.read( full_loadpath_baseline, 'only', new_days{k} );
    end
    switch ( ref_type )
      case 'non_common_averaged'
        signals = reference_subtract_within_day( signals );
        signals = signals.update_range();
        if ( is_norm_power )
          baseline = reference_subtract_within_day( baseline );
          baseline = baseline.update_range();
        end
      case 'common_averaged'
        %
      otherwise
        error( 'Unrecognized reference type ''%s''', reference_type );
    end    
    
    signals.params = signal_container_params;    
    
    switch ( measure_type )
      case 'coherence'
        measure = signals.run_coherence();
      case 'raw_power'
        measure = signals.run_raw_power();
      case 'normalized_power'
        baseline.params = signal_container_params;
        measure = signals.run_normalized_power( baseline );
    end
    
    %   remove days that exist already, if we manually specified days.
    if ( io.contains_labels(new_days{k}, full_savepath) )
      io.remove( new_days{k}, full_savepath );
    end
    %   add in the data.
    io.add( measure, full_savepath );
  end
end

end