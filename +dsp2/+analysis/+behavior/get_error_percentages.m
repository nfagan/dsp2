function errs = get_error_percentages(cont, denom)

if ( nargin < 2 ), denom = 'within_context'; end

import dsp2.util.assertions.*;

assert__isa( cont, 'Container' );
assert__isa( denom, 'char' );

if ( strcmp(denom, 'within_context') )
  errs = process_within( cont, 'contexts' );
elseif ( strcmp(denom, 'good_trials') )
  errs = process_within_denom_as_good_trials( cont, 'contexts' );
else
  error( 'Unrecognized denominator ''%s''.', denom );
end

end

function errors = process_within_denom_as_good_trials( cont, within )

if ( ~iscell(within) ), within = { within }; end

C = cont.pcombs( within );

errors = Container();

for i = 1:size(C, 1)
  all_trials_ind = ~cont.where('error__initial_fixation');
  non_errs = sum( all_trials_ind );
  errs = sum( cont.where([C(i, :), 'error__target_fixation']) );
  
  if ( non_errs == 0 ), continue; end;
  
  prop = errs / non_errs;
  
  cont_ = one( cont );
  
  for j = 1:numel(within)
    cont_(within{j}) = C{i, j};
  end
  
  errors = append( errors, set_data(cont_, full(prop)) );
  
%   errors = append( errors, set_data(one(cont(all_trials_ind)), full(prop)) );
end

end

function errors = process_within( cont, within )

C = cont.pcombs( within );

errors = Container();

for i = 1:size(C, 1)
  all_trials_ind = cont.where(C(i, :)) & ~cont.where('error__initial_fixation');
  non_errs = sum( all_trials_ind );
  errs = sum( cont.where([C(i, :), 'error__target_fixation']) );
  
  if ( non_errs == 0 ), continue; end;
  
  prop = errs / non_errs;
  errors = append( errors, set_data(one(cont(all_trials_ind)), full(prop)) );
end

end