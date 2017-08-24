function obj = only_pairs(obj, pairs, conf)

%   ONLY_PAIRS -- Only retain data associated with predefined channel
%     pairs.
%
%     obj = only_pairs( obj ) retains the data in `obj` associated with
%     the channel pairs as defined in 'pairs.mat'. An error is thrown if
%     this file does not exist.
%
%     obj = only_pairs( obj, pairs ) uses `pairs` instead of the saved
%     pairs in order to select rows of `obj`.
%
%     An error is thrown if any of the days in `obj` are not found in the
%     'days' field of `pairs`.
%
%     See also dsp2.io.define_site_pairs, dsp2.io.get_site_pairs
%
%     IN:
%       - `obj` (Container)
%       - `pairs` (struct) |OPTIONAL| -- Struct with 'days', 'channels',
%         and 'channel_key' fields.
%       - `conf` (struct) |OPTIONAL| -- Config file.

import dsp2.util.assertions.*;

if ( nargin < 3 ), conf = dsp2.config.load(); end
if ( nargin < 2 ), pairs = dsp2.io.get_site_pairs( conf ); end

assert__isa( pairs, 'struct', 'the site pairs' );
assert__isa( obj, 'Container', 'the object' );
assert__contains_fields( obj.labels, {'days', 'channels'} );

obj_days = obj( 'days' );
pair_days = pairs.days;
pair_channels = pairs.channels;

assert( isempty(setdiff(pair_days, obj_days)), ['The following days' ...
  , ' were present in the object, but not in the pairs.mat file: %s.'] ...
  , strjoin(setdiff(pair_days, obj_days), ', ') );

to_rm_ind = obj.logic( false );

for i = 1:numel(obj_days)
  day = obj_days{i};
  ind = obj.where( day );
  obj_channels = unique( obj('channels', ind) );
  chans = pair_channels( strcmp(pair_days, day) );
  joined = join_2d_cell( chans{1}, '_' );
  assert( any(obj.contains(joined)), ['None of the possible channel pairs' ...
    , ' were present in the object.'] );
  to_rm = setdiff( obj_channels, joined );
  if ( isempty(to_rm) ), continue; end
  to_rm_ind = to_rm_ind | obj.where([to_rm(:)', day]);
end

obj = obj.keep( ~to_rm_ind );

end

function strs = join_2d_cell( arr, joiner )

%   JOIN_2D_CELL -- Join rows of a cell array that is a 2-column matrix.

N = size( arr, 1 );
strs = cell( 1, N );
for i = 1:N
  strs{i} = strjoin( arr(i, :), joiner );
end

end