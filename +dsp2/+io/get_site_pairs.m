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
dsp2.util.assertions.assert__file_exists( fname, 'the channel pairs file' );
pairs = dsp2.util.general.fload( fname );

end