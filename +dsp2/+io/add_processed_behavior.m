function add_processed_behavior(varargin)

%   ADD_PROCESSED_BEHAVIOR -- Add processed behavior measures to the .h5
%     database file.
%
%     IN:
%       - `varargin` ('name', value) -- Optionally pass in a config file
%         with 'config', conf

io = dsp2.io.get_dsp_h5();
db = dsp2.database.get_sqlite_db();

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

savepath = conf.PATHS.H5.behavior_measures;

current_db_sessions = db.get_sessions();
reformatted_db_sessions = dsp2.io.util.match_days( current_db_sessions );

if ( io.is_group(savepath) )
  current_saved_days = io.get_days( savepath );
else
  io.create_group( savepath );
  current_saved_days = {};
end

days_to_add = setdiff( reformatted_db_sessions, current_saved_days );

if ( isempty(days_to_add) )
  fprintf( '\n No new data to add ...' );
  db.close();
  return;
end

% get the proper format for the database
inds = get_original_index( reformatted_db_sessions, days_to_add );
db_days_to_add = current_db_sessions( inds );

[behav, key] = dsp2.io.get_behavior( 'config', conf, 'sessions', db_days_to_add );
behav = behav.trial_info;
key = key.trial_info;

io.add( behav, savepath );
io.write( key, io.fullfile(savepath, 'Key') );

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