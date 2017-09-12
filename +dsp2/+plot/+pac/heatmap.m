function heatmap(ax, pac)

assert__contains_fields( pac.labels, {'regions', 'amplitude_range', 'phase_range'} );
assert( numel(pac('regions')) == 1, 'There can only be one region.' );

assert( ax.isvalid, 'The axis is deleted.' );

ax_cmbs = pac.pcombs( {'amplitude_range', 'phase_range'} );

d = 10;

end