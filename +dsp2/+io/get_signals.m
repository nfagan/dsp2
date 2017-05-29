function [signals, time_info] = get_signals(varargin)

%   GET_SIGNALS -- Obtain a Structure of objects whose data are Trials x
%     Samples matrices, according to the options defined in 
%     dsp2.config.create.
%
%     IN:
%       - `varargin` ('name', value)

defaults = struct();
defaults.sessions = 'all';
defaults.fs = 1e3;
defaults.config = dsp2.config.load();

DATA_FIELDS.signals = 'file';
DATA_FIELDS.align = { 'plex', 'picto' };
DATA_FIELDS.events = { 'fixOn', 'cueOn', 'targOn', 'targAcq', 'rwdOn' };
DATA_FIELDS.meta = { 'session', 'actor', 'recipient', 'drug' };

defaults.DATA_FIELDS = DATA_FIELDS;

%   parse inputs

params = dsp2.util.general.parsestruct( defaults, varargin );

%   use all sessions in the database by default; this can be changed to a)
%   a cell array of session names, or b) a path to a subfolder housing the
%   desired sessions -- in this case, call get_folder_names( subfolder ) to
%   get the names of the sessions within. Only works if the session names
%   are the names of the folders.

%   DATABASE

db = dsp2.io.get_sqlite_db();

if ( isequal(params.sessions, 'all') )
  SESSIONS = unique( db.get_fields('session', 'signals') );
else
  SESSIONS = dsp2.util.general.ensure_cell( params.sessions );
end

EPOCHS = params.config.SIGNALS.EPOCHS;

SAMPLING_RATE = params.fs;

COMMON_AVERAGE_REFERENCE = params.config.SIGNALS.reference_on_load && ...
  isequal(params.config.SIGNALS.reference_type, 'common_averaged' );

%   VALIDATE

dsp2.util.assertions.assert__is_cellstr( SESSIONS, 'the sessions to load' );
dsp2.util.assertions.assert__isa( EPOCHS, 'struct', 'the epoch definitions' );

%   END PARAMETERS

if ( isempty(SESSIONS) || isequal(SESSIONS{1}, 'No Data') )
  error( 'Database ''%s'' was empty', db.filename );
end

signals = Structure.create( fieldnames(EPOCHS), Container() );
time_info.epochs = EPOCHS;
time_info.fs = SAMPLING_RATE;

for i = 1:numel(SESSIONS)
  session = sprintf( '"%s"', SESSIONS{i} );
  fprintf( '\n - Processing Session %s (%d of %d)', session, i, numel(SESSIONS) );
  
  pl2_file =    unique( db.get_fields_where_session( DATA_FIELDS.signals, 'signals', session) );
  channel_map = db.get_fields_where_session( {'channel', 'region'}, 'signals', session );
  channels =    channel_map(:, 1);
  regions =     channel_map(:, 2);
  align =       db.get_fields_where_session( DATA_FIELDS.align, 'align', session );
  trial_info =  db.get_fields_where_session( '*', 'trial_info', session );
  events =      db.get_fields_where_session( DATA_FIELDS.events, 'events', session );
  meta =        db.get_fields_where_session( DATA_FIELDS.meta, 'meta', session );
  
  %   reformat
  
  events = cell2mat( events );
  align = cell2mat( align );
  
  %   validate
  
  assert__correct_n_files( pl2_file, 1, 'pl2 files' );
  assert( size(trial_info,1) == size(events,1), ['Mismatch in number of rows' ...
    , ' between events and trial_info. You may wish to regenerate the database'] );
  
  %   alignment
  
  cued = events(:, 4) == 0 & events(:, 1) ~= 0;
  no_rwd = events(:, 5) == 0;
  events = adjusted_event_times( events, align );
  events( cued, 4 ) = 0;
  events( no_rwd, 5 ) = 0;
  
  %   get id times
  
  id_times = get_id_times( pl2_file{1}, channels{1}, SAMPLING_RATE );
  
  %   load pl2
  
  plex = cell( numel(channels), 1 );
  for k = 1:numel(channels)
    plex{k} = get_plex_data( pl2_file{1}, channels{k}, SAMPLING_RATE );
  end
  
  %   optionally common average reference
  
  if ( COMMON_AVERAGE_REFERENCE )
    plex = common_average_reference( plex );
%     [plex, channels, regions] = common_average_or_reference( plex, channel_map );
%     [~, common_avg] = common_average_reference( plex );
%     
%     channels{end+1} = 'CA01';
%     regions{end+1} = 'cav';
%     plex{end+1} = common_avg;
  end
  
  %   get signals
  
  active_epochs = get_active_epochs( EPOCHS );
  epochs = fieldnames( active_epochs );
  for k = 1:numel(epochs)
    epoch = epochs{k};
    fprintf( '\n\t - Processing Epoch "%s" (%d of %d)', epoch, k, numel(epochs) );
    event_index = find( strcmp(DATA_FIELDS.events, epoch) );
    assert( ~isempty(event_index), ['The specified epoch ''%s'' does not' ...
      , ' have event data associated with it, as defined by DATA_FIELDS.events'] ...
      , epoch );
    start_stop = EPOCHS.(epoch).time;
    win_size = EPOCHS.(epoch).win_size;
    %   adjust the end-time so that the last window has a complete window's
    %   worth of data.
    start_stop(2) = start_stop(2) + win_size;
    epoch_events = events(:, event_index);
    tic;
    for j = 1:numel(channels)
      fprintf( '\n\t\t - Processing Channel "%s" (%d of %d)', channels{j}, j, numel(channels) );
      signal = get_signals_( plex{j}, id_times, epoch_events, start_stop ...
        , win_size, SAMPLING_RATE );
      signal_info = struct();
      signal_info.channel = channels{j};
      signal_info.region = regions{j};
      %   since the labels will be the same for each epoch, region, and
      %   channel (except for those categories), only create the 
      %   SparseLabels object once; then update the epoch, region, and
      %   channel
      if ( j == 1 && k == 1 )
        labels = build_labels( db, trial_info, meta, DATA_FIELDS.meta, epoch, signal_info );
      else
        epoch_ind = strcmp( labels.categories, 'epochs' );
        channel_ind = strcmp( labels.categories, 'channels' );
        region_ind = strcmp( labels.categories, 'regions' );
        labels.labels(epoch_ind) = { epoch };
        labels.labels(channel_ind) = channels(j);
        labels.labels(region_ind) = regions(j);
      end
      signals.(epochs{k}) = append( signals.(epochs{k}), Container(signal, labels) );
    end
    toc;
  end
end

%   lastly, convert each standard Container to a SignalContainer.

signals = signals.rm_fields( setdiff(fieldnames(EPOCHS), epochs) );
signals = signals.each( @(x) dsp__post_process(x) );
ids = dsp2.process.get_trial_ids( signals{1} );

converted_signals = Structure();
for i = 1:numel(epochs)
  extr = signals.(epochs{i});
  curr_time = EPOCHS.(epochs{i});
  start_stop = curr_time.time;
  window = [curr_time.stp_size, curr_time.win_size];
  converted_signals.(epochs{i}) = SignalContainer( extr.data, extr.labels ...
    , SAMPLING_RATE, start_stop, window, ids );
end

signals = converted_signals;

end



function [plex, channels, regions] = common_average_or_reference( plex, channel_map )

%   COMMON_AVERAGE_OR_REFERENCE -- Subtract either a common-averaged or
%   	reference signal from each relevant channel.
%
%     For regions with multiple channels, the region will be
%     common-averaged. For regions with a single channel, the region will
%     be reference subtracted.
%
%     IN:
%       - `plex` (cell array) -- Cell array of channel-data. Each channel
%         must be a 1xM vector of raw signal values.
%       - `channel_map` (cell array of strings) -- Two-column cell array of
%         strings where the first column contains channel ids, and the
%         second region ids.

channels = channel_map(:, 1);
regions = channel_map(:, 2);
unique_regions = unique( regions );

if ( numel(unique_regions) == numel(regions) )
  ref_ind = strcmp( regions, 'ref' );
  assert( sum(ref_ind) == 1, ['There must be one and only one reference' ...
    , ' channel.'] );
  ref = plex( ref_ind );
  other_inds = find( ~ref_ind );
  for i = 1:numel(other_inds)
    current = plex( other_inds(i) );
    plex{ other_inds(i) } = current{1} - ref{1};
  end  
  plex( ref_ind ) = [];
  channels( ref_ind ) = [];
  regions( ref_ind ) = [];
  return;
end

counts = cellfun( @(x) sum(strcmp(regions, x)), unique_regions );
multi_ind = find( counts > 1 );
assert( numel(multi_ind) == 1, ['Currently, only one region may have' ...
  , ' multiple channels associated with it in a given day.'] );
multi_region = unique_regions( multi_ind );
matches_mult = strcmp( regions, multi_region );
common_averaged_mult = common_average_reference( plex(matches_mult) );
ref_ind = strcmp( regions, 'ref' );
assert( sum(ref_ind) == 1, ['More than one reference channel was found.' ...
  , ' There can only be one reference channel per day.'] );
other_reg = setdiff( unique_regions, { char(multi_region), 'ref' } );
assert( numel(other_reg) == 1, ['Currently, there can only be three regions' ...
  , ' in a given day.'] );
other_ind = strcmp( regions, other_reg );

other = plex( other_ind );
ref = plex( ref_ind );
plex{ other_ind } = other{1} - ref{1};

plex( matches_mult ) = common_averaged_mult;
plex( ref_ind ) = [];
channels( ref_ind ) = [];
regions( ref_ind ) = [];

end

function [plex, common_average] = common_average_reference( plex )

%   COMMON_AVERAGE_REFERENCE -- Subtract an averaged signal from each
%     channel in Plex.
%
%     Only so-called 'good' sites are included in the averaging; these are
%     sites for which the RMS of the site is between .3 and 2 times the
%     average RMS of all sites ( see Ludwig et al., 2009 ).
%
%     IN:
%       - `plex` (cell array) -- Cell array of channel-data. Each channel
%         must be a 1xM vector of raw signal values.
%     OUT:
%       - `plex` (cell array) -- Cell array of channel-data, in the same
%         order as was input, but with the appropriate common average
%         subtracted sample-by-sample.
%       - `common_average` (double) -- Mx1 column vector of common-averaged
%         signals.

rmses = cellfun( @(x) rms(x), plex );
mean_rms = mean( rmses );
ratio = rmses ./ mean_rms;
good_sites = ratio >=.3 & ratio <= 2;
assert( any(good_sites), 'No good sites were found' );
good_sites = cell2mat( plex(good_sites)' );
common_average = mean( good_sites, 2 );
plex = cellfun( @(x) x-common_average, plex, 'un', false );

end

function names = get_folder_names( directory )

%   GET_FOLDER_NAMES -- Obtain an array of folder names in the given
%     directory.
%     
%     IN:
%       - `directory` (char) -- Path to an outer folder housing other
%         subfolders. An error is thrown if no folders are found in the
%         specified directory.
%     OUT:
%       - `names` (cell array of strings) -- Folder names.

names = dirstruct( directory, 'folders' );
assert( ~isempty(names), 'No folders found in directory ''%s''', directory );
names = { names(:).name };

end

function labels = build_labels( db, trial_info, meta, meta_fields, epoch, signal_info )

trial_tbl_fields = db.get_field_names( 'trial_info' );

desired_trial_cols = { 'trialType', 'magnitude', 'cueType', 'fix', 'folder', 'trial' };

for i = 1:numel(desired_trial_cols)
  col_ind = strcmp( trial_tbl_fields, desired_trial_cols{i} );
  assert( any(col_ind), 'Could not find column ''%s''', desired_trial_cols{i} );
  indices.(desired_trial_cols{i}) = cell2mat( trial_info(:, col_ind) );
end

meta_struct = struct();
for i = 1:numel(meta_fields)
  meta_struct.(meta_fields{i}) = ...
    char( meta(strcmp(meta_fields, meta_fields{i})) );
end

complete_true = true( size(trial_info, 1), 1 );

%   define outcomes

cue_type = indices.cueType;
fixed_on = indices.fix;

inds.outcomes.self =  (cue_type == 0 & fixed_on == 1) | (cue_type == 1 & fixed_on == 2);
inds.outcomes.both =  (cue_type == 1 & fixed_on == 1) | (cue_type == 0 & fixed_on == 2);
inds.outcomes.other = (cue_type == 2 & fixed_on == 1) | (cue_type == 3 & fixed_on == 2);
inds.outcomes.none =  (cue_type == 3 & fixed_on == 1) | (cue_type == 2 & fixed_on == 2);
inds.outcomes.errors = ...
  ~any( [inds.outcomes.self, inds.outcomes.both, inds.outcomes.other, inds.outcomes.none], 2 );

%   define trialtypes
inds.trialtypes.choice = logical( indices.trialType );
inds.trialtypes.cued = ~inds.trialtypes.choice;
%   define magnitudes
inds.magnitudes.high = indices.magnitude == 3;
inds.magnitudes.medium = indices.magnitude == 2;
inds.magnitudes.low = indices.magnitude == 1;
inds.magnitudes.no_reward = ...
  ~any( [inds.magnitudes.high, inds.magnitudes.medium, inds.magnitudes.low], 2 );
%   define epoch
inds.epochs = struct( epoch, complete_true );
%   define session
inds.sessions = struct( ['session__' meta_struct.session], complete_true );
%   define actor monkey
inds.monkeys = struct( meta_struct.actor, complete_true );
%   define recipient monkey
inds.recipients = struct( meta_struct.recipient, complete_true );
%   define drugs
inds.drugs = struct( meta_struct.drug, complete_true );
%   define channels
inds.channels = struct( signal_info.channel, complete_true );
%   define regions
inds.regions = struct( signal_info.region, complete_true );
%   define blocks
blocks = unique( indices.folder );
for i = 1:numel(blocks)
  current_ind = indices.folder == blocks(i);
  inds.blocks.(sprintf('block__%d', blocks(i))) = current_ind; 
end
%   define trials
trials = unique( indices.trial );
for i = 1:numel(trials)
  current_ind = indices.trial == trials(i);
  inds.trials.(sprintf('trial__%d', trials(i))) = current_ind;
end

categories = fieldnames( inds );
sparse_labels_inputs = {};
for i = 1:numel(categories)
  current_cat = inds.(categories{i});
  labels = fieldnames( current_cat );
  for k = 1:numel(labels)
    current_index = current_cat.(labels{k});
    in = struct( 'label', labels{k}, 'category', categories{i}, 'index', current_index );
    sparse_labels_inputs = [ sparse_labels_inputs, in ];
  end
end

labels = SparseLabels( sparse_labels_inputs );

end

function active_epochs = get_active_epochs( epochs )

%   GET_ACTIVE_EPOCHS -- Return a filtered EPOCHS struct with only fields
%     in which `active` is true.
%
%     IN:
%       - `epochs` (struct) -- Epochs struct. Each field of `epochs` must
%         be a structure with an 'active' field.
%     OUT:
%       - `active_epochs` (struct) -- Epochs struct containing only fields
%         for which the corresponding field of the inputted epochs struct
%         had active = true.

assert( isstruct(epochs), 'epochs must be a struct; was a ''%s''', class(epochs) );
fields = fieldnames( epochs );
active_epochs = struct();
for i = 1:numel(fields)
  assert( isstruct(epochs.(fields{i})), ['each field of epochs must be a struct' ...
    , ' was a ''%s'''], class(epochs.(fields{i})) );
  assert( isfield(epochs.(fields{i}), 'active'), ['The epochs struct ''%s''' ...
    , ' is missing the required field ''active'''], fields{i} );
  if ( epochs.(fields{i}).active )
    active_epochs.(fields{i}) = epochs.(fields{i});
  end
end

end

function all_signals = get_signals_( plex, id_times, events, start_stop, w_size, fs )

%   GET_SIGNALS -- Given a vector of event times, get a signal vector of
%     desired length aligned to those events.
%
%     IN:
%       - `plex` (double) -- Complete signal vector from which to draw 
%         samples.
%       - `id_times` (double) -- Complete id_times vector identifying the
%         time of each point in `plex`.
%       - `events` (double) -- Vector of event times. Event-times that are
%         0 will not be searched for; accordingly, the corresponding rows
%         in `all_signals` will be all zeros. All non-zero event-times must
%         be in bounds of `id_times`.
%       - `start_stop` (double) -- Where to start and stop relative to t=0
%         as the actual event time. E.g., `start_stop` = [-1000 1000]
%         starts -1000 ms relative to each events(i), and stops 1000ms post
%         each events(i).
%       - `w_size` (double) |SCALAR| -- Window-size. Used to shift the
%         start of the signal vector such that the center of each window is
%         the time-point associated with that window.
%       - `fs` (double) |SCALAR| -- Sampling rate of the signals in `plex`.
%     OUT:
%       - `all_signals` (double) -- Matrix of signals in which each
%         row(i, :) corresponds to each `events`(i). Rows of `all_signals`
%         will be entirely zero where events == 0.

assert( size(events, 2) == 1, ['Expected there to be only 1 column of events' ...
  , ' data, but there were %d'], size(events, 2) );
assert( numel(start_stop) == 2, 'Specify `start_stop` as a two-element vector' );
assert( start_stop(2) > start_stop(1), ['`start_stop`(2) must be greater than' ...
  , ' `start_stop`(1)'] );

is_zero = events(:,1) == 0;
non_zero_events = events( ~is_zero, : );

amount_ms = (start_stop(2) - start_stop(1)) * (fs/1e3);
start = start_stop(1)/1e3;
w_size = w_size/1e3;

non_zero_events = non_zero_events + start;
non_zero_events = non_zero_events - w_size/2; % properly center each window.

signals = zeros( size(non_zero_events,1), amount_ms );
all_signals = zeros( size(events, 1), amount_ms );

for i = 1:size(non_zero_events, 1)
  current_time = non_zero_events(i);
  [~, index] = histc( current_time, id_times );
  out_of_bounds_msg = ['The id_times do not properly correspond to the' ...
    , ' inputted events'];
  assert( index ~= 0 && (index+amount_ms-1) <= numel(plex), out_of_bounds_msg );
  check = abs( current_time - id_times(index) ) < abs( current_time - id_times(index+1) );
  if ( ~check ), index = index + 1; end;
  signals(i, :) = plex( index:index+amount_ms-1 );
end

all_signals( ~is_zero, : ) = signals;

end

function ad = get_plex_data( file, channel, sampling_rate )

%   GET_PLEX_DATA -- Obtain a signal vector from the specified file and
%     channel, and optionally downsampled to a new sampling rate.
%
%     IN:
%       - `file` (char) -- Full path to a .pl2 file.
%       - `channel` (char) -- Desired channel.
%       - `sampling_rate` (double) |SCALAR| -- Target sampling_rate. Must
%         be an integer factor of the original sample rate specified in the
%         .pl2 file.
%     OUT:
%       - `ad` (double) -- Vector of analog channel data.

[fs, ~, ~, ~, ad] = plx_ad_v( file, channel );
downsample_factor = fs / sampling_rate;
assert( mod(downsample_factor, 1) == 0, ['Attempted to downsample by a non-integer factor;' ...
  , 'current fs is %f; specified sampling_rate was %f'], fs, sampling_rate );

if ( downsample_factor ~= 1 )
  ad = downsample( ad, downsample_factor );
end

end

function id_times = get_id_times( file, channel, sampling_rate )

%   GET_ID_TIMES -- Get a vector of times identifying each sample point in
%     a signal vector, starting from the time of the recording (in terms of
%     Plexon time).
%
%     IN:
%       - `file` (char) -- Full path to a .pl2 file
%       - `channel` (char) -- Name of the analog channel whose dimensions
%         are to be matched.
%       - `sampling_rate` (double) |SCALAR| -- Target sampling_rate. Must
%         be an integer factor of the original sample rate specified in the
%         .pl2 file.
%     OUT:
%       - `id_times` (double) -- Vector of sample-times of the same
%         dimensions as the inputted analog channel.

[fs, ~, ~, ~, ad] = plx_ad_v( file, channel );
pl2_file = PL2GetFileIndex( file );
tick_start = pl2_file.StartRecordingTimeTicks; % get start time of recording in ticks
pl2_recording_time = pl2_file.DurationOfRecordingSec; % get length of recording time in s
tick_duration = pl2_file.DurationOfRecordingTicks; % get length of recording in ticks
factor = tick_duration/pl2_recording_time; % find the factor by which to convert start time to s
start_time_sec = tick_start/factor; % converted to seconds
id_times = start_time_sec + (1 / fs)*(1:length(ad));

downsample_factor = fs / sampling_rate;
assert( mod(downsample_factor, 1) == 0, ['Attempted to downsample by a non-integer factor;' ...
  , 'current fs is %f; specified sampling_rate was %f'], fs, sampling_rate );
if ( downsample_factor == 1 ), return; end;
id_times = downsample( id_times, downsample_factor );

end

function events = adjusted_event_times( events, align )

%   ADJUSTED_EVENT_TIMES -- Express the picto event times in terms of
%     Plexon time.
%     
%     IN:
%       - `events` (matrix) -- Event times; expected to have at least 2
%         columns. Rows where the first column is 0 are assumed to be error
%         trials, and are not aligned.
%       - `align` (matrix) -- Strobed align times between Picto and Plexon.
%         The first column is assumed to be Plex times; the second Picto
%         times.
%     OUT:
%       - `events` (matrix) -- Aligned event times.

plex = align(:, 1);
picto = align(:, 2);
non_zeros = events(:, 1) ~= 0;
to_align = events( non_zeros, : );
try
  closest_inds = arrayfun( @(x) find(picto < x, 1, 'last'), to_align(:,1) );
catch
  error( 'The align file does not match the given events' );
end

offset = to_align(:,1) - picto(closest_inds);
start = plex(closest_inds) + offset;
aligned = to_align;
aligned(:, 1) = start;
for i = 1:size(aligned, 2)
  aligned(:, i) = to_align(:, i) - to_align(:, 1) + start;
end
events( non_zeros, : ) = aligned;

end

function assert__correct_number( arr, N, msg )

if ( nargin < 3 )
  msg = sprintf( 'More or fewer than %d elements were present', N );
end

assert( numel(arr) == N, msg );

end

function assert__correct_n_files( arr, N, file_type )

msg = sprintf( 'More or fewer than %d of ''%s'' were present', N, file_type );
assert__correct_number( arr, N, msg );

end