function cont = convert_granger( G )

%   CONVERT_GRANGER -- Convert the raw output of `permuted_granger` to a
%   	Container whose data are an MxN array of M observations by N
%   	frequencies.
%
%     cont = ... convert_granger( G ) takes the fitted distribution
%     parameters and permuted Granger values from `permuted_granger` and
%     calculates confidence intervals and real Granger statistics with
%     respect to frequency. Each row of `cont` is either a confidence
%     interval or Granger stat associated with a given region-to-region
%     pair.
%
%     IN:
%       - `G` (Container, SignalContainer)
%     OUT:
%       - `cont` (SignalContainer)

cont = Container();

for i = 1:shape(G, 1)
  cont = cont.append( for_one(G(i)) );
end

end

function G = for_one(g)

%   FOR_ONE -- Perform the conversion for a single element of `G`.
%
%     IN:
%       - `g` (Container) -- 1x1 Container whose data are struct.
%     OUT:
%       - `G` (Container) -- MxN Container 

data = g.data;
required_fields = { 'granger', 'fitted', 'freqs', 'ids', 'C' };
dsp2.util.assertions.assert__are_fields( data, required_fields );

G = real( data.granger );
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
    real_data = G_mean( idc(1), idc(2), i );
    switch ( func_name )
      case { 'wblinv', 'evinv' }
        %   make into cell so that all parameters can be pasesd into inv_func
        %   without needing to hard-code the number of inputs to inv_func.
        ps = arrayfun( @(x) x, ps, 'un', false );
        conf_level( j, i ) = inv_func( inv_p, ps{:} );
        real_g( j, i ) = real_data;
      case 'norminv'
        z = (real_data - ps(1)) / ps(2);
        real_g( j, i ) = z;
        p_vals( j, i ) = 2 * normcdf( -abs(z), 0, 1 );
      otherwise
        error( 'Unrecognized inverse function ''%s''.', func_name );
    end
  end
end

labs = g.field_label_pairs();
conf_level = Container( conf_level, labs{:} );
real_g = Container( real_g, labs{:} );
conf_level = conf_level.add_field( 'kind', 'null_distribution' );
real_g = real_g.add_field( 'kind', 'real_granger' );
real_g( 'regions' ) = all_ids;
conf_level( 'regions' ) = all_ids;

G = append( conf_level, real_g );
G = SignalContainer( G.data, G.labels );
G.frequencies = freqs;

end