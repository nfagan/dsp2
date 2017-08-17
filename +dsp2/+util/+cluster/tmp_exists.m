function tf = tmp_exists(fname, conf)

%   TMP_EXISTS -- Check whether a tmp file exists.
%
%     tf = ... tmp_exists() returns true if 'tmp.txt' exists in
%     `conf.PATHS.job_output`.
%
%     tf = ... tmp_exists( 'tmp2' ) looks for the file 'tmp2'.
%
%     tf = ... tmp_exists( ..., conf ) uses the config file `conf` instead
%     of the saved config file.

if ( nargin < 2 ), conf = dsp2.config.load(); end
if ( nargin < 1 ), fname = 'tmp.txt'; end

import dsp2.util.assertions.*;
assert__isa( fname, 'char', 'the tmp filename' );
assert__isa( conf, 'struct', 'the config file' );
fname = fullfile( conf.PATHS.job_output, fname );
tf = exist( fname, 'file' ) > 0;

end