function obj = rm_bad_days( obj )

import dsp2.util.assertions.*;

assert__isa( obj, 'Container' );

obj = obj.rm( dsp2.process.format.get_bad_days() );
  
end