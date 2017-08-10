function add_depends(conf)

%   ADD_DEPENDS -- Add dependencies to Matlab's search path.s
%
%     IN:
%       - `conf` (struct) |OPTIONAL|

if ( nargin < 1 ), conf = dsp2.config.load(); end

dependencies = conf.DEPENDENCIES;
repo_dir = conf.PATHS.repositories;

for i = 1:numel(dependencies)
  depend = dependencies{i};
  full_path = fullfile( repo_dir, depend );
  assert( exist(full_path, 'dir') == 7, ['The required dependency ''%s''' ...
    , ' was not found in ''%s''.'], depend, full_path );
  addpath( genpath(full_path) );
end

end