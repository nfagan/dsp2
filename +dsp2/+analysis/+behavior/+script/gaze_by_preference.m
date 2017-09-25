import dsp2.analysis.behavior.get_preference_index;

conf = dsp2.config.load();

io = dsp2.io.get_dsp_h5();

p = dsp2.io.get_path( 'behavior' );

behav = io.read( p );
days = io.get_days( p );
key = io.read( io.fullfile(p, 'Key') );

behav = dsp2.process.format.fix_block_number( behav );
behav = dsp2.process.format.fix_administration( behav );

date_dir = dsp2.process.format.get_date_dir();
sub_dir = fullfile( 'behavior', 'gaze_split_by_preference', date_dir );
plt_save_path = fullfile( conf.PATHS.plots, sub_dir );
dsp2.util.general.require_dir( plt_save_path );

behav = behav.add_field( 'looks_to' );

%   looks to bottle are actually looks to monkey
looked_to_bottle = strcmp( key, 'lateLookCount' );
looked_to_monkey = strcmp( key, 'lateBottleLookCount' );

trials_looked_to_bottle = behav.data(:, looked_to_bottle) > 0;
trials_looked_to_monkey = behav.data(:, looked_to_monkey) > 0;

trials_looked_to_nothing = ~trials_looked_to_bottle & ~trials_looked_to_monkey;
trials_looked_to_bottle = trials_looked_to_bottle & ~trials_looked_to_monkey;
trials_looked_to_monkey = ~trials_looked_to_bottle & ~trials_looked_to_nothing;

behav( 'looks_to', trials_looked_to_bottle ) = 'looked_to_bottle';
behav( 'looks_to', trials_looked_to_monkey ) = 'looked_to_monkey';
behav( 'looks_to', trials_looked_to_nothing ) = 'looked_to_nothing';

pref = behav.for_each( 'contexts', @get_preference_index, {'days', 'sessions', 'blocks', 'trialtypes'} );

drugs_only = pref.rm( 'unspecified' );
drugs_only = drugs_only( ~isnan(drugs_only.data) & ~isinf(drugs_only.data) );

%%  get median preference per drug, over days

modded = drugs_only;
modded = modded.each1d( {'days', 'outcomes', 'trialtypes'}, @rowops.nanmean );
modded = modded.collapse( {'sessions', 'blocks', 'administration'} );

nans_or_infs = isnan( modded.data ) | isinf( modded.data );

modded = modded( ~nans_or_infs );

med = modded.each1d( {'drugs', 'outcomes', 'trialtypes'}, @rowops.nanmedian );

%%  split into low / high preference

low_lab = 'low_preference';
high_lab = 'high_preference';

behav = behav.require_fields( 'preference_group' );

median_split = drugs_only.each1d( {'days', 'outcomes', 'trialtypes'}, @rowops.nanmean );
median_split = median_split.require_fields( 'preference_group' );

cmbs = median_split.pcombs( {'drugs', 'outcomes', 'trialtypes'} );

for i = 1:size(cmbs, 1)
  
  row = cmbs(i, :);
  drug = row{1};
  outcome = row{2};
  
  drug_ind_all = median_split.where( row );
  drug_ind_med = med.where( row );
  
  below_ind = median_split.data < med.data(drug_ind_med) & drug_ind_all;
  above_ind = median_split.data >= med.data(drug_ind_med) & drug_ind_all;
  
  median_split( 'preference_group', below_ind ) = low_lab;
  median_split( 'preference_group', above_ind ) = high_lab;
  
  %   find the context associated with the current outcome
  matching_context = median_split.uniques_where( 'contexts', outcome );
  assert( numel(matching_context) == 1, 'Wrong context.' );
  
  low_days = unique( median_split('days', median_split.where([row, low_lab])) );
  high_days = unique( median_split('days', median_split.where([row, high_lab])) );
  
  behav_ind_low = behav.where( [drug, matching_context, low_days(:)'] );
  behav_ind_high = behav.where( [drug, matching_context, high_days(:)'] );
  
  behav( 'preference_group', behav_ind_low ) = low_lab;
  behav( 'preference_group', behav_ind_high ) = high_lab;
 
end

%%  get proportion of social gaze

calc_each = { 'days', 'contexts', 'preference_group', 'administration', 'trialtypes' };
props_for = 'looks_to';
look_types = behav.pcombs( {'looks_to'} );

gaze = behav.for_each( calc_each, @proportions, props_for, look_types );

%%    RT

rt_field = strcmp( key, 'reaction_time' );
rt = behav;
rt.data = rt.data(:, rt_field);

rt = rt.only( 'choice' );

rt = rt( rt.data >= .120 & rt.data <= .4 );

rt = rt.keep( ~isnan(rt.data) );
rt = rt.rm( {'errors', 'unspecified'} );
% rt = rt.only( 'post' );

rt = rt.each1d( {'days', 'administration', 'outcomes', 'trialtypes', 'magnitudes'}, @rowops.nanmean );
rt = rt.collapse( {'blocks', 'sessions', 'recipients'} );
% rt = dsp2.process.manipulations.post_over_pre( rt );
% rt = dsp2.process.manipulations.post_minus_pre( rt );

pl = ContainerPlotter();
% pl.order_by = { 'selfboth', 'othernone' };
pl.order_by = { 'self', 'both', 'other', 'none' };

figure(1); clf();

% rt.data = (rt.data - 1) * 100;

% rt.plot_by( pl, 'contexts', 'drugs', 'administration' );
rt.plot_by( pl, 'outcomes', 'magnitudes', {'administration', 'drugs'} );

%%

calc_each = { 'days', 'contexts', 'administration', 'trialtypes' };
props_for = 'looks_to';
look_types = behav.pcombs( {'looks_to'} );

gaze = behav.for_each( calc_each, @proportions, props_for, look_types );

%%

figure(1); clf();

pl = ContainerPlotter();

plt = gaze;

plt = plt.rm( {'unspecified', 'looked_to_nothing', 'cued'} );

plt.plot_by( pl, 'contexts', 'looks_to', {'administration', 'drugs'} );


%%

only_pre = rt.only( 'pre' );
only_post = rt.only( 'post' );

bin_size = 100;

figure(2); clf();

hist( only_pre.data, bin_size );
title( 'pre' );

figure(3); clf();
hist( only_post.data, bin_size );
title( 'post' );

%%

plt = pref.keep( ~isnan(pref.data) & ~isinf(pref.data) );

x_is = 'outcomes';
groups_are = 'drugs';
panels_are = {'monkeys' };

figure(1); clf();

pl = ContainerPlotter();
pl.x_tick_rotation = 0;
pl.order_by = { low_lab, high_lab };
pl.y_label = 'Proportion of trials';

plt.bar( pl, x_is, groups_are, panels_are );

%%  plot

plt = gaze;
plt = plt.rm( {'unspecified', 'looked_to_nothing', 'cued'} );
plt = plt.replace( 'selfboth', 'both : self' );
plt = plt.replace( 'othernone', 'other : none' );
% plt = plt.only( 'post' );
plt = dsp2.process.manipulations.post_over_pre( plt.collapse({'sessions', 'blocks'}) );

x_is = 'preference_group';
groups_are = {'looks_to', 'drugs'};
panels_are = {'administration', 'contexts' };

figure(1); clf();

pl = ContainerPlotter();
pl.x_tick_rotation = 0;
pl.order_by = { low_lab, high_lab };
pl.order_groups_by = { 'looked_to_monkey', 'looked_to_bottle' };
pl.y_label = 'Proportion of trials';

plt.bar( pl, x_is, groups_are, panels_are );

F = FigureEdits( gcf );
F.one_legend();

%%  plot

plt = gaze;
plt = plt.rm( {'unspecified', 'looked_to_nothing', 'cued'} );
plt = plt.replace( 'selfboth', 'both : self' );
plt = plt.replace( 'othernone', 'other : none' );
% plt = plt.only( 'post' );
plt = dsp2.process.manipulations.post_over_pre( plt.collapse({'sessions', 'blocks'}) );

x_is = 'looks_to';
groups_are = 'drugs';
panels_are = {'administration'  };

figure(1); clf();

pl = ContainerPlotter();
pl.x_tick_rotation = 0;
pl.order_by = { low_lab, high_lab };
pl.order_groups_by = { 'looked_to_monkey', 'looked_to_bottle' };
pl.y_label = 'Proportion of trials';

plt.bar( pl, x_is, groups_are, panels_are );

F = FigureEdits( gcf );
F.one_legend();

