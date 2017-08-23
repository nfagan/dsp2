function obj = subsample_sites(obj)

%   SUBSAMPLE_SITES -- For 256-site days, subsample sites such that each
%     bla site site is randomly paired with one acc site.
%
%     For consistency, you will want to call ... seed_rng() before calling
%     this function.
%
%     IN:
%       - `obj` (SignalContainer)
%     OUT:
%       - `obj` (SignalContainer)

sites = obj( 'sites' );
n_present = numel( sites );

if ( n_present <= 16 ), return; end

assert( n_present == 256, 'Not yet adapted to work with multiple-regions.' );

nsite = numel( 'site__' );
nums = cellfun( @(x) str2double(x(nsite+1:end)), sites );
[~, ind] = sort( nums );
sites = sites( ind );

new_sites = cell( 1, 16 );
stp = 1;

for i = 1:16
  inds = stp:stp+16-1;
  j = datasample( inds, 1 );
  new_sites{i} = sites{j};
  stp = stp + 16;
end

obj = obj.only( new_sites );

end