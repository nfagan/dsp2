function grouped = group_cell( arr, nper )

%   GROUP_CELL -- Group elements of a cell array.
%
%     IN:
%       - `arr` (cell) -- Elements to group.
%       - `nper` (double) -- N per group.
%     OUT:
%       - `grouped` (cell)

import dsp2.util.assertions.*;

N = numel( arr );

if ( N == 0 ), grouped = {}; return; end

assert__isa( arr, 'cell', 'the array-to-group' );
if ( isa(nper, 'char') )
  assert( strcmp(nper, 'all'), ['If the elements per group is not ''all''' ...
    , ', it must be a double.'] );
  nper = numel( arr );
else
  assert__is_scalar( nper, 'the elements per group' );
  assert__isa( nper, 'double', 'the elements per group' );
  assert( nper <= numel(arr) && nper > 0, ['Expected the number of' ...
    , ' elements per group to be greater than 0 and less than %d.'] ...
    , numel(arr) );
end

n_groups = floor( N / nper );
one_leftover = mod( N, nper ) ~= 0;
stp = 1;
grouped = cell( 1, n_groups );

for i = 1:n_groups
  grouped{i} = arr(stp:stp+nper-1);
  stp = stp + nper;
end

if ( one_leftover )
  grouped{end+1} = arr(stp:end);
end

end