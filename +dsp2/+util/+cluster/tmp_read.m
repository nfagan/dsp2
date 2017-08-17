function out = tmp_read(fname, conf)

%   TMP_READ -- Read contents of the tmp text file.
%
%     out = ... tmp_read() reads the file 'tmp.txt' in
%     `conf.PATHS.job_output`.
%
%     out = ... tmp_read( 'tmp1' ) reads the file 'tmp1' in the above
%     directory.
%
%     out = ... tmp_read( ..., conf ) uses the config file `conf` instead
%     of the saved config file.
%
%     IN:
%       - `fname` (char) |OPTIONAL| -- Tmp file to read. Defaults to
%         'tmp.txt'.
%       - `conf` (struct) |OPTIONAL| -- Config file.
%     OUT:
%       - `out` (char) -- Contents of `fname`.

if ( nargin < 2 ), conf = dsp2.config.load(); end
if ( nargin < 1 ), fname = 'tmp.txt'; end

import dsp2.util.assertions.*;

assert__isa( conf, 'struct', 'the config file' );
assert__isa( fname, 'char', 'the filename' );

fname = fullfile( conf.PATHS.job_output, fname );

assert__file_exists( fname, 'the tmp text file' );

out = fileread( fname );

end