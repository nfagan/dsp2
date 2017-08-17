function assert__is_cellstr_or_char( val, var_kind )

%   ASSERT__IS_CELLSTR_OR_CHAR -- Ensure a variable is a cell array of
%     strings or char.
%
%     IN:
%       - `var` (/any/) -- Variable to check.
%       - `var_name` (char) |OPTIONAL| -- Optionally provide a more
%         descriptive name for the variable in case the assertion
%         fails.

if ( nargin < 2 ), var_kind = 'input'; end
if ( ~ischar(val) )
  assert( iscellstr(val), ['Expected %s to be a cell array of strings' ...
    , ' or a char; was a ''%s'''], var_kind, class(val) );
end

end