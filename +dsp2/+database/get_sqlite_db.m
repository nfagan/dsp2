function db = get_sqlite_db(varargin)

%   GET_SQLITE_DB -- Return a DictatorSignalsDB object whose .sqlite file
%     is the .sqlite file as defined by dsp2.config.create()
%
%     IN:
%       - `varargin` ('name', value) -- Optionally specify a different
%         config file with 'config', conf
%
%     OUT:
%       - `db` (DictatorSignalsDB) -- Database manager object.

defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

opts = params.config;
db_path = opts.PATHS.database;
db_name = opts.DATABASES.sqlite_file;

db = dsp2.database.DictatorSignalsDB( db_path, db_name );

end