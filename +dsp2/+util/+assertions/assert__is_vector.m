function assert__is_vector( val, var_kind )

%   ASSERT__IS_VECTOR -- Ensure a variable is a vector.
%
%     IN:
%       - `val` (/any/)
%       - `var_kind` (char) |OPTIONAL| -- Optionally provide a more verbose
%         variable descriptor, in case the assertion fails. Defaults to
%         'input'.

if ( nargin < 2 ), var_kind = 'input'; end
assert( ismatrix(val) && isvector(val), 'Expected %s to be vector.', var_kind );

end