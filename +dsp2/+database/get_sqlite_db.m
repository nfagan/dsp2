function db = get_sqlite_db()

%   GET_SQLITE_DB -- Return a DictatorSignalsDB object whose .sqlite file
%     is the .sqlite file as defined by dsp2.config.create()
%
%     OUT:
%       - `db` (DictatorSignalsDB) -- Database manager object.

opts = dsp2.config.load();
db_path = opts.PATHS.database;
db_name = opts.DATABASES.sqlite_file;

db = dsp2.database.DictatorSignalsDB( db_path, db_name );

end