function obj = add_trial_bin(obj, N, start_from)

%   ADD_TRIAL_BIN

stp = 1;

if ( nargin < 3 )
  bin_n = 1;
else
  bin_n = start_from;
end
trial_bins = cell( shape(obj, 1), 1 );
end_ind = 0;

while ( end_ind ~= shape(obj, 1) )
  end_ind = stp + N - 1;
  if ( end_ind > shape(obj, 1) ), end_ind = shape(obj, 1); end;
  ind = stp:end_ind;
  trial_bins(ind) = { sprintf('trial_bin__%d', bin_n) };
  stp = stp + N;
  bin_n = bin_n + 1;
end

obj = obj.require_fields( 'trial_bin' );
obj( 'trial_bin' ) = trial_bins;

end