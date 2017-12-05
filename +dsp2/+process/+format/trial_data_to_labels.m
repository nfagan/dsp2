function labels = trial_data_to_labels( data, key, desired_trial_cols )

for i = 1:numel(desired_trial_cols)
  col_ind = strcmpi( key, desired_trial_cols{i} );
  assert( any(col_ind), 'Could not find column ''%s''', desired_trial_cols{i} );
  indices.(desired_trial_cols{i}) = data(:, col_ind);
end

complete_true = true( size(data, 1), 1 );

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
if ( any(strcmpi(desired_trial_cols, 'magnitude')) )
  inds.magnitudes.high = indices.magnitude == 3;
  inds.magnitudes.medium = indices.magnitude == 2;
  inds.magnitudes.low = indices.magnitude == 1;
  inds.magnitudes.no_reward = ...
    ~any( [inds.magnitudes.high, inds.magnitudes.medium, inds.magnitudes.low], 2 );
end
%   define blocks
% blocks = unique( indices.folder );
% for i = 1:numel(blocks)
%   current_ind = indices.folder == blocks(i);
%   inds.blocks.(sprintf('block__%d', blocks(i))) = current_ind; 
% end
%   define trials
trials = unique( indices.trials );
for i = 1:numel(trials)
  current_ind = indices.trials == trials(i);
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