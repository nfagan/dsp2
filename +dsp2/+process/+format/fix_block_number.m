function obj = fix_block_number( obj )

%   FIX_BLOCK_NUMBER -- Make each block number a unique block number
%     within a recording day.
%
%     I.e., if there are multiple sessions within a day, make block number
%     increment over sessions, rather than reset to 1 for each
%     session.
%
%     IN:
%       - `obj` (Container, SignalContainer)
%     OUT:
%       - `obj` (Container, SignalContainer)

dsp2.util.assertions.assert__isa( obj, 'Container' );
assert__categories_exist( obj.labels, {'blocks', 'sessions', 'days'} );
obj = obj.do( 'days', @fix_one_day );

end

function obj = fix_one_day(obj)

%   FIX_ONE_DAY -- Fix a single day.

inds = obj.get_indices( {'blocks', 'sessions'} );
for i = 1:numel(inds)
  obj( 'blocks', inds{i} ) = sprintf( 'block__%d', i );
end

end