function assert__valid_path(str, var_name)

%   ASSERT__VALID_PATH -- Ensure a string points to a valid path.
%
%     IN:
%       - `str` (char)
%       - `var_name` (char) |OPTIONAL| -- Optionally provide a descriptor
%         of `str`, in case the assertion fails.

if ( nargin == 1 ), var_name = 'path'; end

dsp2.util.assertions.assert__isa( str, 'char', 'the path string' );
dsp2.util.assertions.assert__isa( var_name, 'char', 'the variable name' );

orig = cd;
try
  cd( str );
  cd( orig );
catch
  cd( orig );
  error( 'The path ''%s'' is invalid.', str );
end

end