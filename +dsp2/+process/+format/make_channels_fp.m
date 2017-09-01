function obj = make_channels_fp(obj)

%   MAKE_CHANNELS_FP -- Ensure channel labels begin with 'FP' and not 'WB'.
%
%     IN:
%       - `obj` (Container, SparseLabels)
%     OUT:
%       - `obj` (Container, SparseLabels)

import dsp2.util.assertions.*;

was_container = false;

if ( ~isa(obj, 'SparseLabels') )
  assert__isa( obj, 'Container', 'the object to fix' );
  labels = obj.labels;
  was_container = true;
else
  labels = obj;
end

chan_ind = strcmp( labels.categories, 'channels' );
assert( any(chan_ind), 'Required category ''channels'' is missing.' );
labs = labels.labels( chan_ind );
fix_fun = @(x) strrep( x, 'WB', 'FP' );
labs = cellfun( fix_fun, labs, 'un', false );
labels.labels( chan_ind ) = labs;

if ( was_container )
  obj.labels = labels;
else
  obj = labels;
end

end