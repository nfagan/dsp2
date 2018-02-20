function [behavioral_data, all_data_fields] = get_behavior(varargin)

%   GET_BEHAVIOR -- Obtain a Structure of objects whose data are Trials x
%     Behavior Measure matrices, according to the options defined in 
%     dsp2.config.create.
%
%     IN:
%       - `varargin` ('name', value)
%     OUT:
%       - `behavioral_data` (Container) -- Object whose data are
%         column-vectors of trial-info.
%       - `all_data_fields` (cell array of strings) -- ID array where each
%         `all_data_fields`(i) corresponds to each column of data in
%         `behavioral_data`.

defaults = struct();
defaults.sessions = 'all';
defaults.INCLUDE_GAZE = false;
defaults.config = dsp2.config.load();
defaults.session_table = 'signals';

params = dsp2.util.general.parsestruct( defaults, varargin );

DATA_FIELDS.meta = { 'session', 'actor', 'recipient', 'drug' };
DATA_FIELDS.gaze = { 'x', 'y', 't' };
DATA_FIELDS.events = { 'fixOn', 'cueOn', 'targOn', 'targAcq', 'rwdOn' };
EXCLUDE_FIELDS.trial_info = { 'session' };

INCLUDE_GAZE = params.INCLUDE_GAZE;

%   DATABASE

db = dsp2.database.get_sqlite_db( 'config', params.config );

if ( isequal(params.sessions, 'all') )
  SESSIONS = db.get_sessions( params.session_table );
else
  SESSIONS = dsp2.util.general.ensure_cell( params.sessions );
end

if ( INCLUDE_GAZE )
  behavioral_data = Structure.create( {'trial_info', 'gaze_data', 'events'}, Container() );
else
  behavioral_data = Structure.create( {'trial_info', 'events'}, Container() );
end

for i = 1:numel(SESSIONS)
  session = sprintf( '"%s"', SESSIONS{i} );
  fprintf( '\n - Processing Session %s (%d of %d)', session, i, numel(SESSIONS) );
  
  trial_info =  db.get_fields_where_session( '*', 'trial_info', session );
  meta =        db.get_fields_where_session( DATA_FIELDS.meta, 'meta', session );
  gaze =        db.get_fields_where_session( DATA_FIELDS.gaze, 'gaze', session );
  events =      db.get_fields_where_session( DATA_FIELDS.events, 'events', session );
  
  events = cell2mat( events );
  
  labels = build_labels( db, trial_info, meta, DATA_FIELDS.meta );
  [trial_data, fields] = get_trial_data( db, trial_info, EXCLUDE_FIELDS.trial_info );
  
  labels = add_error_types( labels, trial_data, fields, events, DATA_FIELDS.events );
  
%   if ( INCLUDE_GAZE )
%   events = cell2mat( events );
  fix_on = events(:, strcmp(DATA_FIELDS.events, 'fixOn'));
  targ_on = events(:, strcmp(DATA_FIELDS.events, 'targOn'));
  targ_on_time = diff( [fix_on, targ_on], 1, 2 );
  
  if ( INCLUDE_GAZE )
    [gd, rt] = get_gaze_data( gaze, DATA_FIELDS.gaze, targ_on_time );
    trial_data(:, end+1) = rt;
    fields{end+1} = 'reaction_time';
    behavioral_data.gaze_data = behavioral_data.gaze_data.append( ...
      build_gaze_data_containers(gd, labels) ...
    );
  end
  behavioral_data.events = behavioral_data.events.append( Container(events, labels) );
  
  cont = Container( trial_data, labels );
  behavioral_data.trial_info = behavioral_data.trial_info.append( cont );
  
  if ( i == numel(SESSIONS) )
    all_data_fields.trial_info = fields;
    all_data_fields.events = DATA_FIELDS.events;
  end
end

behavioral_data = behavioral_data.each( @(x) dsp__post_process(x) );
behavioral_data = behavioral_data.each( @(x) x.remove_empty_indices() );

if ( INCLUDE_GAZE )
  gd = behavioral_data.gaze_data.data;
  gd = cellfun( @(x) dsp__post_process(x), gd, 'un', false );
  gd = cellfun( @(x) x.remove_empty_indices(), gd, 'un', false );
  behavioral_data.gaze_data.data = gd;
end

end

function labels = add_error_types(labels, trial_data, trial_key, evts, evt_key)

labels = labels.add_field( 'error_types' );
broke_initial_fixation = evts(:, strcmp(evt_key, 'fixOn')) == 0;
did_not_look_to_cue = trial_data(:, strcmp(trial_key, 'fix')) == 0;
target_fixation_error = did_not_look_to_cue & ~broke_initial_fixation;

labels = labels.set_field( 'error_types', 'error__none' );
labels = labels.set_field( 'error_types', 'error__initial_fixation', broke_initial_fixation );
labels = labels.set_field( 'error_types', 'error__target_fixation', target_fixation_error );

assert( sum(broke_initial_fixation | target_fixation_error) == ...
  sum(labels.where('errors')), 'Errors did not match fixation vs. target-fixation errors.' );

end

function [gaze_data, all_rt] = get_gaze_data( gaze, gaze_fields, event_time )

x_ind = find( strcmp(gaze_fields, 'x') );
y_ind = find( strcmp(gaze_fields, 'y') );
t_ind = find( strcmp(gaze_fields, 't') );
assert( all(arrayfun(@(x) ~isempty(x), [x_ind, y_ind, t_ind])) ...
  , 'At least one required gaze field (x, y, or t) was not found' );

x = cell( size(gaze, 1), 1 );
y = cell( size(x) );
t = cell( size(x) );
px = cell( size(x) );
py = cell( size(x) );
pt = cell( size(x) );

for i = 1:size( gaze, 1 )
  x{i} = dlmread( gaze{i, x_ind} );
  y{i} = dlmread( gaze{i, y_ind} );
  t{i} = dlmread( gaze{i, t_ind} );
  fname = strsplit( gaze{i, 1}, '.' );
  fname = fname{1};
  others = cellfun( @(x) strjoin({fname, x, 'txt'}, '.'), {'px', 'py', 'pt'} ...
    , 'un', false );
  others = cellfun( @dlmread, others, 'un', false );
  px{i} = others{1};
  py{i} = others{2};
  pt{i} = others{3};
end

n_trials = cellfun( @(a) size(a, 1), x );
total_size = sum( n_trials );
assert( total_size == numel(event_time), ['Mismatch between the gaze data' ...
  , ' and event times'] );

start = 1;
all_rt = nan( total_size, 1 );
for i = 1:numel(x)
  stop = start + size( x{i}, 1 ) - 1;
  current_event = event_time( start:stop );
  rt = dsp2.analysis.behavior.get_reaction_time( x{i}, y{i}, t{i}, current_event );
  all_rt( start:stop ) = rt;
  start = start + size( x{i}, 1 );
end

gaze_data.x = x;
gaze_data.y = y;
gaze_data.t = t;
gaze_data.px = px;
gaze_data.py = py;
gaze_data.pt = pt;

end

function [trial_data, fields] = get_trial_data( db, trial_info, excludes )

trial_fields = db.get_field_names( 'trial_info' );
exclude_inds = cellfun( @(x) find(strcmp(trial_fields, x)), excludes );
all_inds = true( 1, size(trial_info, 2) );
all_inds( exclude_inds ) = false;
try
  trial_data = cell2mat( trial_info(:, all_inds) );
catch err
  fprintf( ['\n Attempting to call cell2mat on the trial_info table failed' ...
    , ' with the following error:'] );
  error( err.message );
end

fields = trial_fields( all_inds );

end

function labels = build_labels( db, trial_info, meta, meta_fields )

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

%   define contexts
inds.contexts.selfboth = (cue_type == 0 | cue_type == 1) & inds.trialtypes.choice;
inds.contexts.othernone = (cue_type == 2 | cue_type == 3) & inds.trialtypes.choice;
inds.contexts.context__self = cue_type == 0 & inds.trialtypes.cued;
inds.contexts.context__both = cue_type == 1 & inds.trialtypes.cued;
inds.contexts.context__other = cue_type == 2 & inds.trialtypes.cued;
inds.contexts.context__none = cue_type == 3 & inds.trialtypes.cued;

%   define magnitudes
inds.magnitudes.high = indices.magnitude == 3;
inds.magnitudes.medium = indices.magnitude == 2;
inds.magnitudes.low = indices.magnitude == 1;
inds.magnitudes.no_reward = ...
  ~any( [inds.magnitudes.high, inds.magnitudes.medium, inds.magnitudes.low], 2 );
%   define session
inds.sessions = struct( ['session__' meta_struct.session], complete_true );
%   define actor monkey
inds.monkeys = struct( meta_struct.actor, complete_true );
%   define recipient monkey
inds.recipients = struct( meta_struct.recipient, complete_true );
%   define drugs
inds.drugs = struct( meta_struct.drug, complete_true );
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

function conts = build_gaze_data_containers( gd, labels )

fs = { 'x', 'y', 't', 'px', 'py', 'pt' };
dsp2.util.assertions.assert__isa( gd, 'struct', 'the gaze data' );
dsp2.util.assertions.assert__are_fields( gd, fs );

szs = structfun( @(x) numel(x), gd );
assert( numel(unique(szs)) == 1, 'x, y, and t arrays must be the same size.' );
sz1 = cellfun( @(x) size(x, 1), gd.(fs{1}) );
for i = 2:numel(fs)
  szc = cellfun(@(x) size(x, 1), gd.(fs{i}) );
  assert( isequaln(sz1, szc), 'x, y, and t arrays must be the same size.' );
end

assert( sum(szc(:,1)) == shape(labels, 1), ['Mismatch between number of' ...
  , 'trials in gaze data and labels.'] );

ind = false( shape(labels, 1), 1 );

conts = Container();

for i = 1:numel(fs)
  current = gd.(fs{i});
  stp = 1;
  for k = 1:numel(current)
    rows = size( current{k}, 1 );
    ind_copy = ind;
    ind_copy( stp:stp+rows-1 ) = true;
    sliced = labels.keep( ind_copy );
    cont = Container( current{k}, sliced );
    uniform = cont.one();
    uniform.data = { cont };
    uniform = uniform.require_fields( 'gaze_data_type' );
    uniform( 'gaze_data_type' ) = fs{i};
    conts = conts.append( uniform );
    stp = stp + rows;
  end
end

end
