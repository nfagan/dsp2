function pref = get_preference_index(obj, within, outcome_pairs)

%   GET_PREFERENCE_INDEX -- Calculate the preference index for the given
%     outcomes.
%
%     dsp2.analysis.behavior.get_preference_index( obj, within ) calculates
%     the preference index for (self relative to both) and (other relative
%     to none) to the given specificity `within`.
%
%     dsp2.analysis.behavior.get_preference_index( obj, within,
%     outcome_pairs ) calculates the preference index for each pair of
%     outcomes in `outcome_pairs`, rather than the default outcome_pairs.
%
%     IN:
%       - `obj` (Container)
%       - `within` (cell array of strings, char) -- Specificity of the
%         calculation. E.g., {'days', 'blocks'}
%       - `outcome_pairs` (cell array of cell arrays of strings) -- Pairs
%       	of outcomes for which to calculate the index. E.g., if
%       	`outcome_pairs` is { {'self', 'both'} }, then the returned index
%       	will contain the preference for 'self' relative to 'both'. Its
%       	outcomes label will be 'self_both';
%     OUT:
%       - `pref` (Container)

if ( nargin < 3 )
  outcome_pairs = { {'both', 'self'}, {'other', 'none'} };
end

pref = Container();

for i = 1:numel(outcome_pairs)
  pair = outcome_pairs{i};
  pref_ = obj.for_each( within, @get_index, pair{:} );
  pref = pref.append( pref_ );
end

end

function out = get_index(obj, out1, out2)

%   GET_INDEX -- Calculate the index (A-B) / (A+B)
%
%     IN:
%       - `obj` (Container)
%       - `out1` (char)
%       - `out2` (char)
%     OUT:
%       - `out` (Container) -- Object whose data are a scalar double.

cs = obj.counts_of( 'outcomes', {out1; out2} );
obj1 = cs.only( out1 );
obj2 = cs.only( out2 );

N1 = obj1.data;
N2 = obj2.data;

ind = (N1 - N2) / (N1 + N2);
% ind = (N1 - N2);

out = obj.collapse_non_uniform();
out = out.keep_one();

out.data = ind;
out( 'outcomes' ) = strjoin( {out1, out2}, '_' );

end