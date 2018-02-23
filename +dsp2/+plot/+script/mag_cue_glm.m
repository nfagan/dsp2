%%

meas_type = 'coherence';
behav_type = 'looks';

% date_dir = '120817';
date_dir = '121417';
epoch = 'targon';
kind = 'complete';
manip = 'standard';

load_p = fullfile( conf.PATHS.analyses, 'spectral_glm', date_dir, meas_type, kind, manip, epoch );

dists = dsp2.util.general.concat( dsp2.util.general.load_mats(load_p) );
all_combs = dsp2.util.general.fload( fullfile(load_p, 'all_combs', 'all_combs.mat') );

[I, C] = dists.get_indices( 'glm_id' );

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
  save_p = fullfile( save_p, epoch );
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
