function plot_granger( G, fitted, freqs, ids, C )

G_mean = mean( G, 4 );

inv_func = fitted.inverse_function;
func_name = func2str( inv_func );

params = fitted.data;

p_value = 0.001;
n_freqs = numel( freqs );
inv_p = 1 - p_value;
n_combs = size( C, 1 );
conf_level = zeros( n_combs, n_freqs );
NC = size( C, 1 );
z_scored = zeros( n_combs, n_freqs );
p_vals = zeros( n_combs, n_freqs );

for i = 1:n_freqs
  for j = 1:NC
    idc = C(j, :);
    ps = params( idc(1), idc(2), i, : );
    ps = squeeze( ps );
    ps = ps(:)';
    switch ( func_name )
      case 'wblinv'
        %   make into cell so that all parameters can be pasesd into inv_func
        %   without needing to hard-code the number of inputs to inv_func.
        ps = arrayfun( @(x) x, ps, 'un', false );
        conf_level( j, i ) = inv_func( inv_p, ps{:} );
      case 'norminv'
        real_data = G_mean( idc(1), idc(2), i );
        z = (real_data - ps(1)) / ps(2);
        z_scored( j, i ) = z;
        p_vals( j, i ) = 2 * normcdf( -abs(z), 0, 1 );
      otherwise
        error( 'Unrecognized inverse function ''%s''.', func_name );
    end
  end
end

if ( strcmp(func_name, 'norminv') )
  figure(1);
  clf();

  nrows = floor( sqrt(NC) );
  ncols = 1 + NC - nrows^2;

  h = gobjects( NC, 1 );

  for i = 1:NC  
    h(i) = subplot( nrows, ncols, i );

    pair_ind = C(i, :);
    pair_ids = ids( [pair_ind(1), pair_ind(2)] );
    pair_id = sprintf( '%s to %s', pair_ids{1}, pair_ids{2} );

    z = z_scored(i, :);

    hold off;
    plot( freqs, z );

    title( pair_id );
  end

  arrayfun( @(x) xlim(x, [0, 100]), h );
  lims = cell2mat( get(h, 'ylim') );
  lims = [ min(lims(:)), max(lims(:)) ];
  arrayfun( @(x) ylim(x, lims), h );
end

%{
  weibull
%}

if ( strcmp(func_name, 'wblinv') )
  
  figure(1);
  clf();

  nrows = floor( sqrt(NC) );
  ncols = 1 + NC - nrows^2;

  h = gobjects( NC, 1 );

  for i = 1:NC  
    h(i) = subplot( nrows, ncols, i );

    pair_ind = C(i, :);
    pair_ids = ids( [pair_ind(1), pair_ind(2)] );
    pair_id = sprintf( '%s to %s', pair_ids{1}, pair_ids{2} );

    conf_level_ = conf_level(i, :);
    real_g = squeeze( G_mean(pair_ind(1), pair_ind(2), :) );

    hold off;
    plot( freqs, conf_level_, 'r' );
    hold on;
    plot( freqs, real_g, 'b' );
    legend( {'Confidence Interval', 'Real data'} );

    title( pair_id );
  end

  arrayfun( @(x) xlim(x, [0, 100]), h );
  lims = cell2mat( get(h, 'ylim') );
  lims = [ min(lims(:)), max(lims(:)) ];
  arrayfun( @(x) ylim(x, lims), h );
end

end