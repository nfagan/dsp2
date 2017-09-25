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

pref = behav.for_each( 'contexts', @get_preference_index, 'days' );
pref = pref( ~isnan(pref.data) & ~isinf(pref.data) );

calc_each = { 'days', 'contexts' };
props_for = 'looks_to';
look_types = behav.pcombs( {'looks_to'} );

gaze = behav.for_each( calc_each, @proportions, props_for, look_types );

drugs_only = gaze.rm( 'unspecified' );
drugs_only = drugs_only( ~isnan(drugs_only.data) & ~isinf(drugs_only.data) );

%%  get median preference per drug, over days

modded = drugs_only;
modded = modded.each1d( {'days', 'contexts'}, @rowops.nanmean );
modded = modded.collapse( {'sessions', 'blocks', 'administration'} );

nans_or_infs = isnan( modded.data ) | isinf( modded.data );

modded = modded( ~nans_or_infs );

med = modded.each1d( {'drugs', 'contexts'}, @rowops.nanmedian );

%%  split into low / high preference

low_lab = 'low_preference';
high_lab = 'high_preference';

pref = pref.require_fields( 'preference_group' );

median_split = drugs_only.each1d( {'days', 'contexts'}, @rowops.nanmean );
median_split = median_split.require_fields( 'preference_group' );

cmbs = median_split.pcombs( {'drugs', 'contexts'} );

for i = 1:size(cmbs, 1)
  
  row = cmbs(i, :);
  drug = row{1};
  context = row{2};
  
  drug_ind_all = median_split.where( row );
  drug_ind_med = med.where( row );
  
  below_ind = median_split.data < med.data(drug_ind_med) & drug_ind_all;
  above_ind = median_split.data >= med.data(drug_ind_med) & drug_ind_all;
  
  median_split( 'preference_group', below_ind ) = low_lab;
  median_split( 'preference_group', above_ind ) = high_lab;
  
  low_days = unique( median_split('days', median_split.where([row, low_lab])) );
  high_days = unique( median_split('days', median_split.where([row, high_lab])) );
  
  pref_ind_low = pref.where( [row(:); low_days(:)] );
  pref_ind_high = pref.where( [row(:); high_days(:)] );
  
  pref( 'preference_group', pref_ind_low ) = low_lab;
  pref( 'preference_group', pref_ind_high ) = high_lab;
 
end

%%  plot
plt = pref;
plt = plt.rm( {'unspecified', 'looked_to_nothing'} );

x_is = 'preference_group';
groups_are = 'looks_to';
panels_are = {'administration', 'drugs', 'contexts' };

figure(1); clf();

pl = ContainerPlotter();
pl.x_tick_rotation = 0;
pl.order_by = { low_lab, high_lab };
pl.y_label = 'Proportion of trials';

plt.bar( pl, x_is, groups_are, panels_are );

F = FigureEdits( gcf );
F.one_legend();
