function [granger, fitted, freq_band_centers, ids, C] = permuted_granger(signals, var_specifiers, n_trials_per_perm, n_perms)

%   PERMUTED_GRANGER -- Calculate spectral Granger causality by repeated
%     sub-sampling.
%
%     [G, f, ids] = permuted_granger( signals, 'regions', 100, 1000 ) 
%     calculates spectral granger causality for each pair of labels in 
%     'regions', using 100 trials for each permutation, for 1000
%     permutations. 
%
%     Output `granger` is an MxNxPxQ array of granger values for M
%     variables, N variables, P frequencies, and Q permutations. `fitted` 
%     contains parameter estimates for the null distribution for each 
%     channel pair and frequency, as well as the function needed to 
%     calculate a p value from those parameters. `f` contains the 
%     frequencies at which each granger-stat was evaluated. `ids` identify 
%     the pairs of labels for which the granger-stat was evaluated. `C`
%     contains the indices used to construct the data in `fitted`.
%
%     IN:
%       - `signals` (SignalContainer)
%       - `var_specifiers` (cell array of strings, char)
%       - `n_trials_per_perm` (numeric)
%       - `n_perms` (numeric)
%     OUT:
%       - `granger` (Container)
%       - `fitted` (struct)
%       - `freq_band_centers` (double)
%       - `ids` (cell array of strings)
%       - `C` (double)

if ( nargin < 4 )
  n_perms = 1e3;
end
if ( nargin < 3 )
  n_trials_per_perm = 50;
end

if ( ~iscell(var_specifiers) ), var_specifiers = { var_specifiers }; end;

regression_method = 'LWR';
model_order = 32;

[X, ids] = dsp2.process.format.get_mvgc_data( signals, var_specifiers );

fs =          signals.fs;
n_vars =      size( X, 1 );
n_obs =       size( X, 2 );
n_trials =    size( X, 3 );
n_freqs =     fs;
max_lags =    1e3;
fit_func =    @normfit;
inv_func =    @norminv;
n_dist_p =    2;  % n parameters in the distribution

[granger, freq_band_centers] = calc_granger( false );
permuted_granger = calc_granger( true );

n_freqs = numel( freq_band_centers );

C = get_combinations( n_vars );

fitted = zeros( n_vars, n_vars, n_freqs, n_dist_p );

for ii = 1:size( C, 1 )
  chan1 = C( ii, 1 );
  chan2 = C( ii, 2 );
  for jj = 1:n_freqs
    pair = permuted_granger( chan1, chan2, jj, : );
    pair = squeeze( pair );
    [p1, p2] = fit_func( pair );
    fitted( chan1, chan2, jj, 1:n_dist_p ) = [p1, p2];
  end
end

fitted = struct( 'data', fitted, 'inverse_function', inv_func );

function [data, fres] = calc_granger( permute_per_variable )
  
  %   CALC_GRANGER -- Compute spectral granger causality.
  %
  %     IN:
  %       - `permute_per_variable` (logical) -- True if a different set of
  %         trials should be used for each channel / variable.
  %
  %     OUT:
  %       - `data` (double) -- Spectral granger causality, as an MxNxPxQ
  %         matrix of M variables, N variables, P frequencies, and Q
  %         permutations.
  
  for i = 1:n_perms
    if ( permute_per_variable )
      %   choose a different set of trials for each channel
      subset = zeros( n_vars, n_obs, n_trials_per_perm );
      for j = 1:n_vars
        index = randperm( n_trials, n_trials_per_perm );
        subset(j, :, :) = X( j, :, index );
      end
    else
      %   choose the same set of trials for each channel
      index = randperm( n_trials, n_trials_per_perm );
      subset = X( :, :, index );
    end
    [A, SIG] = tsdata_to_var( subset, model_order, regression_method );
    [G, ~] = var_to_autocov( A, SIG, max_lags );
    [spect, fres] = autocov_to_spwcgc( G, n_freqs );
    if ( i == 1 )
      data = zeros( n_vars, n_vars, size(spect, 3), n_perms );
    end
    data( :, :, :, i ) = spect;
  end
  fres = sfreqs( fres, fs );
end

end

function combinations = get_combinations( n_vars )

[a, b] = meshgrid( 1:n_vars, 1:n_vars );
c = cat( 2, a', b' );
combinations = reshape( c, [], 2 );

matching = combinations(:, 1) == combinations(:, 2);
combinations( matching, : ) = [];
[~, ind] = sort( combinations(:, 1) );
combinations = combinations( ind, : );

end