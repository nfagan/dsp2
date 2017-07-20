function assert__enough_space( path, gigs )

%   ASSERT__ENOUGH_SPACE -- Ensure a given path has enough free space.
%
%     IN:
%       - `path` (char)
%       - `gigs` (number) -- Number specifying the required number of GB
%         free.

dsp2.util.assertions.assert__isa( gigs, 'double', 'the number of GB' );
dsp2.util.assertions.assert__isa( path, 'char', 'the path string' );

free_space = java.io.File( path ).getFreeSpace();
free_space = free_space / 1e9;

assert( free_space > gigs, ['The path ''%s'' does not have enough free' ...
  , ' space (less than %d GB).'], path, gigs );

end