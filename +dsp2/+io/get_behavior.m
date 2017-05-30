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
defaults.INCLUDE_GAZE = true;
defaults.config = dsp2.config.load();

params = dsp2.util.general.parsestruct( defaults, varargin );

DATA_FIELDS.meta = { 'session', 'actor', 'recipient', 'drug' };
DATA_FIELDS.gaze = { 'x', 'y', 't' };
DATA_FIELDS.events = { 'fixOn', 'targOn' };
EXCLUDE_FIELDS.trial_info = { 'session' };

INCLUDE_GAZE = params.INCLUDE_GAZE;

%   DATABASE

db = dsp2.database.get_sqlite_db( 'config', params.config );

if ( isequal(params.sessions, 'all') )
  SESSIONS = db.get_sessions();
else
  SESSIONS = dsp2.util.general.ensure_cell( params.sessions );
end

behavioral_data = Structure.create( {'trial_info'}, Container() );

for i = 1:numel(SESSIONS)
  session = sprintf( '"%s"', SESSIONS{i} );
  fprintf( '\n - Processing Session %s (%d of %d)', session, i, numel(SESSIONS) );
  
  trial_info =  db.get_fields_where_session( '*', 'trial_info', session );
  meta =        db.get_fields_where_session( DATA_FIELDS.meta, 'meta', session );
  gaze =        db.get_fields_where_session( DATA_FIELDS.gaze, 'gaze', session );
  events =      db.get_fields_where_session( DATA_FIELDS.events, 'events', session );
  
  labels = build_labels( db, trial_info, meta, DATA_FIELDS.meta );
  [trial_data, fields] = get_trial_data( db, trial_info, EXCLUDE_FIELDS.trial_info );
  
  if ( INCLUDE_GAZE )
    events = cell2mat( events );
    targ_on_time = diff( events, 1, 2 );
    [~, rt] = get_gaze_data( gaze, DATA_FIELDS.gaze, targ_on_time );
    trial_data(:, end+1) = rt;
    fields{end+1} = 'reaction_time';
  end
  
  cont = Container( trial_data, labels );
  behavioral_data.trial_info = behavioral_data.trial_info.append( cont );
  
  if ( i == numel(SESSIONS) )
    all_data_fields.trial_info = fields;
  end
end

behavioral_data = behavioral_data.each( @(x) dsp__post_process(x) );

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

for i = 1:size( gaze, 1 )  
  x{i} = dlmread( gaze{i, x_ind} );
  y{i} = dlmread( gaze{i, y_ind} );
  t{i} = dlmread( gaze{i, t_ind} );  
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

%   define contexts
inds.contexts.selfboth = cue_type == 0 | cue_type == 1;
inds.contexts.othernone = cue_type == 2 | cue_type == 3;

%   define trialtypes
inds.trialtypes.choice = logical( indices.trialType );
inds.trialtypes.cued = ~inds.trialtypes.choice;
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
