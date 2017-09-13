function heatmap(ax, pac)

assert__contains_fields( pac.labels, {'regions', 'amplitude_range', 'phase_range'} );
assert( numel(pac('regions')) == 1, 'There can only be one region.' );

assert( ax.isvalid, 'The axis is deleted.' );

phase_ranges = pac( 'phase_range' );
amp_ranges = pac( 'amplitude_range' );

data = nan( numel(phase_ranges), numel(amp_ranges) );
xs = repmat( (1:size(data, 1))', 1, size(data, 2) );

for i = 1:numel(phase_ranges)
  phase_range = phase_ranges{i};
  for j = 1:numel(amp_ranges)
    amp_range = amp_ranges{j};
    ind = pac.where( {phase_range, amp_range} );
    if ( ~any(ind) ), continue; end
    assert( sum(ind) == 1, 'Too many trials requested.' );
    data(i, j) = pac.data(ind);
  end
end

% xs = flipud( xs );
data = flipud( data );
amp_ranges = flipud( amp_ranges(:) );

h = imagesc( xs, 'CData', data, 'parent', ax );
colormap( 'jet' );
color_bar = colorbar;
set( ax, 'xtick', xs(:, 1) );
set( ax, 'ytick', xs(:, 2) );
set( ax, 'xticklabel', phase_ranges );
set( ax, 'yticklabel', amp_ranges );

end