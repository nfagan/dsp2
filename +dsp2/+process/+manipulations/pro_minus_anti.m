function out = pro_minus_anti(obj, to_collapse)

%   PRO_MINUS_ANTI -- Subtract (selfMinusBoth) from (otherMinusNone).
%
%     IN:
%       - `obj` (Container, SignalContainer)
%       - `to_collapse` (cell array of strings, char) -- Fields to collapse
%         before subtracting
%     OUT:
%       - `out` (Container, SignalContainer)

if ( nargin < 2 )
  to_collapse = { 'outcomes' };
end

dsp2.util.assertions.assert__isa( obj, 'Container', 'the object' );

obj.labels.assert__contains_labels( {'selfMinusBoth', 'otherMinusNone'} );

sb = obj.only( 'selfMinusBoth' );
on = obj.only( 'otherMinusNone' );

out = on.opc( sb, to_collapse, @minus );
out( 'outcomes' ) = 'proMinusAnti';

end