function obj = fix_channels(obj, map, conf)

%   FIX_CHANNELS -- For measures with site__%d numbers, fix channel numbers
%     so they reflect the actual pairs of channels associated with that
%     site.
%
%     IN:
%       - `obj` (Container, SparseLabels)
%       - `map` (struct) |OPTIONAL| -- Map which relates channels to sites.
%       - `conf` (struct) |OPTIONAL| -- Config file.
%     OUT:
%       - `obj` (Container, SparseLabels) -- Of the same class as the
%         inputted object.

import dsp2.util.assertions.*;

if ( nargin < 3 ), conf = dsp2.config.load(); end
if ( nargin < 2 ), map = dsp2.io.get_site_map(); end

is_cont = true;

if ( ~isa(obj, 'SparseLabels') )
  assert__isa( obj, 'Container', 'the object to process' );
  labs = obj.labels;
else
  is_cont = false;
  labs = obj;
end

assert__isa( map, 'struct', 'the channel map' );
assert__isa( conf, 'struct', 'the config file' );

assert__contains_fields( labs, {'channels', 'sites'} );

channels = labs.full_fields( 'channels' );

chan_inds = strcmp( labs.categories, 'channels' );
labs.categories( chan_inds ) = [];
labs.labels( chan_inds ) = [];
labs.indices(:, chan_inds) = [];

days = labs.flat_uniques( 'days' );

for i = 1:numel(days)
  map_ind = strcmp( map.days, days{i} );
  chans = map.channel_map{ map_ind };
  map_sites = chans(:, 1);
  map_chans = chans(:, 2);
  for k = 1:numel(map_sites)
    site_ind = labs.where( {days{i}, map_sites{k}} );
    assert( any(site_ind), 'No sites matched the given site map.' );
    lab_ind = strcmp( labs.labels, map_chans{k} );
    if ( any(lab_ind) )
      labs.indices(:, lab_ind) = labs.indices(:, lab_ind) | site_ind;
    else
      labs.labels{end+1, 1} = map_chans{k};
      labs.categories{end+1, 1} = 'channels';
      labs.indices(:, end+1) = site_ind;
    end
    channels( site_ind ) = map_chans(k);
  end
end

if ( ~is_cont )
  obj = labs; 
  return;
end

obj.labels = labs;

end