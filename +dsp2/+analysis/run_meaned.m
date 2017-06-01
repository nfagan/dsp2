function run_meaned(measure_type, varargin)

%   RUN_MEANED -- Construct and save an average of a complete signal
%     measure, as specified in the config file.
%
%     run_meaned( measure_type ) constructs the average of
%     the specified `measure_type`. `measure_type` must exist in the .h5
%     file under a /complete group.
%
%     run_meaned( ..., 'config', conf ) uses the config file `conf` instead
%     of the default config.
%
%     IN:
%       - `measure_type` (char) -- 'coherence', 'normalized_power',
%         'raw_power'
%       - `varargin` ('name', value)

io = dsp2.io.get_dsp_h5();

defaults.config = dsp2.config.load();
defaults.sessions = 'new';

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

m_within = conf.SIGNALS.meaned.mean_within;

base_complete_path = dsp2.io.get_signal_measure_path( measure_type, 'complete' );
base_mean_path = dsp2.io.get_signal_measure_path( measure_type, 'meaned' );

epochs = io.get_component_group_names( base_complete_path );

for i = 1:numel(epochs)
  fprintf( '\n Processing ''%s'' (%d of %d)', epochs{i}, i, numel(epochs) );
  
  full_complete_path = io.fullfile( base_complete_path, epochs{i} );
  full_mean_path = io.fullfile( base_mean_path, epochs{i} );
  
  try
    complete_days = io.get_days( full_complete_path );
  catch
    error( 'No complete measure has been defined for ''%s''.', measure_type );
  end
  
  if ( isequal(params.sessions, 'new') )
    if ( io.is_group(full_mean_path) )
      mean_days = io.get_days( full_mean_path );
    else
      io.create_group( full_mean_path );
      mean_days = {};
    end
    new_days = setdiff( complete_days, mean_days );
  else
    new_days = dsp2.util.general.ensure_cell( new_days );
    assert( io.contains(new_days, full_complete_path), ['Some of the' ...
      , ' specified days are not present in the complete measure ''%s''.'] ...
      , measure_type );
    if ( io.is_group(full_mean_path) )
      io.remove( new_days, full_mean_path );
    else
      io.create_group( full_mean_path );
    end
  end
  
  if ( isempty(new_days) )
    fprintf( '\n No new data to add ...' );
    continue;
  end
  
  for k = 1:numel(new_days)
    fprintf( '\n\t Processing ''%s'' (%d of %d)', new_days{k}, k, numel(new_days) );
    complete = io.read( full_complete_path, 'only', new_days{k} );
    meaned = complete.do( m_within, @mean );
    io.add( meaned, full_mean_path );
  end
end

end