function assert__is_scalar( val, var_kind )

%   ASSERT__IS_SCALAR -- Ensure a variable is a scalar.
%
%     IN:
%       - `val` (/any/)
%       - `var_kind` (char) |OPTIONAL| -- Optionally provide a more verbose
%         variable descriptor, in case the assertion fails. Defaults to
%         'input'.

if ( nargin < 2 ), var_kind = 'input'; end
assert( isscalar(val), 'Expected %s to be scalar; instead %d elements' ...
  , ' were present', var_kind, numel(val) );

end