function print_process(arr, index, prepend)

if ( nargin < 3 ), prepend = ''; end

fprintf( '\n%s Processing %s (%d of %d)', prepend, arr{index}, index, numel(arr) );

end