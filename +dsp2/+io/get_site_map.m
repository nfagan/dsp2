function map = get_site_map(conf)

%   GET_SITE_MAP -- Load previously generated site map.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- Config file.
%     OUT:
%       - `pairs` (struct)

if ( nargin < 1 ), conf = dsp2.config.load(); end
dsp2.util.assertions.assert__isa( conf, 'struct', 'the config file' );
fname = fullfile( conf.PATHS.database, 'site_map.mat' );
try
  dsp2.util.assertions.assert__file_exists( fname );
catch err
  error( ['No pairs.mat file was found in %s. Use dsp2.io.define_site_map()' ...
    , ' to generate the file.'], conf.PATHS.database );
end
map = dsp2.util.general.fload( fname );

end