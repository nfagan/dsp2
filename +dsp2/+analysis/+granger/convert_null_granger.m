function obj = convert_null_granger(obj)

%   CONVERT_NULL_GRANGER -- Convert an object whose data are an array of
%     struct to an object whose data are an MxN double array of M
%     observations by N frequencies.
%
%     IN:
%       - `obj` (SignalContainer)
%     OUT:
%       - `obj` (SignalContainer)

dsp2.util.assertions.assert__isa( obj, 'SignalContainer' );

objs = cell( 1, shape(obj, 1) );

parfor i = 1:shape(obj, 1)
  current = obj(i);
  labs = current.labels;
  data = current.data;
  granger = data.granger;
  assert( size(granger, 4) == 1, 'Cannot have more than one permutation.' );
  C = data.C;
  ids = data.ids;
  freqs = data.freqs;
  new_data = zeros( size(C, 1), numel(freqs) );
  new_labs = SparseLabels();
  for k = 1:size(C, 1)
    cmb = C(k, :);
    g = squeeze( granger( cmb(1), cmb(2), : ) );
    id_str = strjoin( [ids(cmb(1)), ids(cmb(2))], '_' );
    labs = labs.set_field( 'regions', id_str );
    new_labs = new_labs.append( labs );
    new_data(k, :) = g;
  end
  new_obj = SignalContainer( new_data, new_labs );
  new_obj.frequencies = freqs;
  objs{i} = new_obj;
end

obj = extend( objs{:} );
obj = obj.require_fields( 'kind' );
obj( 'kind' ) = 'real_granger';

end