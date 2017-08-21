function cont = run_granger( signals, reg1, reg2, n_perms, varargin )

import dsp2.analysis.playground.*;

defaults.dist = 'wbl';
defaults.max_lags = 1e3;

params = dsp2.util.general.parsestruct( defaults, varargin );

chans = signals( 'channels', : );
reg1_chans = unique( chans(signals.where(reg1)) );
reg2_chans = unique( chans(signals.where(reg2)) );

prod = dsp2.util.general.allcomb( {reg1_chans, reg2_chans} );

switch ( params.dist )
  case 'wbl'
    fit_func = @wblfit;
    inv_func = @wblinv;
    n_dist_p = 2;
  case 'norm'
    fit_func = @normfit;
    inv_func = @norminv;
    n_dist_p = 2;
  case 'ev'
    fit_func = @evfit;
    inv_func = @evinv;
    n_dist_p = 2;
  otherwise
    error( 'Unrecognized distribution ''%s''', params.dist );
end

if ( size(prod, 1) > 16 )
  assert( size(prod, 1) == 256, 'Too many pairs.' );
  %   for consistency
  dsp2.util.general.seed_rng();
  prod = random_pairs( reg1_chans, reg2_chans, 16 );
  rng( 'shuffle' );
end

cont = cell( 1, size(prod, 1) );

for i = 1:size(prod, 1)
  fprintf( '\n Processing %d of %d', i, size(prod, 1) );
  row = prod(i, :);
  subset = signals.only( row );
  [granger, fitted, freqs, ids, C] = ...
    permuted_granger( subset, 'regions', n_perms, n_perms ...
      , 'fit_func', fit_func ...
      , 'inv_func', inv_func ...
      , 'n_dist_p', n_dist_p ...
      , 'max_lags', params.max_lags ...
    );
  data = struct( ...
      'granger', granger ...
    , 'fitted', fitted ...
    , 'freqs', freqs ...
    , 'ids', {ids} ...
    , 'C', C ...
  );
  collapsed = subset.one();
  collapsed.data = data;
  collapsed( 'channels' ) = strjoin( row, '_' );
  collapsed( 'regions' ) = strjoin( {reg1, reg2}, '_' );
  cont{i} = collapsed;
end

cont = extend( cont{:} );

end

function pairs = random_pairs(reg1, reg2, N)

pairs = cell( N, 2 );

for i = 1:N
  ind1 = randperm( numel(reg1), 1 );
  ind2 = randperm( numel(reg2), 1 );
  pairs(i, :) = [reg1(ind1), reg2(ind2)];
  reg1(ind1) = [];
  reg2(ind2) = [];
end

end