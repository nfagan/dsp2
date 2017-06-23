function obj = fix_site_ids(obj)

%   FIX_SITE_IDS -- Ensure the object has a sitesxdays field in which each
%     sitesxdays label is unique across sites and days.
%
%     IN:
%       - `obj` (Container, SignalContainer)
%     OUT:
%       - `obj` (Container, SignalContainer)

dsp2.util.assertions.assert__isa( obj, 'Container', 'the object to fix' );
assert__categories_exist( obj.labels, {'days', 'sites'} );

field_name = 'sitesxdays';

obj = obj.require_fields( field_name );

days = obj( 'days' );
labs = obj.labels;

stp = 1;

for i = 1:numel( days )
  extr = labs.only( days{i} );
  sites = extr.get_fields( 'sites' );
  for j = 1:numel(sites)
    ind = labs.where( {days{i}, sites{j}} );
    obj( field_name, ind ) = sprintf( '%s__%d', field_name, stp );
    stp = stp + 1;
  end
end



end