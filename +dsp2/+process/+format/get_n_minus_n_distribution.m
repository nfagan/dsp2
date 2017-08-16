function obj = get_n_minus_n_distribution(obj, N, prev_is, current_is)

%   GET_N_MINUS_N_DISTRIBUTION -- Obtain a distribution of trials and N
%     trials in the past.
%
%     The object `obj` must be a SignalContainer whose `trial_ids` property
%     has been defined (i.e., does not contain any NaN values).
%     Additionally, each trial_id (within a given day, channel, and region)
%     must be unique; otherwise, an error is thrown.
%
%     IN:
%       - `obj` (SignalContainer)
%       - `N` (double) -- Number of trials to look back.
%     OUT:
%       - `obj` (SignalContainer)

if ( nargin < 4 ), current_is = {}; end
if ( nargin < 3 ), prev_is = {}; end

dsp2.util.assertions.assert__isa( obj, 'SignalContainer' );
dsp2.util.assertions.assert__is_scalar( N, 'the n-minus-n value' );

assert( ~any(isnan(obj.trial_ids)), 'Trial-ids must be defined.' );

trials = obj( 'trials' );

assert( ~any(strcmp(trials, 'all__trials')), ['Cannot convert the object' ...
  , ' to an n-minus-n distribution because it contains some data that' ...
  , ' have been collapsed across trials.'] );

obj = obj.for_each( {'days', 'channels', 'regions'} ...
  , @one_iter, N, prev_is, current_is  );

end

function obj = one_iter(obj, N, prev_is, current_is)

%   ONE_ITER -- Process one iteration.

day = char( obj('days') );

present_ns = obj.trial_ids;

assert( numel(unique(present_ns)) == numel(present_ns), ['Duplicate trial' ...
  , ' ids were present on day ''%s''.'], day );

prev_ns = present_ns - N;
negs = sign( prev_ns ) == -1 | prev_ns == 0;

prev_ns( negs ) = [];
present_ns( negs ) = [];

%   get rid of the previous trials for which there is no trial id for
%   that trial. also get rid of the corresponding present trial.

missing_prev_ind = arrayfun( @(x) ~any(prev_ns == x), present_ns );
missing_prev_ind2 = arrayfun( @(x) ~any(obj.trial_ids == x), prev_ns );

present_ns( missing_prev_ind | missing_prev_ind2 ) = [];
prev_ns( missing_prev_ind | missing_prev_ind2 ) = [];

present_inds = arrayfun( @(x) find(obj.trial_ids == x), present_ns );
prev_inds = arrayfun( @(x) find(obj.trial_ids == x), prev_ns );

current = obj( present_inds );
previous = obj( prev_inds );

current = current.require_fields( 'n_minus_n' );
current( 'n_minus_n' ) = 'n_minus_0';

previous = previous.require_fields( 'n_minus_n' );
previous( 'n_minus_n' ) = sprintf( 'n_minus_%d', N );

all_ind = previous.logic( true );

if ( ~isempty(prev_is) )
  all_ind = previous.where( prev_is );
end
if ( ~isempty(current_is) )
  all_ind = all_ind & current.where( current_is );
end

previous = previous(all_ind);
current = current(all_ind);

obj = append( current, previous );

end