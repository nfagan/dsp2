function others = reference_subtract_within_day( obj )

%   REFERENCE_SUBTRACT_WITHIN_DAY -- For each day, subtract the ref
%     electrode trace from each additional channel.
%
%     IN:
%       - `obj` (SignalContainer)

dsp2.util.assertions.assert__isa( obj, 'Container', 'the signals' );
assert( obj.contains('ref'), 'the given object must have a ''ref'' channel.' );

ref = only( obj, 'ref' );
others = remove( obj, 'ref' );

indices = get_indices( others, { 'days', 'regions' } );

for i = 1:numel(indices)
  fprintf( '\n\t ! reference_subtract_within_day: Processing %d of %d' ...
    , i, numel(indices) );
  extr = others( indices{i} );
  ref_complement = ref.only( char(unique(extr('days'))) );
  ref_min = ref_complement.trial_stats.min;
  ref_max = ref_complement.trial_stats.max;
  channels = unique( extr('channels') );
  for k = 1:numel(channels)
    ind = extr.where( channels{k} );
    curr_min = extr.trial_stats.min( ind );
    curr_max = extr.trial_stats.max( ind );
    subtracted = opc( extr(ind), ref_complement ...
      , {'channels', 'regions', 'sites'}, @minus );
    if ( ~any(subtracted.data(:) > 0) )
      error( 'subtracted a channel from itself' );
    end
    extr.data(ind, :) = subtracted.data;
    extr.trial_stats.min(ind) = min( [curr_min, ref_min], [], 2 );
    extr.trial_stats.max(ind) = max( [curr_max, ref_max], [], 2 );
  end
  others.data(indices{i},:) = extr.data;
  others.trial_stats.min(indices{i}) = extr.trial_stats.min;
  others.trial_stats.max(indices{i}) = extr.trial_stats.max;
end

others = others.update_range();

end