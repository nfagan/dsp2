function obj = fix_sites(obj)

%   FIX_SITES -- Make each day's 'sites' labels reflect unique values for
%     each channel.
%
%     IN:
%       - `obj` (Container, SignalContainer)
%     OUT:
%       - `obj` (Container, SignalContainer)

dsp2.util.assertions.assert__isa( obj, 'Container', 'the object to fix' );
obj.labels.assert__categories_exist( {'channels', 'days'} );

if ( ~obj.labels.contains_fields('sites') )
  obj = obj.add_field( 'sites' );
end

labs = obj.labels;

days = labs.get_fields( 'days' );

new_labs = SparseLabels();

for i = 1:numel(days)
  
  extr = labs.only( days{i} );
  inds = extr.get_indices( 'channels' );
  
  for k = 1:numel(inds)
    extr = extr.set_field( 'sites', sprintf('site__%d', k), inds{k} );
  end
  
  new_labs = new_labs.append( extr );
end

obj.labels = new_labs;

end