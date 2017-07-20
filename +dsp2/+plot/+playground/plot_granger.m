function plot_granger( G, fitted, freqs, ids, C )

G = mean( G, 4 );

inv_func = fitted.inverse_function;

params = fitted.data;

p_value = 0.001;
n_freqs = numel( freqs );
inv_p = 1 - p_value;
n_combs = size( C, 1 );
conf_level = zeros( n_combs, n_freqs );

for i = 1:n_freqs
  for j = 1:size( C, 1 )
    ps = params( C(j, 1), C(j, 2), i, : );
    ps = squeeze( ps );
    ps = ps(:)';
    ps = arrayfun( @(x) x, ps, 'un', false );
    conf_level( j, i ) = inv_func( inv_p, ps{:} );
  end
end

d = 10;

end