function obj = require_labels(obj, within, values)

%   REQUIRE_LABELS -- Remove elements that do not contain labels.
%
%     obj = ... require_labels(obj, 'days', obj('outcomes')) will, for each
%     'days', check if all 'outcomes' are present. If they are not, that
%     day will be removed from the output 'obj'.
%
%     IN:
%       - `obj` (Container, SignalContainer)
%       - `within` (cell array of strings, char)
%       - `values` (cell array of strings)
%     OUT:
%       - `obj` (Container, SignalContainer)

import dsp2.util.assertions.*;

assert__isa( obj, 'Container', 'the object' );
assert__is_cellstr_or_char( within );
assert__is_cellstr( values, 'the values to search for' );

inds = obj.get_indices( within );
to_keep = obj.logic( true );
for i = 1:numel(inds)
  for j = 1:size(values, 1)
    val_ind = inds{i} & obj.where( values(j, :) );
    if ( ~any(val_ind) )
      to_keep( inds{i} ) = false;
      break;
    end
  end
end

obj = obj.keep( to_keep );

end

