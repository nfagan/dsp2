function add_processed_signals(varargin)

%   ADD_PROCESSED_SIGNALS -- Save SignalContainer objects for each active
%     epoch, as defined in dsp2.config.create().
%
%     IN:
%       - `varargin` ('name', value) -- Optionally pass in a config file
%         with 'config', conf

io = dsp2.io.get_dsp_h5();
io.ALLOW_REWRITE = true;
db = dsp2.database.get_sqlite_db();

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

reference_type = conf.SIGNALS.reference_type;

base_savepath = io.fullfile( conf.PATHS.H5.signals, reference_type );

epochs = dsp2.config.get.active_epochs( 'config', conf );
epoch_folders = cellfun( @(x) conf.SIGNALS.epoch_mapping.(x), epochs, 'un', false );

current_db_sessions = db.get_sessions();
reformatted_db_sessions = dsp2.io.util.match_days( current_db_sessions );

for i = 1:numel( epochs )
  
  conf = dsp2.config.set.inactivate_epochs( 'all', conf );
  conf = dsp2.config.set.activate_epochs( epochs{i}, conf );
  
  full_savepath = io.fullfile( base_savepath, 'complete', epoch_folders{i} );
  
  if ( io.is_group(full_savepath) )
    current_saved_days = io.get_days( full_savepath );
  else
    io.create_group( full_savepath );
    current_saved_days = {};
  end
  
  days_to_add = setdiff( reformatted_db_sessions, current_saved_days );
  
  if ( isempty(days_to_add) )
    fprintf( '\n No new data to add ...' );
    continue;
  end
  
  % get the proper format for the database
  inds = get_original_index( reformatted_db_sessions, days_to_add );
  db_days_to_add = current_db_sessions( inds );
  
  for k = 1:numel(db_days_to_add)
    db_day = db_days_to_add{k};
    signals = dsp2.io.get_signals( 'config', conf, 'sessions', db_day );
    signal_container = signals{1};
    signal_container.params = conf.SIGNALS.signal_container_params;
    io.add( signal_container, full_savepath );
  end
end

db.close();

end

function ind = get_original_index( reformatted, days_to_add )

ind = false( numel(reformatted), 1 );
for i = 1:numel(days_to_add)
  current = strcmp( reformatted, days_to_add{i} );
  assert( any(current), 'Wrong format.' );
  ind = ind | current;
end

end