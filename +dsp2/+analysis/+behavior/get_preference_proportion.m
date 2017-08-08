function pref = get_preference_proportion(obj, within, outcome_subsets)

%   GET_PREFERENCE_PROPORTION -- Calculate the proportion of outcomes
%     within a given specificity.
%
%     dsp2.analysis.behavior.get_preference_proportion( obj, 'days' )
%     calculates, for each day in 'days', the proportion of self choices,
%     relative to both choice, and, separately, other choices, relative to
%     none choices.
%
%     dsp2.analysis.behavior.get_preference_index( obj, 'days',
%     outcome_subsets ) works as above, except that proportions are
%     calculated for each subset of outcomes in `outcome_subsets`.
%
%     IN:
%       - `obj` (Container)
%       - `within` (cell array of strings, char) -- Specificity of the
%         calculation. E.g., {'days', 'blocks'}
%       - `outcome_subsets` (cell array of cell arrays of strings)
%     OUT:
%       - `pref` (Container)

if ( nargin < 3 )
  outcome_subsets = { {'both', 'self'}, {'other', 'none'} };
end

pref = Container();

for i = 1:numel(outcome_subsets)
  subset = outcome_subsets{i};
  selected = obj.only( subset );
  assert( ~selected.isempty(), 'No data matched these criterion: %s' ...
    , strjoin(subset, ', ') );
  pref_ = selected.for_each( within, @proportions, 'outcomes', subset(:) );
  pref = pref.append( pref_ );
end

end