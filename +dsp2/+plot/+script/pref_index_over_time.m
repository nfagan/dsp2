conf = dsp2.config.load();
load_date_dir = '120117';
load_p = fullfile( conf.PATHS.analyses, 'behavior', 'trial_info', load_date_dir, 'behavior' );
plt_save_path = fullfile( conf.PATHS.plots, 'behavior', dsp2.process.format.get_date_dir() );

new_behav = dsp2.util.general.fload( fullfile(load_p, 'behavior.mat') );
new_key = dsp2.util.general.fload( fullfile(load_p, 'key.mat') );
new_key = new_key.trial_info;

new_behav = new_behav.require_fields( {'sites', 'channels', 'regions'} );
new_behav = dsp2.process.format.fix_block_number( new_behav );
new_behav = dsp2.process.format.fix_administration( new_behav );

is_drug = true;

if ( ~is_drug )
  [unspc, new_behav] = new_behav.pop( 'unspecified' );
  unspc = unspc.for_each( 'days', @dsp2.process.format.keep_350, 350 ); 
  new_behav = append( new_behav, unspc );
  new_behav = dsp2.process.manipulations.non_drug_effect( new_behav );
else
  new_behav = new_behav.rm( 'unspecified' );
end

new_behav = new_behav.rm( dsp2.process.format.get_bad_days() );

%%

import dsp2.process.format.add_trial_bin;

N = 25;
step_size = 10;
allow_truncated_bin = false;
start_over_at = { 'days', 'administration', 'contexts' };
increment_for = { 'sessions', 'blocks' };

to_bin = new_behav( {'choice'} );

[I, C] = to_bin.get_indices( start_over_at );

all_binned = Container();

for i = 1:numel(I)
  one_day = to_bin(I{i});
  
  start_from = 1;
  
  block_inds = one_day.get_indices( increment_for );
  
  for j = 1:numel(block_inds)
    binned = add_trial_bin( one_day(block_inds{j}), N, start_from, step_size, allow_truncated_bin );
    
    if ( isempty(binned) ), continue; end
    
    bins = binned( 'trial_bin' );
    bins_ = zeros( size(bins) );
    for h = 1:numel(bins), bins_(h) = str2double(bins{h}(numel('trial_bin__')+1:end)); end
    
    start_from = max( bins_ ) + 1;
    
    all_binned = all_binned.append( binned );
  end
end

%%

pref_within = { 'days', 'administration', 'trialtypes', 'contexts', 'trial_bin' };

pref = dsp2.analysis.behavior.get_preference_index( all_binned, pref_within );

pref(isnan(pref.data)) = [];

%%

pl = ContainerPlotter();
fig = figure(2);
clf( fig );

plt = pref( {'choice', 'saline'} );

bins = plt( 'trial_bin' );
bin_ns = shared_utils.container.cat_parse_double( 'trial_bin__', plt('trial_bin') );
[~, sorted_ind] = sort( bin_ns );

pl.order_by = bins( sorted_ind );
pl.summary_function = @nanmean;

x_is = 'trial_bin';
lines_are = { 'outcomes' };
panels_are = { 'outcomes', 'administration', 'drugs' };

pl.plot_by( plt, x_is, lines_are, panels_are );

%%

import shared_utils.container.cat_parse_double;

save_p = fullfile( conf.PATHS.plots, 'behavior', dsp2.process.format.get_date_dir(), 'preference_index_over_trials' );
drug_colors = { 'r', 'b' };

drugs = pref.pcombs( 'drugs' );

fig = figure(1);
clf( fig );

h = [];

for idx = 1:size( drugs, 1 )
  
plt = pref( {'choice', drugs{idx, 1}} );

[I, C] = plt.get_indices( {'outcomes', 'administration'} );

outs = unique( C(:, 1) );
map = containers.Map( outs, 1:numel(outs) );

bin_pre = max( cat_parse_double('trial_bin__', plt.uniques_where('trial_bin', 'pre')) );
bin_post = max( cat_parse_double('trial_bin__', plt.uniques_where('trial_bin', 'post')) );

t_series_means = nan( 1, bin_pre+bin_post );
t_series_errs = nan( size(t_series_means) );

for i = 1:numel(I)
  subset = plt(I{i});
  
  if ( strcmp(C{i, 2}, 'pre') )
    start_from = 0;
  else
    start_from = bin_pre;
  end
  
  bins = subset( 'trial_bin' );
  bin_ns = shared_utils.container.cat_parse_double( 'trial_bin__', bins );
  [~, sorted_ind] = sort( bin_ns );
  bins = bins( sorted_ind );
  
  for j = 1:numel(bins)
    one_bin = subset(bins(j));
    
    y_coord = shared_utils.container.cat_parse_double( 'trial_bin__', bins{j} );
    
    t_series_means(map(C{i, 1}), start_from+y_coord) = nanmean( one_bin.data );
    t_series_errs(map(C{i, 1}), start_from+y_coord) = rowops.sem( one_bin.data );
    
  end
end

for i = 1:size(t_series_means, 1)
  subplot( 2, 1, i );
  means = t_series_means(i, :);
  errs = t_series_errs(i, :);
  
  h(idx) = errorbar( 1:numel(means), means, errs );
%   h(idx) = plot( means, drug_colors{idx} );
  hold on;
%   plot( means+errs, drug_colors{idx} );
%   plot( means-errs, drug_colors{idx} );
%   ylim( [-0.4, 0.6] );
%   xlim( [] );
  plot( [bin_pre+0.5, bin_pre+0.5], get(gca, 'ylim'), 'k' );
%   title_str = strjoin( [outs{i}, plt.flat_uniques('drugs')], ' | ' );
  title_str = strjoin( outs(i), ' | ' );
  title( strrep(title_str, '_', ' ') );
end

end

legend( h, drugs );

dsp2.util.general.require_dir( save_p );

fname = sprintf( 'saline_vs_ot_error_bars_small_limits_bin%d_step%d', N, step_size );

dsp2.util.general.save_fig(gcf, fullfile(save_p, fname), {'fig', 'png', 'epsc'});



