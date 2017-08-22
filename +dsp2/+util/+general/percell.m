function arr = percell(func, arr)

%   PERCELL -- Cellfun, but assume cell (non-uniform) output.
%
%     arr = ... percell( @mean, {[10; 11], [11, 12]} ); is equivalent to 
%     ... cellfun( ..., 'un', false );
%
%     IN:
%       - `func` (function_handle)
%       - `arr` (cell)
%     OUT:
%       - `arr` (cell)

arr = cellfun( func, arr, 'un', false );

end