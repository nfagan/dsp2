function result = measure_vs_preference_simple( obj, N, label_a, label_b )

import dsp2.util.assertions.*;
assert__isa( obj, 'SignalContainer' );
assert__isa( N, 'double' );
assert( isscalar(N), 'Number of trials must be scalar.' );
assert( all(obj.contains({label_a, label_b})), ['At least one of' ...
  , ' the given labels does not exist.'] );
assert( ismatrix(obj.data) && size(obj.data, 2) == 1, ...
  'Data must be a vector.' );

ids = 1:shape( obj, 1 );

result = Container();

while ( ~isempty(ids) )
  next = N;
  
  if ( next * 2 > numel(ids) )
    next = numel(ids);
  end
  
  subset = ids(1:next);
  
  extr = obj( subset );
  
  ind_label_a = extr.where( label_a );
  ind_label_b = extr.where( label_b );
  
  numel_a = sum( ind_label_a );
  numel_b = sum( ind_label_b );
  pref_ind = ( numel_a - numel_b ) / ( numel_a + numel_b );
  pref_ind = full( pref_ind );
  
  extr( 'outcomes' ) = sprintf( '%s_minus_%s', label_a, label_b );
  res = extr.one();
  res.data = pref_ind;
  res = res.require_fields( 'measure' );
  res( 'measure' ) = 'preference_index';
  
  result = result.append( res );
  
  res.data = mean( extr.data(ind_label_a) ) - mean( extr.data(ind_label_b) );
  res( 'measure' ) = 'signal_measure';
  
  result = result.append( res );
  
  ids(1:next) = [];
end


end