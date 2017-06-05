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

days = obj( 'days' );

labs = obj.labels;

for i = 1:numel(days)
  extr = labs.only( days{i} );
  channels = extr.get_fields( 'channels' );
  stp = 1;
  for k = 1:numel(channels)
    ind = labs.where( {days{i}, channels{k}} );
    labs = labs.set_field( 'sites', sprintf('site__%d', stp), ind );
    stp = stp + 1;
  end
end

obj.labels = labs;

end