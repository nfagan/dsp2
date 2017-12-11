function obj = add_trial_bin(obj, N, start_from, step_size, allow_truncated_final_bin)

%   ADD_TRIAL_BIN

if ( nargin < 5 )
  allow_truncated_final_bin = false;
end
if( nargin < 4 )
  step_size = N;
end

stp = 1;

if ( nargin < 3 )
  bin_n = 1;
else
  bin_n = start_from;
end
trial_bins = cell( shape(obj, 1), 1 );
end_ind = 0;

to_rm = obj.logic( false );

while ( end_ind ~= shape(obj, 1) )
  end_ind = stp + N - 1;
  if ( end_ind > shape(obj, 1) )
    if ( allow_truncated_final_bin )
      end_ind = shape(obj, 1); 
    else
      to_rm( stp:end ) = true;
      trial_bins( to_rm ) = { 'trial_bin__null' };
      break;
    end
  end;
  ind = stp:end_ind;
  trial_bins(ind) = { sprintf('trial_bin__%d', bin_n) };
  stp = stp + step_size;
  bin_n = bin_n + 1;
end

obj = obj.require_fields( 'trial_bin' );
obj( 'trial_bin' ) = trial_bins;
obj = obj.keep( ~to_rm );

end