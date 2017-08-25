function define_site_map(P, conf)

%   DEFINE_SITE_MAP -- Construct a map that relates site__%d labels to
%     chan1_chan2 pairs.
%
%     IN:
%       - `P` (char) -- H5 path from which to sample labels.
%       - `conf` (struct) |OPTIONAL|

if ( nargin < 2 ), conf = dsp2.config.load(); end

import dsp2.util.assertions.*;

assert__isa( P, 'char', 'the sample path string' );
assert__isa( conf, 'struct', 'the config file' );

io = dsp2.io.get_dsp_h5( 'config', conf );

fname = fullfile( conf.PATHS.database, 'site_map.mat' );

sample = io.read_labels_( P );
sample = Container( sparse(zeros(shape(sample, 1), 1)), sample );

days = sample( 'days' );
sample_channels = sample( 'channels', : );

map = struct();

chan_map = cell( size(days) );

for i = 1:numel(days)
  bla_chans = unique( sample_channels(sample.where({days{i}, 'bla'})) );
  acc_chans = unique( sample_channels(sample.where({days{i}, 'acc'})) );
  product = dsp2.util.general.allcomb( {bla_chans, acc_chans} );
  current = cell( size(product, 1), 2 );
  for k = 1:size(product, 1)
    site_str = sprintf( 'site__%d', k );
    current{k, 1} = site_str;
    current{k, 2} = strjoin( product(k, :), '_' );
  end
  chan_map{i} = current;
end

map.days = days;
map.channel_map = chan_map;
map.channel_key = { 'bla', 'acc' };

save( fname, 'map' );

end