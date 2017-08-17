function out = fload(fname)

%   FLOAD -- Load in and assign to variable.
%
%     out = ... fload( 'file1.mat' ); loads the contents of 'file1.mat' and
%     assigns to the variable `out`. 'file1.mat' cannot contain multiple 
%     variables.
%
%     IN:
%       - `fname` (char) -- .mat file to load.
%     OUT:
%       - `out` (/any/) -- Loaded data.

import dsp2.util.assertions.*;

assert__isa( fname, 'char', 'the .mat file' );
assert__file_exists( fname, 'the .mat file' );

var = load( fname );
fs = fieldnames( var );

assert( numel(fs) == 1, 'More than one variable saved in ''%s''.', fname );

out = var.(fs{1});

end