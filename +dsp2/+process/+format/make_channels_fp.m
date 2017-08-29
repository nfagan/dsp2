function obj = make_channels_fp(obj)

%   MAKE_CHANNELS_FP -- Ensure channel labels are 'FP' and not 'WB'

import dsp2.util.assertions.*;

was_container = false;

if ( ~isa(obj, 'SparseLabels') )
  labs = obj.labels;
else
  assert__isa( obj, 'Container', 'the object to fix' );
  labs = obj;
  was_container = true;
end

assert__contains_fields( labs, 'channels' );

chan_ind = strcmp( labs.categories, 'channels' );
labs = labs.labels( chan_ind );
fix_fun = @(x) strrep( x, 'WB', 'FP' );
labs = cellfun( fix_fun, labs, 'un', false );
labs.labels( chan_ind ) = labs;

if ( was_container )
  obj.labels = labs;
end


end