function out = pro_v_anti(obj, to_collapse)

%   PRO_V_ANTI -- Compare (self-both) vs. (other-none).
%
%     IN:
%       - `obj` (Container, SignalContainer)
%       - `to_collapse` (cell array of strings, char) -- Fields to collapse
%         before subtracting ('self'-'both') and ('other'-'none')
%     OUT:
%       - `out` (Container, SignalContainer)

if ( nargin < 2 )
  to_collapse = { 'outcomes' };
end

dsp2.util.assertions.assert__isa( obj, 'Container', 'the object' );

obj.labels.assert__contains_labels( {'self', 'both', 'other', 'none'} );

self =  obj.only( 'self' );
both =  obj.only( 'both' );
other = obj.only( 'other' );
none =  obj.only( 'none' );

self = self.opc( both, to_collapse, @minus );
other = other.opc( none, to_collapse, @minus );

self( 'outcomes' ) = 'selfMinusBoth';
other( 'outcomes' ) = 'otherMinusNone';

out = self.append( other );

end