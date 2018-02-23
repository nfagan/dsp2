function all_labels = build_labels( trial_info, trial_tbl_fields, meta, meta_fields )

desired_trial_cols = { 'trialType', 'magnitude', 'cueType', 'fix', 'folder', 'trial' };
desired_meta_fields = { 'session', 'actor', 'recipient', 'drug' };

meta_session_index = strcmp( meta_fields, 'session' );
assert( sum(meta_session_index) == 1, 'Could not locate "session" in meta fields.' );

unq_sessions = unique( meta(:, meta_session_index) );

all_labels = SparseLabels();

for idx = 1:numel(unq_sessions)
  fprintf( '\n %d of %d', idx, numel(unq_sessions) );
  
  current_session = unq_sessions{idx};
  
  trial_info_session_index = strcmp( trial_tbl_fields, 'session' );
  
  assert( sum(trial_info_session_index) == 1, ['Could not locate "session"' ...
    , ' in trial info fields.'] );
  
  meta_this_session_index = strcmp( meta(:, meta_session_index), current_session );
  
  assert( sum(meta_this_session_index) == 1, '%d elements matched "%s" for this meta file.' ...
    , sum(meta_this_session_index), current_session );
  
  current_meta = meta(meta_this_session_index, :);
  
  trial_info_this_session = strcmp( trial_info(:, trial_info_session_index), current_session );
  
  assert( any(trial_info_this_session), 'Could not locate session "%s" in trial info.' ...
    , current_session );
  
  current_trial_info = trial_info(trial_info_this_session, :);
  
  indices = struct();

  for i = 1:numel(desired_trial_cols)
    col_ind = strcmp( trial_tbl_fields, desired_trial_cols{i} );
    assert( any(col_ind), 'Could not find column ''%s''', desired_trial_cols{i} );
    indices.(desired_trial_cols{i}) = cell2mat( current_trial_info(:, col_ind) );
  end

  meta_struct = struct();
  for i = 1:numel(desired_meta_fields)
    meta_field_name = desired_meta_fields{i};
    col_ind = strcmp( meta_fields, meta_field_name );
    assert( sum(col_ind) == 1, 'Could not locate meta field "%s"', meta_field_name );
    meta_struct.(meta_field_name) = char( current_meta(:, col_ind) );
  end

  complete_true = true( size(current_trial_info, 1), 1 );

  %   define outcomes

  cue_type = indices.cueType;
  fixed_on = indices.fix;
  
  inds = struct();
  
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
  
  sparse_labels_inputs{end+1} = struct( 'label', current_session ...
    , 'category', 'session_ids', 'index', complete_true );

  labels = SparseLabels( sparse_labels_inputs );
  
  all_labels = all_labels.append( labels );
end

end