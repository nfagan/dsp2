function aligned_spikes = align_spikes( spike_vec, align_mat, align_key )

import shared_utils.assertions.*;

assert__isa( spike_vec, 'double' );
assert__is_vector( spike_vec );
assert__isa( align_mat, 'double' );
assert__is_cellstr( align_key );
assert( numel(align_key) == size(align_mat, 2), 'The align key does not match the align matrix.' );
required_keys = { 'plex', 'picto' };

for i = 1:numel(required_keys)
  assert( any(strcmpi(align_key, required_keys{i})) ...
    , 'Required key ''%s'' was not present.', required_keys{i} );
end

plex_ind = strcmp( align_key, 'plex' );
picto_ind = strcmp( align_key, 'picto' );

plex_times = align_mat(:, plex_ind);
picto_times = align_mat(:, picto_ind);
min_plex = min( plex_times );
max_plex = max( plex_times );

aligned_spikes = nan( size(spike_vec) );

for i = 1:numel(spike_vec)
  
  spk = spike_vec(i);
  
  if ( spk < min_plex || spk > max_plex ), continue; end
  
  [~, ind] = min( abs(plex_times - spk) );
  offset = plex_times(ind) - spk;
  aligned_spikes(i) = picto_times(ind) + offset;
  
end


end