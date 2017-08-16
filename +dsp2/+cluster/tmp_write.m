function tmp_write(str, fname, conf)

%   TMP_WRITE -- Write text to a temporary text file.
%
%     IN:
%       - `str` (char) -- String to write.
%       - `fname` (char) |OPTIONAL| -- Filename. Defaults to 'tmp.txt'.
%       - `conf` (struct) |OPTIONAL| -- Config file.

if ( nargin < 3 ), conf = dsp2.config.load(); end
if ( nargin < 2 ), fname = 'tmp.txt'; end

dsp2.util.assertions.assert__isa( str, 'char', 'the file contents' );
dsp2.util.assertions.assert__isa( conf, 'struct', 'the config file' );

fname = fullfile( conf.PATHS.job_output, fname );
fid = fopen( fname, 'w+' );

try
  fprintf( fid, str );
  fclose( fid );
catch err
  fclose( fid );
  throw( err );
end

end