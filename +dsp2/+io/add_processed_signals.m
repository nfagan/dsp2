function add_processed_signals(varargin)

%   ADD_PROCESSED_SIGNALS -- Save SignalContainer objects for each active
%     epoch, as defined in dsp2.config.create().
%
%     IN:
%       - `varargin` ('name', value) -- Optionally pass in a config file
%         with 'config', conf

defaults.config = dsp2.config.load();
defaults.wideband = false;

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

io = dsp2.io.get_dsp_h5( 'config', conf );
io.ALLOW_REWRITE = true;
db = dsp2.database.get_sqlite_db( 'config', conf );

reference_type = conf.SIGNALS.reference_type;

if ( params.wideband )
  subfolder = 'wideband';
else
  subfolder = 'complete';
end

base_savepath = io.fullfile( conf.PATHS.H5.signals, reference_type );

epochs = dsp2.config.get.active_epochs( 'config', conf );
epoch_folders = cellfun( @(x) conf.SIGNALS.epoch_mapping.(x), epochs, 'un', false );

current_db_sessions = db.get_sessions();
reformatted_db_sessions = dsp2.io.util.match_days( current_db_sessions );

for i = 1:numel( epochs )
  
  conf = dsp2.config.set.inactivate_epochs( 'all', conf );
  conf = dsp2.config.set.activate_epochs( epochs{i}, conf );
  
  full_savepath = io.fullfile( base_savepath, subfolder, epoch_folders{i} );
  
  if ( io.is_group(full_savepath) && io.is_container_group(full_savepath) )
    current_saved_days = io.get_days( full_savepath );
  else
    current_saved_days = {};
  end
  
  if ( ~io.is_group(full_savepath) )
    io.create_group( full_savepath );
  end
  
  days_to_add = setdiff( reformatted_db_sessions, current_saved_days );
  
  if ( isempty(days_to_add) )
    fprintf( '\n No new data to add ...' );
    continue;
  end
  
  % get the proper format for the database
  inds = get_original_index( reformatted_db_sessions, days_to_add );
  db_days_to_add = current_db_sessions( inds );
  reformat_days_to_add = reformatted_db_sessions( inds );
  db_days_to_add = group_by_day( reformat_days_to_add, db_days_to_add );
  
  for k = 1:numel(db_days_to_add)
    
    dsp2.util.assertions.assert__enough_space( 'E:\', 150 );
    
    db_day = db_days_to_add{k};
    try 
      signals = dsp2.io.get_signals( ...
          'config', conf ...
        , 'sessions', db_day ...
        , 'wideband', params.wideband ...
      );
    catch err
      warning( err.message );
      continue;
    end
    signal_container = signals{1};
    signal_container.params = conf.SIGNALS.signal_container_params;
    io.add( signal_container, full_savepath );
  end
end

db.close();

end

function ind = get_original_index( reformatted, days_to_add )

%   GET_ORIGINAL_INDEX -- Get the index of the database sessions to add,
%     based on the reformatted days to add.
%
%     IN:
%       - `reformatted` (cell array of strings)
%       - `days_to_add` (cell array of strings)
%     OUT:
%       - `ind` (logical)

ind = false( numel(reformatted), 1 );
for i = 1:numel(days_to_add)
  current = strcmp( reformatted, days_to_add{i} );
  assert( any(current), 'Wrong format.' );
  ind = ind | current;
end

end

function grps = group_by_day( reformatted, db_sessions )

%   GROUP_BY_DAY -- Group database sessions by day.
%
%     IN:
%       - `reformatted` (cell array of strings)
%       - `db_sessions` (cell array of strings)
%     OUT:
%       - `grps` (cell array of strings)

days = unique( reformatted );
grps = cell( size(days) );
for i = 1:numel(days)
  grps{i} = db_sessions( strcmp(reformatted, days{i}) );
end

end