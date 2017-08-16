function set_abort(conf)

%   SET_ABORT -- Mark that an analysis should abort.
%
%     ... set_abort() writes 'abort' to the analysis status file,
%     indicating that a currently running analysis should abort.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- Config file.

if ( nargin < 1 ), conf = dsp2.config.load(); end

dsp2.util.assertions.assert__isa( conf, 'struct', 'the config file' );

fname = conf.CLUSTER.analysis_status_filename;
fname = fullfile( conf.PATHS.repositories, 'dsp2', fname );

fid = fopen( fname, 'w+' );
try
  fprintf( fid, 'abort' );
  fclose( fid );
catch err
  fclose( fid );
  throw( err );
end

end