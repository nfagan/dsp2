function obj = fix_block_number( obj )

%   FIX_BLOCK_NUMBER -- Make each block number a unique block number
%     within a recording day.
%
%     I.e., if there are multiple sessions within a day, make block number
%     increment over sessions, rather than reset to 1 for each session.
%
%     IN:
%       - `obj` (Container, SignalContainer)
%     OUT:
%       - `obj` (Container, SignalContainer)

dsp2.util.assertions.assert__isa( obj, 'Container' );
assert__categories_exist( obj.labels, {'blocks', 'sessions', 'days'} );
% obj = obj.parfor_each( 'days', @fix_one_day ); return;

[inds, C] = obj.get_indices( {'days', 'blocks', 'sessions'} );
prev_day = C{1, 1};
stp = 1;
obj( 'blocks', inds{1} ) = sprintf( 'block__%d', stp );
for i = 2:numel(inds)
  curr_day = C{i, 1};
  if ( ~strcmp(prev_day, curr_day) )
    stp = 1;
  else
    stp = stp + 1;
  end
  obj( 'blocks', inds{i} ) = sprintf( 'block__%d', stp );
  prev_day = curr_day;
end


end

function obj = fix_one_day(obj)

%   FIX_ONE_DAY -- Fix a single day.

inds = obj.get_indices( {'blocks', 'sessions'} );
for i = 1:numel(inds)
  obj( 'blocks', inds{i} ) = sprintf( 'block__%d', i );
end

end