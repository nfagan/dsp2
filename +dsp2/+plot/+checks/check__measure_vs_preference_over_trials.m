conf = dsp2.config.load();
date_dir = '110217';
base_p = fullfile( conf.PATHS.analyses, 'behavior', 'coherence_preference_over_trials', date_dir );

is_within_context = true;
trial_bins = 10;

if ( is_within_context )
  base_fname = 'per_context_results_';
else
  base_fname = 'all_contexts_results_';
end
\
save_date_dir = dsp2.process.format.get_date_dir();
save_p = fullfile( conf.PATHS.plots, 'behavior', 'coherence_preference_over_trials', save_date_dir );

fname = sprintf( '%s%d_trials.mat', base_fname, trial_bins );

results = dsp2.util.general.fload( fullfile(base_p, fname) );

%%  gamma / beta ratio over time

pref = results.only( 'preference_index' ); 
pref = pref.rm( 'unspecified' );
pref = pref.only( 'beta' );
pref_pre = pref.only( 'pre' ); pref_post = pref.only( 'post' ); 
pref_combined = pref_pre; pref_combined.data = [ pref_pre.data, pref_post.data ];
pref_combined( 'administration' ) = 'pre_post';

coh = results.only( 'signal_measure' );
coh = coh.rm( 'unspecified' );

pre = coh.only( 'pre' );
post = coh.only( 'post' );

assert( shapes_match(pre, post) );

combined = pre;
combined.data = [ pre.data, post.data ];
combined( 'administration' ) = 'pre_post';

all_nans_pre = all( isnan(pre.data) );
all_nans_post = all( isnan(post.data) );

last_all_pre = find( all_nans_pre, 1, 'last' );
first_all_post = find( all_nans_post, 1, 'first' );
offset = size( pre.data, 2 );

combined.data = combined.data( :, last_all_pre+1:first_all_post+offset-1 );
pref_combined.data = pref_combined.data(:, last_all_pre+1:first_all_post+offset-1 );

pre_ind = 1e3 - last_all_pre;

beta = combined.only( 'beta' );
gamma = combined.only( 'gamma' );

ratio = gamma ./ beta;

assert( ~any(isinf(ratio.data(:))) );

%%  optional -- std threshold

check_within = { 'band', 'drugs', 'contexts', 'epochs' };
thresholded = ratio;
thresholded_pref = pref_combined;
n_devs = 1.5;
[I, C] = thresholded.get_indices( check_within );
all_good_samples = false( thresholded.shape() );
for i = 1:numel(I)
  distr = thresholded.data(I{i}, :);
  good_samples = true( size(distr, 1), 1 );
  for j = 1:size(distr, 2)
    subset = distr(:, j);
    
    mean_subset = nanmean( subset, 1 );
    dev_subset = nanstd( subset, [], 1 );
    
    if ( isnan(mean_subset) || isnan(dev_subset) )
      continue; 
    end
    
    ci_lo = mean_subset - (dev_subset * n_devs);
    ci_hi = mean_subset + (dev_subset * n_devs);
    
    within = subset >= ci_lo & subset <= ci_hi;
    
%     good_samples = good_samples & within;
    
    all_good_samples( I{i}, j ) = within;
  end
  
end

thresholded.data( ~all_good_samples ) = NaN;
thresholded_pref.data( ~all_good_samples ) = NaN;
thresh_beta = beta; thresh_beta.data( ~all_good_samples ) = NaN;
thresh_gamma = gamma; thresh_gamma.data( ~all_good_samples ) = NaN;
thresh_combined = append( beta, gamma );
thresh_pref_combined = thresholded_pref;
thresh_pref_combined( 'band' ) = 'gamma';
thresholded_pref( 'band' ) = 'beta';
thresh_pref_combined = append( thresh_pref_combined, thresholded_pref );

%%  line over time vs. pref

is_ratio = false;
y_lim_pref = [ -0.75, 0.75 ];
y_tick_pref_stp = 0.1;
y_lab_coh = 'Coherence';

if ( is_ratio )
  y_tick_coh_stp = 1;
  y_lim_coh = [ -10, 10 ];
  thresholded_pref( 'band' ) = thresholded('band');
  all_thresholded = append( thresholded, thresholded_pref );
else
  y_lim_coh = [ -0.07, 0.07 ];
  y_tick_coh_stp = 0.01;
  all_thresholded = append( thresh_combined, thresh_pref_combined );
end

mdls_within = { 'contexts', 'band', 'epochs', 'drugs' };
[I, C] = all_thresholded.get_indices( mdls_within );

do_save = true;

for i = 1:numel(I)
  subset = all_thresholded(I{i});
  subset_pref = subset.only( 'preference_index' );
  subset_coh = subset.only( 'signal_measure' );
  
  last_nan_pref = find( all(isnan(subset_pref.data), 1), 1, 'last' );
  last_nan_meas = find( all(isnan(subset_coh.data), 1), 1, 'last' );
  
  if ( isempty(last_nan_pref) && ~isempty(last_nan_meas) )
    min_nan = last_nan_meas;
  elseif ( ~isempty(last_nan_pref) && isempty(last_nan_meas) )
    min_nan = last_nan_pref;
  else
    min_nan = min( last_nan_pref, last_nan_meas );
  end
  
  if ( ~isempty(min_nan) )
    subset_pref.data(:, min_nan:end) = NaN;
    subset_coh.data(:, min_nan:end) = NaN;
  end
  
  x = 1:size(subset_pref.data, 2);
  
  mdl = dsp2.analysis.behavior.measure_vs_preference_lm( subset_pref );
  mdl = mdl(1).data{1};
  m = mdl.Coefficients{2, 'Estimate'};
  p = mdl.Coefficients{1, 'Estimate'};
  func_pref = @(x) x.*m + p;
  pref_is_sig = mdl.Coefficients{2, 'pValue'} < .05;
  
  mdl = dsp2.analysis.behavior.measure_vs_preference_lm( subset_coh );
  mdl = mdl(1).data{1};
  m_coh = mdl.Coefficients{2, 'Estimate'};
  p_coh = mdl.Coefficients{1, 'Estimate'};
  func_coh = @(x) x.*m_coh + p_coh;
  coh_is_sig = mdl.Coefficients{2, 'pValue'} < .05;
  
  figure(1); clf();
  box off;
  [axs, h1, h2] = plotyy(x, nanmean(subset_pref.data, 1), x, nanmean(subset_coh.data, 1) );
  set( axs, 'NextPlot', 'add' );
  plot( axs(1), x, func_pref(x), 'b' );
  plot( axs(2), x, func_coh(x), 'r' );
  
  set( axs(1), 'xlim', [x(1)-1, x(end)+1] );
  set( axs(2), 'xlim', [x(1)-1, x(end)+1] );
  set( axs(1), 'ylim', y_lim_pref );
  set( axs(2), 'ylim', y_lim_coh );
  set( axs(1), 'ytick', [y_lim_pref(1):y_tick_pref_stp:y_lim_pref(2)] );
  set( axs(2), 'ytick', [y_lim_coh(1):y_tick_coh_stp:y_lim_coh(2)] );
  ylabel( axs(1), 'Preference index' );
  ylabel( axs(2), y_lab_coh );
  
  
  title_str = strrep( strjoin(flat_uniques(subset_coh, mdls_within), ' | '), '_', ' ' );
  title( title_str );

  plot( axs(1), [pre_ind, pre_ind], get(axs(1), 'ylim'), 'k' );   
  
  if ( coh_is_sig )
    ylims_coh = get( axs(2), 'ylim' );
    plot( axs(2), x(end-1), ylims_coh(2), 'r*' );
  end
  if ( pref_is_sig )
    ylims_pref = get( axs(1), 'ylim' );
    plot( axs(1), x(2), ylims_pref(2), 'b*' );
  end
  
  if ( do_save )
    if ( is_ratio )
      full_fname = sprintf( '%s_%s', fname, 'thresholded_ratio_over_time' );
      full_save_p = fullfile( save_p, 'drug', 'thresholded_ratio_over_time_vs_preference' );
      dsp2.util.general.require_dir( full_save_p );
    else
      full_fname = sprintf( '%s_%s', fname, 'thresholded_measure_over_time' );
      full_save_p = fullfile( save_p, 'drug', 'thresholded_measure_over_time_vs_preference' );
    	dsp2.util.general.require_dir( full_save_p );
    end
    full_fname = dsp2.util.general.append_uniques( subset_coh, full_fname, mdls_within );
    dsp2.util.general.save_fig( gcf, fullfile(full_save_p, full_fname), { 'epsc', 'fig', 'png'} );
  end
end

%%  plot -- gamma / beta ratio over trials

DO_SAVE = true;

% plt = ratio;
plt = thresholded;

figure(1); clf();

pl = ContainerPlotter();
pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;
pl.add_ribbon = true;
pl.vertical_lines_at = pre_ind;
pl.y_label = 'Ratio Gamma / Beta';

plt.plot( pl, 'drugs', {'contexts', 'epochs'} );

f = FigureEdits( gcf );
f.xlim( [0, 55] );

if ( DO_SAVE )
  dsp2.util.general.require_dir( save_p );
  full_fname = sprintf( '%s_%s', fname, 'thresholded_ratio_over_time' );
  dsp2.util.general.save_fig( gcf, fullfile(save_p, full_fname), { 'epsc', 'fig', 'png'} );
end

%%  plot -- gamma / beta ratio binned

DO_SAVE = true;
plt = ratio;

pre = plt;
pre.data = pre.data(:, 1:pre_ind);
post = plt;
post.data = post.data(:, pre_ind+1:end);
half_point = floor( size(post.data, 2) / 2 );
late_post = post;
post.data = post.data(:, 1:half_point);
late_post.data = late_post.data(:, half_point+1:end);

pre( 'administration' ) = 'pre';
late_post( 'administration' ) = 'late_post';
post( 'administration' ) = 'early_post';

pre = pre.nanmean(2);
late_post = late_post.nanmean(2);
post = post.nanmean(2);

combined_ratio = extend( pre, late_post, post );

pl = ContainerPlotter();
pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;
pl.order_by = { 'pre', 'early_post', 'late_post' };
pl.y_lim = [ -10 10 ];

figure(1); clf(); colormap( 'default' );

combined_ratio.bar( pl, 'administration', 'drugs', {'band', 'contexts', 'epochs'} );

if ( DO_SAVE )
  dsp2.util.general.require_dir( save_p );
  full_fname = sprintf( '%s_%s', fname, 'coherence_ratio_split_into_thirds' );
  dsp2.util.general.save_fig( gcf, fullfile(save_p, full_fname), { 'epsc', 'fig', 'png'} );
end


%%  regression -- gamma / beta ratio over trials

func_pref = @dsp2.analysis.behavior.measure_vs_preference_lm;
mdl_within = { 'epochs', 'drugs', 'band', 'contexts' };
mdls = thresholded.for_each( mdl_within, func_pref );

ps = mdls.each1d( mdl_within, @(x) x{1}.Coefficients{2, 'pValue'} );
beta = mdls.each1d( mdl_within, @(x) x{1}.Coefficients{2, 'Estimate'} );
intercept = mdls.each1d( mdl_within, @(x) x{1}.Coefficients{1, 'Estimate'} );

is_sig = ps.data <= .05;
sig_mdls = mdls( is_sig );

if ( ~isempty(sig_mdls) )
  disp( sig_mdls );
end

%%  split into groups of 3

pre = results.only( 'pre' );
post = results.only( 'post' );

% pre = ratio.only( 'pre' );
% post = ratio.only( 'post' );

all_nans_pre = all( isnan(pre.data) );
all_nans_post = all( isnan(post.data) );

last_all_pre = find( all_nans_pre, 1, 'last' );
first_all_post = find( all_nans_post, 1, 'first' );

pre.data = pre.data(:, last_all_pre+1:end);
post.data = post.data(:, 1:first_all_post-1);

sz = size( post.data, 2 );
half_point = floor( sz/2 );

post_early = post;
post_early( 'administration' ) = 'early_post';
post( 'administration' ) = 'late_post';

post_early.data = post_early.data(:, 1:half_point);
post.data = post.data(:, half_point+1:end);

pre = pre.nanmean(2);
post_early = post_early.nanmean(2);
post = post.nanmean(2);

combined = extend( pre, post_early, post );

%%  plot bar split into 3

DO_SAVE = true;
is_pref = false;

figure(1); clf();
pl = ContainerPlotter();
pl.order_by = { 'pre', 'early_post', 'late_post' };
pl.summary_function = @nanmean;
pl.error_function = @ContainerPlotter.nansem;

plt = combined;
if ( is_pref )
  plt = plt.only( 'preference_index' );
  kind = 'preference_index';
else
  plt = plt.only( 'signal_measure' );
  kind = 'coherence_ratio';
end
plt = plt.rm( 'unspecified' );

if ( is_pref )
  plt = plt.for_each( 'days', @(x) only(x, x('channels',1)) );
  plt = plt.for_each( 'days', @(x) only(x, x('band', 1)) );
end

pl.y_label = kind;
pl.shape = [4, 2];
pl.y_lim = [  ];

plt.bar( pl, 'administration', 'drugs', {'outcomes', 'band', 'epochs'} );

f = FigureEdits( gcf() );
f.one_legend();
set( gcf(), 'units', 'normalized' );
set( gcf(), 'position', [0, 0, 1, 1] );

if ( DO_SAVE )
  dsp2.util.general.require_dir( save_p );
  full_fname = sprintf( 'early_vs_late_%s_%s', fname, kind );
  dsp2.util.general.save_fig( gcf, fullfile(save_p, full_fname), { 'epsc', 'fig', 'png'} );
end






