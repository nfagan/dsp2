function require_h5_database(conf)

%   REQUIRE_H5_DATABASE -- Create the .h5 database file if it does not
%     already exist.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- Config file. Defaults to saved
%         config file.

if ( nargin < 1 )
  conf = dsp2.config.load();
end

h5_dir = conf.PATHS.database;
h5_file = fullfile( h5_dir, conf.DATABASES.h5_file );

if ( exist(h5_file, 'file') == 0 )
  io = dsp2.io.dsp_h5();
  io.create( h5_file );
end

end