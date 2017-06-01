function prepended = prepend(arr, val)

%   PREPEND -- Prepend a char value to a char value or cell array of
%     strings.
%
%     IN:
%       - `arr` (cell array of strings, char)
%       - `val` (char) -- Value to prepend.

dsp2.util.assertions.assert__isa( val, 'char', 'the value to prepend' );

func = @(x) [ val, x ];

if ( iscell(arr) )
  dsp2.util.assertions.assert__is_cellstr( arr );
  prepended = cellfun( @(x) func(x), arr, 'un', false );
else
  dsp2.util.assertions.assert__isa( arr, 'char' );
  prepended = func( arr );
end

end