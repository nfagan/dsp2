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

import dsp2.util.assertions.*;
assert__isa( arr, 'cell', 'the array' );
if ( isempty(arr) ), obj = {}; return; end
classes = cellfun( @class, arr, 'un', false );
assert( numel(unique(classes)) == 1 && isa(arr{1}, 'Container'), ...
  'Each element in the array must be a Container of the same subclass.' );
obj = extend( arr{:} );

end