function all_g = get_granger_confidence_interval(g, iteration)

for i = 1:numel(g)
  
end

data = g.data;
required_fields = { 'granger', 'fitted', 'freqs', 'ids', 'C' };
dsp2.util.assertions.assert__are_fields( data, required_fields );

labs = g.field_label_pairs();

G = data.granger;
fitted = data.fitted;
freqs = data.freqs;
ids = data.ids;
C = data.C;

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
real_g = zeros( n_combs, n_freqs );
p_vals = zeros( n_combs, n_freqs );

all_ids = cell( NC, 1 );

for j = 1:NC
  idc = C(j, :);
  all_ids{j} = strjoin( ids(idc), ' to ' );
  for i = 1:n_freqs
    ps = params( idc(1), idc(2), i, : );
    ps = squeeze( ps );
    ps = ps(:)';
    switch ( func_name )
      case 'wblinv'
        %   make into cell so that all parameters can be pasesd into inv_func
        %   without needing to hard-code the number of inputs to inv_func.
        ps = arrayfun( @(x) x, ps, 'un', false );
        conf_level( j, i ) = inv_func( inv_p, ps{:} );
        real_g( j, i ) = G_mean( idc(1), idc(2), i );
      case 'norminv'
        real_data = G_mean( idc(1), idc(2), i );
        z = (real_data - ps(1)) / ps(2);
        real_g( j, i ) = z;
        p_vals( j, i ) = 2 * normcdf( -abs(z), 0, 1 );
      otherwise
        error( 'Unrecognized inverse function ''%s''.', func_name );
    end
  end
end

conf_level = Container( conf_level, labs{:} );
real_g = Container( real_g, labs{:} );
conf_level = conf_level.add_field( 'kind', 'confidence_interval' );
real_g = real_g.add_field( 'kind', 'real_granger' );
real_g( 'regions' ) = all_ids;
conf_level( 'regions' ) = all_ids;

G = append( conf_level, real_g );
G = SignalContainer( G.data, G.labels );
G.frequencies = freqs;

end