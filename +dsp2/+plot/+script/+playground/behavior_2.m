conf = dsp2.config.load();

io = dsp2.io.get_dsp_h5();
p = dsp2.io.get_path( 'behavior' );
% behav = io.read( p );
behav = dsp2.util.general.fload( fullfile(conf.PATHS.analyses, 'behavior', 'trial_info', '112817', 'behavior.mat') );
key = io.read( io.fullfile(p, 'Key') );

plt_save_path = fullfile( conf.PATHS.plots, 'behavior', dsp2.process.format.get_date_dir() );
dsp2.util.general.require_dir( plt_save_path );

behav = dsp2.process.format.fix_block_number( behav );
behav = dsp2.process.format.fix_administration( behav );

%%

meas_type = 'rt';
drug_type = 'none';

is_within_mag_cue = false;
is_drug = false;
is_post_only = false;
is_post_minus_pre = false;
is_post_v_pre = false;
is_pref_proportion = false;
is_rt = true;
is_pref_index = false;
is_errors = false;

%%

processed_behav = behav.require_fields( {'channels','regions','sites', 'contexts'} );
processed_behav = processed_behav.replace( 'selfboth', 'selfBoth' );
processed_behav = processed_behav.replace( 'othernone', 'otherNone' );
processed_behav( 'contexts', processed_behav.where({'self','both', 'choice'}) ) = 'selfBoth';
processed_behav( 'contexts', processed_behav.where({'other','none', 'choice'}) ) = 'otherNone';

if ( is_pref_proportion )
  w_in = { 'days', 'administration', 'contexts', 'trialtypes' };
else
  w_in = { 'days', 'administration', 'trialtypes' };
end

if ( is_within_mag_cue )
  w_in{end+1} = 'magnitudes';
else
  processed_behav = processed_behav.collapse( 'magnitudes' );
end

if ( ~is_drug )
  [non_inject, processed_behav] = processed_behav.pop( 'unspecified' );
  non_inject = non_inject.for_each( 'days', @dsp2.process.format.keep_350, 350 );
  processed_behav = processed_behav.append( non_inject );
  processed_behav = dsp2.process.manipulations.non_drug_effect( processed_behav );
else
  processed_behav = processed_behav.rm( 'unspecified' );
end

if ( ~is_errors )
  processed_behav = processed_behav.rm( {'errors', 'cued'} );
else
  percs = processed_behav.for_each( w_in, @dsp2.analysis.behavior.get_error_percentages );
end

targ_field = 'outcomes';
targ_items = processed_behav.pcombs( targ_field );

if ( is_pref_proportion )
  percs = processed_behav.for_each( w_in, @percentages, targ_field, targ_items );
elseif ( is_pref_index )
  percs = dsp2.analysis.behavior.get_preference_index( processed_behav, w_in ); 
elseif ( is_rt )
  percs = dsp2.analysis.behavior.get_rt( processed_behav, key );
  percs = percs.each1d( [w_in, 'outcomes'], @rowops.mean );
end

if ( is_drug && is_post_only )
  percs = percs.only( 'post' );
elseif ( is_drug )
  percs = percs.collapse( {'blocks', 'recipients', 'sessions'} );
  if ( is_post_minus_pre )
    percs = dsp2.process.manipulations.post_minus_pre( percs );
  end
end

%%  BAR PER DAY
figs_are = { 'drugs', 'days' };
x_is = 'administration';
groups_are = { 'outcomes' };
panels_are = { 'drugs' };

meas_type = 'rt';

per_day_save_path = fullfile( plt_save_path, meas_type, 'per_day_plots', 'drug' );
dsp2.util.general.require_dir( fullfile(per_day_save_path, 'oxytocin') );
dsp2.util.general.require_dir( fullfile(per_day_save_path, 'saline') );

C = percs.pcombs( figs_are );
for i = 1:size(C, 1)
  plt = percs.only( C(i, :) );
  
  drug_name = C{i, 1};
  
  pl = ContainerPlotter();
  pl.order_by = { 'pre', 'post' };
  pl.y_lim = [0, .4];
  
  figure(1); clf(); colormap( 'default' );
  
  plt.bar( pl, x_is, groups_are, panels_are );
  
  if ( DO_SAVE )
    fname = dsp2.util.general.append_uniques( plt, meas_type, {'drugs', 'days'} );
    dsp2.util.general.save_fig( gcf, fullfile(per_day_save_path, drug_name, fname) ...
      , {'epsc', 'png', 'fig'} );
  end
end

%%  SD CUTOFFS

n_devs = 1.5;

m_within = [ setdiff(w_in, 'days'), 'outcomes' ];

if ( is_drug )
  m_within{end+1} = 'drugs';
end

perc_means = percs.each1d( m_within, @rowops.mean );
perc_devs = percs.each1d( m_within, @rowops.std );

good_data = percs.logic( true );
[I, C] = percs.get_indices( m_within );

for i = 1:numel(I)
  subset = percs(I{i});
  matching_means = get_data( perc_means.only(C(i, :)) );
  matching_devs = get_data( perc_devs.only(C(i, :)) );
  below_thresh = subset.data < matching_means - matching_devs * n_devs;
  above_thresh = subset.data > matching_means + matching_devs * n_devs;
  good_data(I{i}) = ~below_thresh & ~above_thresh;
end

cont_good_data = Container( good_data, percs.labels );
cont_good_percs = cont_good_data.each1d( [m_within, 'days'], @(x) perc(x) );

cutoffed = percs.keep( good_data );

%% BAR

DO_SAVE = true;

cutoffed = percs.rm( {'day__05172016', 'day__05192016', 'day__02142017' });

plt = cutoffed;

pl = ContainerPlotter();
pl.y_label = meas_type;
% pl.y_lim = [-.3, .4];

figure(2); clf(); colormap( 'default' );

if ( ~is_drug )
  if ( is_errors )
    plt.data = plt.data * 100;
    pl.x_tick_rotation = 0;
    pl.order_by = { 'context__self', 'context__both', 'context__other', 'context__none' };
    pl.per_panel_labels = true;
    plt.bar( pl, 'contexts', 'magnitudes', {'trialtypes', 'administration'} );
  else
    pl.order_by = { 'low', 'medium', 'high' };
    plt.bar( pl, 'magnitudes',  {'outcomes', 'trialtypes'} );
  end
else
  pl.order_by = { 'self', 'both', 'other', 'none' };
  plt.bar( pl, 'drugs', 'administration', {'outcomes', 'trialtypes'} );
end

f = FigureEdits( gcf );
% f.one_legend();

fname = dsp2.util.general.append_uniques( plt, 'proportions', {'drugs', 'outcomes', 'magnitudes', 'trialtypes'} );
full_plt_save_path = fullfile( plt_save_path, meas_type, drug_type );
if ( DO_SAVE )
  dsp2.util.general.require_dir( full_plt_save_path );
  dsp2.util.general.save_fig( gcf, fullfile(full_plt_save_path, fname), {'epsc', 'png', 'fig'} );
end

%%  STATS -- PREF proportion

ctx_pairs = { {'self', 'both'}, {'other', 'none'} };
to_stats = percs;
stats = Container();

for i = 1:numel(ctx_pairs)
  subset_a = to_stats.only(ctx_pairs{i}{1});
  subset_b = to_stats.only(ctx_pairs{i}{2});
  
  [~, p] = ttest2( subset_a.data, subset_b.data );
  
  result = set_data( one(subset_a), p );
  stats = stats.append( result );
end

%%  STATS -- PREF index

sb = percs.only( 'both_self' );
on = percs.only( 'other_none' );

p_sb = signrank( sb.data );
p_on = signrank( on.data );

stats = Container();
stats = extend( stats, set_data(one(sb), p_sb), set_data(one(on), p_on) );

%%  STATS -- RT

grp = percs.full_fields( 'outcomes' );
[p, ~, stats] = anova1( percs.data, grp );
[c, ~, ~, gnames] = multcompare( stats );

%%  STATS -- PREF index anova, drug

to_stats = cutoffed;
grp = { cutoffed('drugs', :), cutoffed('outcomes', :) };
[p, ~, stats] = anovan( to_stats.data, grp, 'model', 'full' );
[c, ~, ~, gnames] = multcompare( stats, 'dimension', 1:2 );
C = dsp2.util.general.multcompare_to_cell( c, gnames );

%%  STATS -- PREF index sign rank

to_stats = cutoffed;
outs = to_stats( 'outcomes' );
pref_stats = Container();
for i = 1:numel(outs)
  oxy = to_stats.only( {'oxytocin', outs{i}} );
  sal = to_stats.only( {'saline', outs{i}} );
  assert( ~isempty(oxy) && ~isempty(sal) );
  [~, p1] = ttest2( oxy.data, sal.data );
  pref_stats = append( pref_stats, set_data(one(oxy), p1) );
end

%% HIST

figure(1); clf(); colormap( 'default' );

plt = percs.only( 'oxytocin' );
pl = ContainerPlotter();
pl.y_label = 'frequency';

if ( ~is_drug )
  plt.bar( pl, 'sessions',  'outcomes' );
else
  pl.order_by = { 'saline', 'oxytocin' };
  plt.hist( pl, 30, [], {'drugs', 'outcomes', 'administration'} );
end


