conf = dsp2.config.load();
load_date_dir = '120117';
load_p = fullfile( conf.PATHS.analyses, 'behavior', 'trial_info', load_date_dir, 'behavior' );

new_behav = dsp2.util.general.fload( fullfile(load_p, 'behavior.mat') );
new_key = dsp2.util.general.fload( fullfile(load_p, 'key.mat') );
new_key = new_key.trial_info;

new_behav = new_behav.require_fields( {'sites', 'channels', 'regions'} );
new_behav = dsp2.process.format.fix_block_number( new_behav );
new_behav = dsp2.process.format.fix_administration( new_behav );
[unspc, new_behav] = new_behav.pop( 'unspecified' );
unspc = unspc.for_each( 'days', @dsp2.process.format.keep_350, 350 ); 
new_behav = append( new_behav, unspc );
new_behav = dsp2.process.manipulations.non_drug_effect( new_behav );

%%

looks = dsp2.analysis.behavior.get_combined_looking_measures( new_behav, new_key );
looks = dsp2.process.format.rm_bad_days( looks );

%%

calc = looks;

calc_within = { 'days', 'looks_to', 'look_period', 'outcomes', 'trialtypes', 'magnitudes' };
freq = calc({'count'});
quantity = calc({'quantity'});
freq = dsp2.analysis.behavior.get_gaze_frequency( freq, calc_within );

%%

io = dsp2.io.get_dsp_h5();
conf = dsp2.config.load();

meas_type = 'coherence';
kind = 'complete';
manip = 'standard';
epoch = 'reward';

p = dsp2.io.get_path( 'measures', meas_type, kind, epoch );
days = io.get_days( p );
days = setdiff( days, dsp2.process.format.get_bad_days() );

date_dir = dsp2.process.format.get_date_dir();
save_p = fullfile( conf.PATHS.analyses, 'spectral_glm', date_dir, meas_type, kind, manip, epoch );
dsp2.util.general.require_dir( save_p );

m_within = conf.SIGNALS.meaned.mean_within;
m_within = union( m_within, 'magnitudes' );

match_for = { 'outcomes', 'trialtypes', 'magnitudes' };

rois = dsp2.process.format.get_roi_combinations( {[-200, 0]}, {[15, 30], [45, 60]} );
band_roi_names = { 'beta', 'gamma' };

glm_combs = freq.pcombs( {'looks_to', 'outcomes'} );

all_combs = {};
stp = 1;
for i = 1:size(glm_combs, 1)
  for h = 1:numel(rois)
    all_combs(stp, :) = [glm_combs(i, :), rois(h), band_roi_names{h}];
    stp = stp + 1;
  end
end

for d = 1:numel(days)

fprintf( '\n Processing %d of %d', d, numel(days) );
  
distributions = Container();
  
fprintf( '\n Loading ... ' );
coh = io.read( p, 'only', days{d}, 'frequencies', [0, 100], 'time', [-200, 0] );
fprintf( 'Done' );

coh = dsp2.process.format.fix_block_number( coh );
coh = dsp2.process.format.fix_administration( coh );

if ( strcmp(meas_type, 'coherence') )
  coh = dsp2.process.format.fix_channels( coh );
  coh = dsp2.process.format.only_pairs( coh );
end

if ( coh.contains('unspecified') )
  [unspc, rest] = coh.pop( 'unspecified' );
  unspc = dsp2.process.format.keep_350( unspc, 350 );
  coh = append( unspc, rest );
end

coh = dsp2.process.manipulations.non_drug_effect( coh );

behav = freq({'choice', 'late', 'error__none'});
measure = coh({'choice'});
measure = measure.rm( 'errors' );

measure = measure.each1d( m_within, @rowops.nanmedian );
measure = measure.each1d( setdiff(m_within, {'blocks', 'sessions'}), @rowops.nanmean );

[I, C] = measure.get_indices( {'days', 'sites', 'channels', 'regions'} );

for idx = 1:size(all_combs, 1)
  fprintf('\n\t %d of %d', idx, size(all_combs, 1) );
  
  glm_c = all_combs(idx, 1:2);
  roi = all_combs{idx, 3};
  band_name = all_combs{idx, 4};

  for i = 1:numel(I)
    subset = measure(I{i});
    behav_subset = behav( [C(i, 1), glm_c] );
    
    subset = subset.time_freq_mean( roi{:} );
    
    match_c = behav_subset.pcombs( match_for );
    
    subset_ = Container();
    behav_subset_ = Container();
    for h = 1:size(match_c, 1)
      items_to_match = match_c(h, :);
      assert( all(subset.contains(items_to_match)), 'Missing mathcing elements.' );
      
      matched_subset = subset(items_to_match);
      matched_behav_subset = behav_subset(items_to_match);
      
      assert( shapes_match(matched_subset, matched_behav_subset) );
      
      matched_subset = matched_subset.require_fields( {'meas_type', 'glm_id'} );
      matched_behav_subset = matched_behav_subset.require_fields( {'meas_type', 'glm_id'} );
      
%       glm_id = map( strjoin(items_to_match, '_') );
      glm_id_str = sprintf( 'glm_id__%d', idx );
      
      missing_from_behav = setdiff( matched_subset.categories(), matched_behav_subset.categories() );
      matched_behav_subset = matched_behav_subset.require_fields( missing_from_behav );
      labs_subset = one( matched_subset );
      for hh = 1:numel(missing_from_behav)
        matched_behav_subset( missing_from_behav{hh} ) = labs_subset( missing_from_behav{hh} );
      end
      missing_from_measure = setdiff( matched_behav_subset.categories(), matched_subset.categories() );
      matched_subset = matched_subset.require_fields( missing_from_measure );
      labs_subset_behav = one( matched_behav_subset );
      for hh = 1:numel(missing_from_measure)
        matched_subset( missing_from_measure{hh} ) = labs_subset_behav( missing_from_measure{hh} );
      end
     
      matched_behav_subset = SignalContainer( matched_behav_subset );
      matched_behav_subset.trial_stats = matched_subset.trial_stats;
      
      matched_behav_subset( 'meas_type' ) = 'looks';
      matched_subset( 'meas_type' ) = meas_type;
      
      combined = append( matched_subset, matched_behav_subset );
      combined( 'glm_id' ) = glm_id_str;
      combined = combined.require_fields( 'band' );
      combined( 'band' ) = band_name;
      
      distributions = append( distributions, combined );
    end
  end
end

save( fullfile(save_p, days{d}), 'distributions' );

end

%%

save_p = fullfile( conf.PATHS.analyses, 'spectral_glm', '120817', meas_type, kind, manip, epoch );

dists = dsp2.util.general.concat( dsp2.util.general.load_mats(save_p) );
[I, C] = dists.get_indices( 'glm_id' );

meas_type = 'coherence';
behav_type = 'looks';

mdls = Container();

for i = 1:numel(I)
  
  behav = dists( I{i} & dists.where(behav_type) );
  meas = dists( I{i} & dists.where(meas_type) );
  id = str2double( C{i, 1}(numel('glm_id__')+1:end) );
  
  assert( shapes_match(behav, meas) );
  
  mags = { 'low', 'medium', 'high' };
  
  factor_magnitude = zeros( shape(behav, 1), 1 );
  factor_looks = behav.data;
  
  for j = 1:numel(mags)
    factor_magnitude( behav.where(mags{j}) ) = j;
  end
  
  assert( ~any(factor_magnitude == 0) );
  
  mdl = fitglm( [factor_magnitude, factor_looks], meas.data, 'interactions' );
  
  meas = one( meas );
  meas = meas.require_fields( 'band' );
  meas( 'band' ) = all_combs{id, end};
  
  mdls = mdls.append( set_data(meas, {mdl}) );
end

%%

betas = cellfun( @(x) {x.Coefficients.Estimate}, mdls.data, 'un', false );
ps = cellfun( @(x) {x.Coefficients.pValue}, mdls.data, 'un', false );

conts = Container();
for i = 1:numel(betas)
  
  beta = betas{i}{1};
  p = ps{i}{1};
  cont = mdls(i);
  cont = cont.add_field( 'term' );
  
  cont = extend( cont, cont, cont, cont );
  cont = set_data( cont, [beta, p] );
  cont = cont.rm_fields( 'meas_type' );
  cont( 'term' ) = { 'intercept', 'reward_size', 'looking_probability', 'interaction' };
  conts = append( conts, cont );
  
end

%%

% sig_perc = conts.for_each( {'term', 'out

sig = conts( conts.data(:, 2) < .05 );
sig = sig.rm( 'intercept' );

plt = set_data( sig, sig.data(:, 1) );

pl = ContainerPlotter();
pl.one_legend = false;
pl.match_y_lim = false;
% pl.order_by = { 'reward_size', 'looking_probability', 'interaction' };
pl.order_by = { 'self', 'both', 'other', 'none' };

figure(1); clf();

pl.bar( plt, 'outcomes', 'band', {'trialtypes', 'looks_to', 'term'} );

%%

do_save = true;

fixed_monk_labs = conts;
bottle_ind = fixed_monk_labs.where( 'bottle' );
fixed_monk_labs( 'looks_to', bottle_ind ) = 'monkey';
fixed_monk_labs( 'looks_to', ~bottle_ind ) = 'bottle';

plt = fixed_monk_labs({'interaction'});
% plt = fixed_monk_labs;
plt = set_data( plt, plt.data(:, 1) );

figure(1); clf();

pl = ContainerPlotter();
pl.one_legend = true;

x_is = 'band';
bars_are = { 'outcomes' };
panels_are = { 'looks_to', 'term' };

axs = pl.bar( plt, x_is, bars_are, panels_are );
h = findobj( gcf, 'type', 'bar' );
set( axs, 'nextplot', 'add' );
y_amt = .5e-4;

for i = 1:numel(h)
  
  obj = h(i).UserData;
  xs = h(i).XData;
  ys = h(i).YData;
  signs = sign( ys );
  offsets = h(i).XOffset;
  
  plt_ax = h(i).Parent;
  
  for j = 1:numel(obj)
    labs = obj{j}.flat_uniques( [x_is, bars_are, panels_are] );
    matching = fixed_monk_labs( labs );
    assert( matching.shape(1) == 1 );
    x = xs(j) + offsets;
    y = ys(j) + y_amt * signs(j);
    if ( matching.data(2) < .05 )
      plot( plt_ax, [x, x], [y, y], 'k*' );
    end
  end
  
end

if ( do_save )
  save_p = fullfile( conf.PATHS.plots, 'mag_cue_glm', dsp2.process.format.get_date_dir(), 'bar' );
  dsp2.util.general.require_dir( save_p );
  fname = fullfile( save_p, 'bar' );
  dsp2.util.general.save_fig( gcf, fname, {'epsc', 'png', 'fig'} );  
end

%%

to_tbl = conts;

monk_ind = to_tbl.where( 'monkey' );
assert( all(~monk_ind == to_tbl.where('bottle')) );
to_tbl( 'looks_to', monk_ind ) = 'bottle';
to_tbl( 'looks_to', ~monk_ind ) = 'monkey';

to_tbl = to_tbl.require_fields( {'p', 'significant'} );
to_tbl( 'p' ) = arrayfun( @(x) ['p__', num2str(x)], to_tbl.data(:, 2), 'un', false );
to_tbl = to_tbl.rm( 'intercept' );
sig_ind = to_tbl.data(:, 2) < .05;
to_tbl( 'significant', sig_ind ) = 'S';
to_tbl( 'significant', ~sig_ind ) = 'NS';
to_tbl = set_data( to_tbl, to_tbl.data(:, 1) );
to_tbl.data( ~sig_ind ) = NaN;

to_tbl.table( {'outcomes', 'band', 'looks_to'}, 'term' )




