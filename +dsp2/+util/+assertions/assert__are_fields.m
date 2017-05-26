function assert__are_fields( S, F )

%   ASSERT__ARE_FIELDS -- Ensure a struct has a number of required fields.
%
%     IN:
%       - `S` (struct) -- Struct to validate.
%       - `F` (cell array of strings, char) -- Required fields.

if ( ~iscell(F) ), F = { F }; end;
dsp2.util.assertions.assert__isa( S, 'struct' );
fs = fieldnames( S );
msg = 'The required field ''%s'' does not exist.';
cellfun( @(x) assert(any(strcmp(fs, x)), msg, x), F );

end