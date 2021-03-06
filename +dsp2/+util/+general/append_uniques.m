function str = append_uniques(obj, str, fs, join_char)

%   APPEND_UNIQUES -- Append unique labels in fields to a str.
%
%     IN:
%       - `obj` (Container, SparseLabels)
%       - `str` (char)
%       - `fs` (cell array of strings, char)
%       - `join_char` (char) |OPTIONAL|
%     OUT:
%       - `str` (char)

if ( nargin < 4 ), join_char = '_'; end

dsp2.util.assertions.assert__is_cellstr_or_char( fs, 'the categories' );
if ( ~isa(obj, 'SparseLabels') )
  dsp2.util.assertions.assert__isa( obj, 'Container', 'the object' );
  obj = obj.labels;
end

fs = dsp2.util.general.ensure_cell( fs );

dsp2.util.assertions.assert__isa( str, 'char' );

unqs = obj.flat_uniques( fs );

str = sprintf( '%s%s%s', str, join_char, strjoin(unqs, join_char) );

end