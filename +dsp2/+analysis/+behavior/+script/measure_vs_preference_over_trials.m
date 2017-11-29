import dsp2.analysis.behavior.measure_vs_preference_simple; 

conf = dsp2.config.load();

io = dsp2.io.get_dsp_h5();

P = dsp2.io.get_path( 'measures', 'coherence', 'complete' );

epochs = { 'targacq', 'reward' };
epoch_rois = { [-250, 0], [50, 250] };

band_rois  = { [15, 25], [30, 45] };
band_names = { 'beta', 'gamma' };
pref_within = { 'sites', 'channels', 'regions', 'administration', 'contexts' };

prealc_cols = 1e3;
prealc_rows = 10e3;
prealc_mat = nan( prealc_rows, prealc_cols );
row_stp = 1;

admins = { 'pre', 'post' };
prealc_mats = cellfun( @(x) prealc_mat, admins, 'un', false );
row_stps = cellfun( @(x) 1, admins, 'un', false );
labs = cellfun( @(x) SparseLabels(), admins, 'un', false );

Results = Container();

is_within_context = true;
trial_bins = 20;

for i = 1:numel(epochs)
  fprintf( '\n Processing (%s) %d of %d', epochs{i}, i, numel(epochs) );
  full_p = io.fullfile( P, epochs{i} );
  days = io.get_days( full_p );
  days = setdiff( days, {'day__05172016', 'day__05192016', 'day__02142017', 'day__06022017'} );
  
  for j = 1:numel(days)
    fprintf( '\n\t Processing (%s) %d of %d', days{j}, j, numel(days) );
    coh = io.read( full_p, 'only', days{j}, 'time', epoch_rois{i} );
    coh = coh.time_mean( epoch_rois{i} );
    coh = dsp2.process.format.fix_block_number( coh );
    coh = dsp2.process.format.fix_administration( coh );
    coh = dsp2.process.format.add_trial_ids( coh );
    coh.labels = dsp2.process.format.fix_channels( coh.labels );
    coh = dsp2.process.format.only_pairs( coh );
    
    coh = coh.require_fields( 'contexts' );
    if ( is_within_context )
      coh( 'contexts', coh.where({'self', 'both'}) ) = 'selfBoth';
      coh( 'contexts', coh.where({'other', 'none'}) ) = 'otherNone';
    else
      coh = coh.collapse( 'contexts' );
      coh = coh.replace( {'self', 'none'}, 'antisocial' );
      coh = coh.replace( {'both', 'other'}, 'prosocial' );
    end
    
    for h = 1:numel(band_rois)
      meaned = coh.freq_mean( band_rois{h} );
      meaned.data = squeeze( meaned.data );
      band_name = band_names{h};
      
      meaned = meaned.only( {'choice'} );
      meaned = meaned.rm( 'errors' );
      
      C = meaned.pcombs( pref_within );
      
      for k = 1:size(C, 1)
        ctx_ind = strcmp( pref_within, 'contexts' );
        assert( any(ctx_ind), 'No contexts category specified.' );
        
        outs = meaned.uniques_where( 'outcomes', C{k, ctx_ind} );
        assert( numel(outs) == 2, 'Expected 2 outcomes; got %d', numel(outs) );
        
        if ( strcmp(C{k, ctx_ind}, 'otherNone') )
          outs{1} = 'other';
          outs{2} = 'none';
        elseif ( strcmp(C{k, ctx_ind}, 'selfBoth') )
          outs{1} = 'self';
          outs{2} = 'both';
        else
          assert( strcmp(C{k, ctx_ind}, 'all__contexts'), 'Unrecognized context specifer' );
          outs{1} = 'prosocial';
          outs{2} = 'antisocial';
        end
        
        pref_vs_measure = measure_vs_preference_simple( ...
          meaned.only( C(k, :) ), trial_bins, outs{1}, outs{2} );
        
        admin_ind = strcmp( pref_within, 'administration' );
        assert( any(admin_ind) );
        current_admin = C{k, admin_ind};
        
        pref = pref_vs_measure.only( 'preference_index' );
        meas = pref_vs_measure.only( 'signal_measure' );
                
        ind = strcmp( admins, current_admin );
        assert( any(ind), 'No matching administration labels.' );

        pref_x = pref;
        meas_x = meas;

        n_x = shape( pref_x, 1 );

        assert( n_x <= prealc_cols, 'More sample points than preallocated.' );

        if ( strcmp(current_admin, 'pre') )
          prealc_mats{ind}(row_stps{ind}, end-n_x+1:end) = pref_x.data(:)';
          prealc_mats{ind}(row_stps{ind}+1, end-n_x+1:end) = meas_x.data(:)';
        else
          prealc_mats{ind}(row_stps{ind}, 1:n_x) = pref_x.data(:)';
          prealc_mats{ind}(row_stps{ind}+1, 1:n_x) = meas_x.data(:)';
        end

        pref_x_ = pref_x.one();
        pref_x_ = pref_x_.require_fields( 'band' );
        pref_x_( 'band' ) = band_name;
        labs_a = pref_x_.labels.set_field( 'measure', 'preference_index' );
        labs_b = pref_x_.labels.set_field( 'measure', 'signal_measure' );
        labs{ind} = labs{ind}.append( labs_a );
        labs{ind} = labs{ind}.append( labs_b );

        row_stps{ind} = row_stps{ind} + 2;
      end
    end
  end
end

% get rid of excess rows
conts = cell( size(prealc_mats) );
for i = 1:numel(prealc_mats)
  prealc_mats{i}(row_stps{i}:end, :) = [];
  conts{i} = Container( prealc_mats{i}, labs{i} );
end

results = Container.concat( conts );

save_p = fullfile( conf.PATHS.analyses, 'behavior', 'coherence_preference_over_trials' );
save_p = fullfile( save_p, dsp2.process.format.get_date_dir() );
dsp2.util.general.require_dir( save_p );
if ( is_within_context )
  base_fname = 'per_context_results';
else
  base_fname = 'all_contexts_results';
end

fname = sprintf( '%s_%d_trials.mat', base_fname, trial_bins );
save( fullfile(save_p, fname), 'results' );

%%

post = results.only( 'post' );
pre = results.only( 'pre' );

combined = pre;
combined.data = [ pre.data, post.data ];

combined( 'administration' ) = 'prePost';

func = @dsp2.analysis.behavior.measure_vs_preference_lm;
mdls = combined.for_each( {'epochs', 'drugs', 'band', 'contexts', 'measure'}, func );

%%
sig = cellfun( @(x) x.Coefficients{2, 'pValue'} < .05, mdls.data );
sig_mdls = mdls( sig );

% mdl = dsp2.analysis.behavior.measure_vs_preference_lm( combined );


%%

post = results.only( 'post' );
pre = results.only( 'pre' );

combined = pre;
combined.data = [ pre.data, post.data ];

combined( 'administration' ) = 'prePost';

plt = combined.only( {'targAcq', 'saline'} );

figure(1); clf();
pl = ContainerPlotter();
pl.error_function = @nanstd;
pl.summary_function = @nanmean;
pl.x = 1:shape(combined, 2);
pl.vertical_lines_at = 1e3;
pl.add_ribbon = true;

plt.plot( pl, 'measure', {'contexts', 'epochs', 'band', 'drugs'} );

%%

% plt = combined.only( {'targAcq', 'saline'} );
plt = combined.rm( 'unspecified' );
plt_for_each = { 'contexts', 'epochs', 'band', 'drugs' };

C = plt.pcombs( plt_for_each );

for i = 1:size(C, 1)
   
  pref = plt.only( [C(i, :), 'preference_index'] );
  meas = plt.only( [C(i, :), 'signal_measure'] );
  
  matching_model_pref = mdls.only( [C(i, :), 'preference_index'] );
  matching_model_meas = mdls.only( [C(i, :), 'signal_measure'] );
  assert( ~isempty(matching_model_pref) && ~isempty(matching_model_meas) );
  assert( shapes_match(matching_model_pref, matching_model_meas) );
  assert( shape(matching_model_pref, 1) == 1 );
  
  mdl_pref = matching_model_pref.data{1};
  mdl_meas = matching_model_meas.data{1};
  
  mdl_pref_func = @(x) mdl_pref.Coefficients{1, 'Estimate'} + mdl_pref.Coefficients{2, 'Estimate'} * x;
  mdl_meas_func = @(x) mdl_meas.Coefficients{1, 'Estimate'} + mdl_meas.Coefficients{2, 'Estimate'} * x;
  
  all_nan_pref = ~isnan( pref.data );
  all_nan_meas = ~isnan( meas.data );
  all_nan_pref = all( all_nan_pref, 1 );
  all_nan_meas = all( all_nan_meas, 1 );
  
  min_pref = find( ~all_nan_pref, 1, 'first' );  
  min_meas = find( ~all_nan_meas, 1, 'first' );
  max_pref = find( ~all_nan_pref, 1, 'last' );
  max_meas = find( ~all_nan_meas, 1, 'last' );
  
  mins = min( min_pref, min_meas );
  maxs = max( max_pref, max_meas );

  pref_means = nanmean( pref.data, 1 );
  meas_means = nanmean( meas.data, 1 );
  
  ci_lo_pref = pref_means - nanstd( pref.data, [], 1 );
  ci_hi_pref = pref_means + nanstd( pref.data, [], 1 );
  
  ci_lo_meas = meas_means - nanstd( meas.data, [], 1 );
  ci_hi_meas = meas_means + nanstd( meas.data, [], 1 );
  
  x = 1:size(ci_lo_meas, 2);
  
  figure(1); clf(); hold off;
  axs = plotyy( x, pref_means, x, meas_means );
%   axs2 = plotyy( x, ci_lo_pref, x, ci_lo_meas );
%   axs3 = plotyy( x, ci_hi_pref, x, ci_hi_meas ); 

  hold( axs(1), 'on' );
  hold( axs(2), 'on' );
  plot( axs(1), x, mdl_pref_func(x), 'b' );
  plot( axs(2), x, mdl_meas_func(x), 'r' );
  if ( trial_bins == 50 )
    set( axs(1), 'YLim', [-.5, .5] );
    set( axs(2), 'YLim', [-0.02, 0.02] );
    set( axs(1), 'XLim', [995, 1008] );
    set( axs(2), 'XLim', [995, 1008] );
    set(axs(1), 'YTick',[-.5:.05:.5]);
    set(axs(2), 'YTick',[-.02:.01:.02]);
  elseif ( trial_bins == 10 )
    y_lims_pref = [ -.6, .6 ];
    y_lims_meas = [ -.07, .07 ];
    set( axs(1), 'YLim', y_lims_pref );
    set( axs(2), 'YLim', y_lims_meas );
    set( axs(1), 'XLim', [960, 1060] );
    set( axs(2), 'XLim', [960, 1060] );
    set(axs(1),'YTick',[y_lims_pref(1):.1:y_lims_pref(2)]);
    set(axs(2),'YTick',[y_lims_meas(1):.01:y_lims_meas(2)]);
  else
    y_lims_pref = [ -.5, .5 ];
    y_lims_meas = [-.06, .06];
    set( axs(1), 'YLim', y_lims_pref );
    set( axs(2), 'YLim', y_lims_meas );
    set( axs(1), 'XLim', [990, 1017] );
    set( axs(2), 'XLim', [990, 1017] );
    set(axs(1), 'YTick',[y_lims_pref(1):.05:y_lims_pref(2)]);
    set(axs(2), 'YTick',[y_lims_meas(1):.01:y_lims_meas(2)]);
  end
  set( axs(1),'Box','off ');
  set( axs(2),'Box','off ');
  ylabel( axs(1), 'Preference index' );
  ylabel( axs(2), 'Coherence' );
  
  if ( mdl_pref.Coefficients{2, 'pValue'} < .05 )
    x_coord = min( get(axs(1), 'xlim') );
    y_coord = max( get(axs(1), 'ylim') );
    plot( x_coord, y_coord, 'b*' );
  end
  if ( mdl_meas.Coefficients{2, 'pValue'} < .05 )
    x_coord = max( get(axs(1), 'xlim') );
    y_coord = max( get(axs(1), 'ylim') );
    plot( x_coord, y_coord, 'r*' );
  end
  
  plot( axs(1), [1e3, 1e3], [-1, 1], 'k' );
  
  title( axs(2), strjoin(pref.flat_uniques(plt_for_each), ' | ') );
  
  save_path = fullfile( conf.PATHS.plots, 'behavior' ...
    , 'measure_vs_preference_over_trials' ...
    , dsp2.process.format.get_date_dir() );
  
  if ( is_within_context )
    subdir = sprintf( 'per_context_results_%d', trial_bins );
  else
    subdir = sprintf( 'all_contexts_results_%d', trial_bins );
  end
  
  save_path = fullfile( save_path, subdir );
  
  fname = dsp2.util.general.append_uniques( pref, 'meas_v_pref', plt_for_each );
  
  dsp2.util.general.require_dir( save_path );
  dsp2.util.general.save_fig( gcf(), fullfile(save_path, fname), {'epsc', 'png', 'fig'} );
  
end





%         figure(1); clf();
%         x = 1:shape( pref, 1 );
%         axs = plotyy( x, full(pref.data)', x, full(meas.data)' );
%         hold on;
% 
%         lims = get( gca, 'ylim' );
%         plot( [shape(pref_pre, 1); shape(pref_pre, 1)], lims, 'k' );
% 
%         ylabel( axs(1), 'preferenceIndex' );
%         ylabel( axs(2), 'coherence' );