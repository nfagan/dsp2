function define_site_pairs(P, conf)

%   DEFINE_SITE_PAIRS -- Establish channel-pairs, up to 16, for each day.
%
%     ... define_site_pairs( '/Signals/none/complete/reward' ) reads labels
%     in the given dataset path. The labels in this path identify the
%     channels x regions x days combinations from which to draw pairs.
%
%     See also dsp2.process.format.select_site_pairs
%
%     IN:
%       - `P` (char) -- Path to the dataset to use to determine the
%         channels for each day.
%       - `conf` (struct) |OPTIONAL| -- Config file.

if ( nargin < 2 ), conf = dsp2.config.load(); end

fname = fullfile( conf.PATHS.database, 'pairs.mat' );

io = dsp2.io.get_dsp_h5( 'config', conf );

labs = io.read_labels_( P );
cont = Container( zeros(shape(labs, 1), 1), labs );

pairs = dsp2.process.format.select_site_pairs( cont );

save( fname, 'pairs' );

end