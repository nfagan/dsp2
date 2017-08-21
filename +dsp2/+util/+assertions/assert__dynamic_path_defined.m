function assert__dynamic_path_defined( identifier, conf )

%   ASSERT__DYNAMIC_PATH_DEFINED -- Ensure a dynamic path has been defined.
%
%     assert__dynamic_path_defined( 'granger' ) loads the config file, and
%     ensures that 'granger' is a field of PATHS.dynamic.
%
%     assert__dynamic_path_defined( ..., conf ) uses the config file `conf`
%     instead of the saved config file.
%
%     IN:
%       - `identifier` (char) -- Field of conf.PATHS.dyanmic
%       - `conf` (struct) |OPTIONAL| -- Config file.

if ( nargin < 2 ), conf = dsp2.config.load(); end

import dsp2.util.assertions.*;

try
  assert__isa( identifier, 'char', 'the dynamic path field' );
  assert__isa( conf, 'struct', 'the config file' );
  assert__are_fields( conf.PATHS, 'dynamic' );
  assert__isa( conf.PATHS.dynamic, 'struct', 'the dyanmic paths' );
  assert__are_fields( conf.PATHS.dynamic, identifier );
catch err
  throwAsCaller( err );
end

end