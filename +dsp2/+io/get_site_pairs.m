function pairs = get_site_pairs(conf)

%   GET_SITE_PAIRS -- Load previously generated site pairs.
%
%     IN:
%       - `conf` (struct) |OPTIONAL| -- Config file.
%     OUT:
%       - `pairs` (struct)

if ( nargin < 1 ), conf = dsp2.config.load(); end
dsp2.util.assertions.assert__isa( conf, 'struct', 'the config file' );
fname = fullfile( conf.PATHS.database, 'pairs.mat' );
try
  dsp2.util.assertions.assert__file_exists( fname );
catch err
  error( ['No pairs.mat file was found in %s. Use dsp2.io.define_site_pairs()' ...
    , ' to generate the file.'], conf.PATHS.database );
end
pairs = dsp2.util.general.fload( fname );

end