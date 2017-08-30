function catted = concat(arr)

%   CONCAT -- Concatenate an array of Container objects.
%
%     IN:
%       - `arr` (cell array of Container objects, {})
%     OUT:
%       - `catted` (Container, {})

dsp2.util.assertions.assert__isa( arr, 'cell', 'the array of Container objects' );
if ( isempty(arr) ), catted = {}; return; end
classes = cellfun( @class, arr, 'un', false );
assert( numel(unique(classes)) == 1 && isa(arr{1}, 'Container') ...
  , 'Each array element must be a Container object of the same subclass.' );
cellfun( @(x) assert(isa(x.labels, 'SparseLabels'), ['The labels' ...
  , ' of all Container objects must be SparseLabels.']), arr );
%   we can only do the optimized routine for these data types
prealc_dtypes = { 'double', 'logical' };
if ( ~any(strcmp(prealc_dtypes, class(arr{1}.data))) )
  catted = extend( arr{:} );
  return;
end
if ( numel(arr) == 1 )
  catted = arr{1};
  return;
end
is_signal_cont = strcmp( classes{1}, 'SignalContainer' );
stat_fs = {};
if ( is_signal_cont )
  stat_fs = cellfun( @(x) fieldnames(x.trial_stats), arr, 'un', false );
  assert( isequal(stat_fs{:}), 'Trial stat fields must be equal.' );
  stat_fs = stat_fs{1};
end
first = arr{1};
cats = first.labels.categories;
unqs = unique( cats );
dtype = class( first.data );
sz = size( first.data );
N = sz(1);
all_labs = first.labels.labels;
all_cats = cats;
total_n_true = sum(sum(first.labels.indices));
for i = 2:numel(arr)
  [all_labs, ind] = sort( all_labs );
  all_cats = all_cats( ind );
  current = arr{i};
  curr_size = size( current.data );
  
  assert( isequal(unqs, unique(current.labels.categories)), ['Categories' ...
    , ' must match between labels objects.'] );
  assert( strcmp(class(current.data), dtype), 'Dtypes must be consistent.' );
  assert( all(sz(2:end) == curr_size(2:end)), ['Size of arrays beyond the' ...
    , 'first dimension must match.'] )
  
  [curr_labs, ind] = sort( current.labels.labels );
  curr_cats = current.labels.categories( ind );
  shared = intersect( curr_labs, all_labs );
  new = setdiff( curr_labs, all_labs );
  n_new = numel( new );
  shared_cats_all = all_cats( cellfun(@(x) find(strcmp(all_labs, x)), shared ) );
  shared_cats_curr = curr_cats( cellfun(@(x) find(strcmp(curr_labs, x)), shared) );
  assert( isequal(shared_cats_all, shared_cats_curr), ['Some of the labels' ...
    , ' shared between objects appear in different categories.'] );
  if ( n_new > 0 )
    all_labs(end+1:end+n_new) = new;
    all_cats(end+1:end+n_new) = curr_cats( cellfun(@(x) find(strcmp(curr_labs, x)), new) );
  end
  N = N + curr_size(1);
  total_n_true = total_n_true + sum(sum(current.labels.indices));
end

n_labs = numel( all_labs );
new_data = zeros( [N, sz(2:end)], 'like', first.data );
% new_inds = spalloc( N, n_labs, total_n_true );
new_inds = false( N, n_labs );

trial_stats = struct();
trial_ids = [];

if ( is_signal_cont )
  for i = 1:numel(stat_fs)
    curr_stat = first.trial_stats.(stat_fs{i});
    stat_sz = size( curr_stat );
    trial_stats.(stat_fs{i}) = zeros( [N, stat_sz(2:end)], 'like', curr_stat );
  end
  trial_ids = zeros( N, 1 );
end

stp = 1;
colons = repmat( {':'}, 1, ndims(new_data)-1 );
for i = 1:numel(arr)
  dat = arr{i}.data;
  labs = arr{i}.labels.labels;
  curr_inds = arr{i}.labels.indices;
  lab_inds = cellfun( @(x) find(strcmp(all_labs, x)), labs );
  n = size( dat );
  new_data( stp:stp+n-1, colons{:} ) = dat;
  new_inds( stp:stp+n-1, lab_inds ) = curr_inds;
  if ( is_signal_cont )
    for k = 1:numel(stat_fs)
      trial_stats.(stat_fs{k})(stp:stp+n-1, :) = arr{i}.trial_stats.(stat_fs{k});
    end
    trial_ids( stp:stp+n-1 ) = arr{i}.trial_ids;
  end
  stp = stp + n;
end

labels_obj = SparseLabels();
labels_obj.labels = all_labs;
labels_obj.categories = all_cats;
labels_obj.indices = sparse( new_inds );

if ( is_signal_cont )
  catted = first.set_data_and_labels( new_data, labels_obj );
  catted.trial_ids = trial_ids;
  catted.trial_stats = trial_stats;
  return;
else
  catted = Container( new_data, labels_obj );
end

end