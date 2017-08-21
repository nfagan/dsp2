function add_gaze_data( process_all, conf )

%   ADD_GAZE_DATA -- Process and save gaze data.
%
%     IN:
%       - `process_all` (logical) |OPTIONAL| -- Reprocess all sessions,
%         or only process new sessions. Default is false, only process new
%         sessions.
%       - `conf` (struct) |OPTIONAL| -- Config file

if ( nargin < 1 ), process_all = false; end
if ( nargin < 2 ), conf = dsp2.config.load(); end

spath_gaze = conf.PATHS.gaze_data;

dsp2.util.general.require_dir( spath_gaze );

db = dsp2.database.get_sqlite_db( 'config', conf );
all_sessions = db.get_sessions();
db.close();

current_sessions = dsp2.util.general.dirnames( spath_gaze, '.mat' );
current_sessions = cellfun( @(x) x(1:end-4), current_sessions, 'un', false );

if ( process_all ) 
  new_sessions = all_sessions;
else
  new_sessions = setdiff( all_sessions, current_sessions );
end

N = numel( new_sessions );

if ( N == 0 ), fprintf( '\n No new data to add ...' ); return; end

for i = 1:N
  fprintf( '\n Processing %s (%d of %d)', new_sessions{i}, i, N );
  
  day = new_sessions{i};
  [behav, ~] = dsp2.io.get_behavior( 'config', conf, 'sessions', day );
  
  gaze = behav.gaze_data;
  
  fname = [ new_sessions{i}, '.mat' ];
  save( fullfile(spath_gaze, fname), 'gaze' );
end

end