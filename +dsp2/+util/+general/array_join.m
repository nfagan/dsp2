function out_arr = array_join(arr, join_char)

%   ARRAY_JOIN -- Join an MxN cell array of strings, column-wise.
%
%     IN:
%       - `arr` (cell array of strings)
%       - `join_char` (char)
%     OUT:
%       - `out_arr` (cell array of strings)

import dsp2.util.assertions.*;

if ( nargin < 2 )
  join_char = ', ';
end

assert__is_cellstr( arr, 'the array' );
assert__isa( join_char, 'char', 'the join character' );

out_arr = cell( size(arr, 1), 1 );

for i = 1:size(out_arr, 1)
  out_arr{i} = strjoin( arr(i, :), join_char );
end

end