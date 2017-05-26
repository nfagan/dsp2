function add_processed_signals(varargin)

%   ADD_PROCESSED_SIGNALS -- Save SignalContainer objects for each active
%     epoch, as defined in dsp2.config.create().
%
%     IN:
%       - `varargin` ('name', value)

io = dsp2.io.DSP_IO();
db = dsp2.database.get_sqlite_db();

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

reference_type = conf.SIGNALS.reference_type;

base_savepath = conf.PATHS.pre_processed_signals;
base_savepath = fullfile( base_savepath, reference_type );

epochs = dsp2.config.get.active_epochs( 'config', conf );
epoch_folders = cellfun( @(x) conf.SIGNALS.epoch_mapping.(x), epochs, 'un', false );

current_database_sessions = unique( db.get_fields('session', 'signals') );
current_database_sessions = match_days( current_database_sessions );

for i = 1:numel( epochs )
  
  conf = dsp2.config.set.inactivate_epochs( 'all', conf );
  conf = dsp2.config.set.activate_epochs( epochs{i}, conf );
  
  full_savepath = fullfile( base_savepath, epoch_folders{i} );
  if ( io.header_file_exists(full_savepath) )
    current_saved_days = io.get_days( full_savepath );
  else
    current_saved_days = {};
  end
  
  days_to_add = setdiff( current_database_sessions, current_saved_days );
  
  if ( isempty(days_to_add) )
    fprintf( '\n No new data to add ...' );
    continue;
  end
  
  signals = dsp2.io.get_signals( 'config', conf, 'sessions', days_to_add );
  signal_container = signals{1};
  io.save( signal_container, full_savepath );
 
end

db.close();

end

function matched = match_days( days_to_add )

matched = cell( size(days_to_add) );
second_underscore = cellfun( @(x) strfind(x, '_'), days_to_add, 'un', false );
for i = 1:numel(second_underscore)
  current = second_underscore{i};
  if ( numel(current) > 1 )
    matched{i} = days_to_add{i}(current(1)+1:current(2)-1);
  elseif ( numel(current) == 1 )
    matched{i} = days_to_add{i}(current(1)+1:end);
  else
    error( ['The session names are not formatted properly in the raw' ...
      , ' signals folder / database. They must begin with a number' ...
      , ' identifier and have an underscore, like this: 1_05202017'] );
  end
end

matched = cellfun( @(x) ['day__' x], matched, 'un', false );

end