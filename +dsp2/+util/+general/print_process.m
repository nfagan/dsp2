function print_process(arr, index, prepend)

if ( nargin < 3 ), prepend = ''; end
str = strjoin( arr(index, :), ', ' );
fprintf( '\n%s Processing %s (%d of %d)', prepend, str, index, size(arr, 1) );

end