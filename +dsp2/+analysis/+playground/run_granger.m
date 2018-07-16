function cont = run_granger( signals, reg1, reg2, n_trials_per_perm, n_perms, varargin )

import dsp2.analysis.playground.*;

defaults.dist = 'wbl';
defaults.max_lags = 1e3;
defaults.do_permute = true;
defaults.estimate_model_order = false;
defaults.fs_divisor = 1;

params = dsp2.util.general.parsestruct( defaults, varargin );

assert( numel(signals('days')) == 1, 'There can only be one day present.' );

pairs = dsp2.io.get_site_pairs();
day_ind = strcmp( pairs.days, signals('days') );
assert( any(day_ind), 'Unrecognized day %s', char(signals('days')) );
col1_ind = strcmp( pairs.channel_key, reg1 );
col2_ind = strcmp( pairs.channel_key, reg2 );
chans = pairs.channels{ day_ind };

assert( any(col1_ind) && any(col2_ind), ['Expected regions to be one' ...
  , ' of these kinds: ''%s''.'], strjoin(pairs.channel_key, ', ') );

prod = [ chans(:, col1_ind), chans(:, col2_ind) ];
assert( size(prod, 1) <= 16, 'Expected fewer than 16 pairs; got %d', size(prod, 1) );

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

cont = cell( 1, size(prod, 1) );

for i = 1:size(prod, 1)
  fprintf( '\n Processing %d of %d', i, size(prod, 1) );
  row = prod(i, :);
  subset = signals.only( row );
  [granger, fitted, freqs, ids, C] = ...
    permuted_granger( subset, 'regions', n_trials_per_perm, n_perms ...
      , 'fit_func', fit_func ...
      , 'inv_func', inv_func ...
      , 'n_dist_p', n_dist_p ...
      , 'max_lags', params.max_lags ...
      , 'do_permute', params.do_permute ...
      , 'estimate_model_order', params.estimate_model_order ...
      , 'fs_divisor', params.fs_divisor ...
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