clpse = { 'monkeys', 'trials' };
manipulation = 'pro_minus_anti';
load_kind = { 'coherence', 'reward', manipulation, clpse };

coh = dsp2.io.get_processed_measure( load_kind, 'nanmedian' );

%%  pro v anti preference
behav = io.read( dsp2.io.get_path('Behavior') );
calc_within = { 'days', 'administration', 'trialtypes', 'monkeys' };
behav = dsp2.process.manipulations.non_drug_effect( behav );
behav = dsp2.analysis.behavior.get_preference_index( behav, calc_within, {{'other', 'none'}, {'self', 'both'}} );
behav = behav.replace( 'other_none', 'otherMinusNone' );
behav = behav.replace( 'self_both', 'selfMinusBoth' );
% behav = behav.replace( 'both_self', 'bothMinusSelf' );

%%  pro minus anti preference
behav = dsp2.io.get_processed_behavior( {'preference_index', manipulation, {'monkeys', 'trials'}} );

%%

behav = behav.require_fields( 'median_split' );
med = behav.for_each( {'outcomes', 'trialtypes'}, @median );
[objs, ~, C] = behav.enumerate( {'outcomes', 'trialtypes'} );
splt = behav;
for i = 1:numel(objs)
  unqs = C(i, :);
  matched = med.only( unqs );
  assert( numel(matched.data) == 1 );
  ind = behav.where( unqs );
  abv = ind & behav.data >= matched.data;
  bel = ind & behav.data < matched.data;
  behav( 'median_split', abv ) = 'above_median';
  behav( 'median_split', bel ) = 'below_median';
end

outs = { 'otherMinusNone', 'bothMinusSelf' };
out_map = { 'otherMinusNone', 'selfMinusBoth' };

for i = 1:numel(outs)

high_days = unique( behav('days', behav.where({'choice', outs{i}, 'above_median'})) );
low_days = unique( behav('days', behav.where({'choice', outs{i}, 'below_median'})) );

med_name = 'median_split_prosocial_behavior';
coh = coh.require_fields( {med_name, 'band'} );
coh( med_name, coh.where([high_days; out_map{i}]) ) = 'high_preference'; 
coh( med_name, coh.where([low_days; out_map{i}]) ) = 'low_preference';

end

beta = coh.time_freq_mean( [50, 250], [15, 30] );
gamma = coh.time_freq_mean( [50, 250], [35, 50] );
beta( 'band' ) = 'beta';
gamma( 'band' ) = 'gamma';
banded = beta.append( gamma );

%%  median split pro - anti



%%

behav = behav.require_fields( 'lmh_split' );
[objs, inds] = behav.enumerate( {'outcomes', 'trialtypes'} );
for i = 1:numel(objs)
  obj = objs{i};
  third = prctile( obj.data, [33.333, 66.666, 100] );
  l_third = inds{i} & behav.data < third(1);
  m_third = inds{i} & behav.data >= third(1) & behav.data < third(2);
  u_third = inds{i} & behav.data >= third(2);
  behav( 'lmh_split', l_third ) = 'low_prosocial_preference';
  behav( 'lmh_split', m_third ) = 'medium_prosocial_preference';
  behav( 'lmh_split', u_third ) = 'high_prosocial_preference';
end

outs = { 'otherMinusNone', 'selfMinusBoth' };

for i = 1:2

low_days = unique( behav('days', behav.where({'choice', outs{i}, 'low_prosocial_preference'})) );
med_days = unique( behav('days', behav.where({'choice', outs{i}, 'medium_prosocial_preference'})) );
high_days = unique( behav('days', behav.where({'choice', outs{i}, 'high_prosocial_preference'})) );

med_name = 'median_split_prosocial_behavior';
coh = coh.require_fields( {med_name, 'band'} );
coh( med_name, coh.where([high_days; outs{i}]) ) = 'high_prosocial_preference'; 
coh( med_name, coh.where([low_days; outs{i}]) ) = 'low_prosocial_preference';
coh( med_name, coh.where([med_days; outs{i}]) ) = 'medium_prosocial_preference';

end

beta = coh.time_freq_mean( [50, 250], [15, 30] );
gamma = coh.time_freq_mean( [50, 250], [35, 50] );
beta( 'band' ) = 'beta';
gamma( 'band' ) = 'gamma';
banded = beta.append( gamma );

%%

med_name = 'median_split_prosocial_behavior';
coh = coh.require_fields( {med_name, 'band'} );
coh( med_name, coh.where(high_days) ) = 'above_median_prosocial_preference'; 
coh( med_name, coh.where(low_days) ) = 'below_median_prosocial_preference';

beta = coh.time_freq_mean( [50, 250], [15, 30] );
gamma = coh.time_freq_mean( [50, 250], [35, 50] );
beta( 'band' ) = 'beta';
gamma( 'band' ) = 'gamma';
banded = beta.append( gamma );

%%

plt = banded.only( {'choice'} );
plt = plt.replace( 'selfMinusBoth', 'Self vs Both' );
plt = plt.replace( 'otherMinusNone', 'Other vs None' );

plt = plt.replace( 'low_preference', 'low_prosocial_preference' );
plt = plt.replace( 'high_preference', 'high_prosocial_preference' );


figure(1); clf();
pl = ContainerPlotter();
% pl.order_groups_by = { 'low_preference', 'high_preference' };
pl.order_groups_by = { 'low_prosocial_preference', 'medium_prosocial_preference', 'high_prosocial_preference' };
pl.y_label = 'Coherence Difference';

plt.bar( pl, 'outcomes', {med_name}, {'band', 'epochs'} );

%%
axs = findobj( gcf, 'type', 'axes' );
for i = 1:numel(axs)
  h = findobj( axs(i), 'type', 'bar' );
  h(1).FaceColor = [ .7, 0, 0 ];
  h(3).FaceColor = [ 1, 0, 0 ];
  h(2).FaceColor = [0, .7, 0];
  h(4).FaceColor = [0, 1, 0];
end

%%
axs = findobj( gcf, 'type', 'axes' );
for i = 1:numel(axs)
  h = findobj( axs(i), 'type', 'bar' );
  h(1).FaceColor = [ .7, 0, 0 ];
  h(2).FaceColor = [1, 0, 0];
end


