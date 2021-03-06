function tmp_write(str, fname, conf)

%   TMP_WRITE -- Write text to a temporary text file.
%
%     ... tmp_write( 'value' ) appends 'value' to the text file 'tmp.txt',
%     stored in `conf.PATHS.job_output`.
%
%     ... tmp_write( {'%s_%d.mat', 'test', 1} ) constructs the string
%     'test1.mat' before writing to the file. All sprintf inputs are valid.
%
%     ... tmp_write( ..., 'tmp1' ) uses the filename 'tmp1' instead of
%     'tmp.txt'
%
%     ... tmp_write(), without arguments, creates the text file 'tmp.txt'
%     in `conf.PATHS.job_output`, if it does not already exist, or clears
%     the file if it does exist.
%
%     ... tmp_write( '-clear' ) is equivalent to above.
%
%     IN:
%       - `str` (char) -- String to write.
%       - `fname` (char) |OPTIONAL| -- Filename. Defaults to 'tmp.txt'.
%       - `conf` (struct) |OPTIONAL| -- Config file.

if ( nargin < 3 ), conf = dsp2.config.load(); end
if ( nargin < 2 ), fname = 'tmp.txt'; end
if ( nargin == 0 ), str = '-clear'; end

import dsp2.util.assertions.*;

if ( ~iscell(str) )
  assert__isa( str, 'char', 'the file contents' );
else
  str = sprintf( str{:} );
end

assert__isa( conf, 'struct', 'the config file' );

if ( ~conf.CLUSTER.use_cluster || ~conf.CLUSTER.tmp_write_output )
  %   if we're not on the cluster, print the string to standard output
  %   instead of writing to a file, but if the string is '-clear', just
  %   return without printing anything
  if ( strcmpi(str, '-clear') ), return; end
  fprintf( str );
  return;
end

fname = fullfile( conf.PATHS.job_output, fname );

if ( strcmpi(str, '-clear') )
  fid = fopen( fname, 'wt' );
  str = '';
else
  fid = fopen( fname, 'at' );
end

try
  fprintf( fid, str );
  fclose( fid );
catch err
  fclose( fid );
  throw( err );
end

end