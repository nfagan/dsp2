function errs = get_error_percentages(cont)

import dsp2.util.assertions.*;

assert__isa( cont, 'Container' );

errs = process_within( cont, 'contexts' );

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