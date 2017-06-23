function out = oxy_minus_sal(obj, to_collapse)

%   OXY_MINUS_SAL -- Subtract saline data from oxytocin data.
%
%     IN:
%       - `obj` (Container, SignalContainer)
%       - `to_collapse` (cell array of strings, char) -- Fields to collapse
%         before subtracting 'oxytocin' - 'saline'
%     OUT:
%       - `out` (Container, SignalContainer)    

if ( nargin < 2 )
  to_collapse = { 'drugs' };
end

dsp2.util.assertions.assert__isa( obj, 'Container', 'the object' );

obj.labels.assert__contains_labels( {'oxytocin', 'saline'} );

oxy = obj.only( 'oxytocin' );
sal = obj.only( 'saline' );

out = oxy.opc( sal, to_collapse, @minus );

out( 'drugs' ) = 'oxyMinusSal';

end