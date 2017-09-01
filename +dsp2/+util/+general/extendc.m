function obj = extendc( arr )

%   EXTENDC -- Extend a cell array of Container objects.
%
%     obj = ... extendc( {obj1, obj2, obj3} ) returns `obj`, the
%     concatenated array of Container objects `obj1`, `obj2` ... . All
%     values in the array must be Container objects with the same subclass.
%
%     ... extendc( {} ) returns an empty cell array {}.
%
%     IN:
%       - `arr` (cell array of Container objects, {})
%     OUT:
%       - `obj` (Container, SignalContainer, {})

obj = dsp2.util.general.concat( arr );

end