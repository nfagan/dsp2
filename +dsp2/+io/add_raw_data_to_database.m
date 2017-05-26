function add_raw_data_to_database( outerfolder, varargin )

%   ADD_RAW_DATA_TO_DATABASE -- Add un-processed behavioral data (and
%     references to neural data) to the sqlite database.
%
%     add_raw_data_to_database( outerfolder ) adds all data in the
%     subfolders of `outerfolder` to the database.
%
%     IN:
%       - `outerfolder` (char)

defaults.config = dsp2.config.load();
params = dsp2.util.general.parsestruct( defaults, varargin );

db = dsp2.database.get_sqlite_db();

allow_overwrite = params.config.DATABASES.allow_overwrite;
if ( allow_overwrite )
  prompt_to_overwrite = true;
else
  prompt_to_overwrite = false;
end

try
  db.ADD_DATA( outerfolder, prompt_to_overwrite );
catch err
  fprintf( '\n The following error occurred when attempting to add data:\n' );
  fprintf( '\n%s', err.message );
end

db.close();

end