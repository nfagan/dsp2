function psth = get_gaze_psth( evts, pupil, tlabel )

%   GET_GAZE_PSTH -- Get gaze data aligned to event start + stop times.
%
%     IN:
%       - `evts` (Container) -- Event times.
%       - `pupil` (Container) -- Pupil data.
%       - `tlabel` (char) -- Label that identifies the time samples in
%         `pupil`.
%     OUT:
%       - `psth` (Container) -- Object whose data are an MxN matrix of M
%         trials by N samples, aligned to `evts`.

import dsp2.util.assertions.*;

%   ensure we can proceed
assert__isa( evts, 'Container', 'the event times' );
assert__isa( pupil, 'Container', 'the gaze data' );
assert__isa( tlabel, 'char', 'the time label' );
assert__isa( pupil.data, 'cell', 'the gaze data in the Container' );
assert( size(evts.data, 2) == 2, ['Event times must be a two-column' ...
  , ' matrix; %d columns were present.'], size(evts.data, 2) );
assert__contains_fields( pupil.labels, 'gaze_data_type' );
kinds = pupil( 'gaze_data_type' );
assert__contains_labels( pupil.labels, tlabel );
assert( numel(kinds) > 1, 'Only time data is present.' );

evts_sesh_ids = evts.pcombs( {'days', 'sessions'} );
pup_sesh_ids = pupil.pcombs( {'days', 'sessions'} );

assert( isequal(evts_sesh_ids, pup_sesh_ids), ['The event times do not' ...
  , ' contain the same number of sessions as the pupil data.'] );

%   find the number of sessions, etc.

N = size( evts_sesh_ids, 1 );
psth = cell( 1, N );

for i = 1:N
  row = evts_sesh_ids(i, :);  
  evt = evts.only( row );
  pup = pupil.only( row );  
  psth{i} = one_session( evt, pup, tlabel );
end

psth = extend( psth{:} );

end

function out = one_session( evt, pup, tlabel )

%   ONE_SESSION -- Generate a psth for one session, for each sample type.

t = pup.only( tlabel );
others = pup.rm( tlabel );

out = others.for_each( 'gaze_data_type', @one_sample_type, evt, t );

end

function out = one_sample_type( samples, evt, t )

%   ONE_SAMPLE_TYPE -- Generate a psth from for one sample type.

assert( shape(samples, 1) == shape(t, 1), ['Mismatch between number of' ...
  , ' trials for time and number of trials for ''%s''.'] ...
  , strjoin(samples('gaze_data_type'), ', ') );

blocks = cellfun( @(x) x('blocks'), t.data, 'un', false );
blocks = cellfun( @(x) str2double(x{1}(numel('block__')+1:end)), blocks );
[~, ind] = sort( blocks );

nrows = sum( cellfun( @(x) shape(x, 1), t.data ) );
assert( nrows == shape(evt, 1), ['Mismatch between number of gaze data' ...
  , ' trials and number of event times.'] );

identifier = strjoin( flat_uniques(samples.labels, {'days', 'sessions'}), ', ' );

stp = 1;
did_prealc = false;
new_labs = SparseLabels();
errs = 0;

for i = 1:numel(ind)
  t_ = t( ind(i) );
  t_ = t_.data{1};
  samp_ = samples( ind(i) );
  samp_ = samp_.data{1};
  samp_ = samp_.require_fields( 'gaze_data_type' );
  samp_( 'gaze_data_type' ) = samples( 'gaze_data_type' );
  labs = samp_.labels;
  samp_ = samp_.data;
  t_ = t_.data;
  N = size( t_, 1 );
  evt_ = evt( stp:stp+N-1 );
  evt_ = evt_.data;
  for k = 1:size(evt_, 1)
    current = evt_(k, :);
    if ( any(current == 0) ), errs = errs + 1; continue; end;
    current_t = t_(k, :);
    if ( max(current) > max(current_t) ), errs = errs + 1; continue; end
    assert( current_t(1) == -1, ['Expected a first time value of -1, but' ...
      , ' got %d.'], current_t(1) );
    diffed_start = abs( current_t - current(1) );
    diffed_stop = abs( current_t - current(2) );
    start = find( diffed_start == min(diffed_start) );
    stop = find( diffed_stop == min(diffed_stop) );
    assert( stop > start, 'Incorrect start or stop time.' );
    if ( ~did_prealc )
      new_data = nan( nrows, (stop-start)+1 );
      did_prealc = true;
    else
      if ( (stop-start)+1 ~= size(new_data, 2) )
        warning( 'Incorrect start or stop time for ''%s''.', identifier );
        continue;
      end
    end
    new_data(k+stp-1, :) = samp_(k, start:stop);
  end
  stp = stp + N;
  assert( did_prealc, 'No events were greater than 0 for ''%s''.', identifier );
  new_labs = new_labs.append( labs );
end

out = Container( new_data, new_labs );

end