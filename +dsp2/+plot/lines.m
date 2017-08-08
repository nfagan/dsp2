function lines(varargin)

%   LINES -- Plot and save line-plots for the given measures, epochs,
%     and manipulations.

defaults.config = dsp2.config.load();
defaults.date = '072117';
defaults.kind = 'meaned';
defaults.measures = { 'normalized_power', 'coherence' };
defaults.epochs = { 'reward', 'targacq' };
defaults.manipulations = { 'pro_v_anti' };
defaults.to_collapse = { {'trials', 'monkeys'} };
defaults.formats = { 'png', 'epsc', 'fig' };
defaults.plotby = 'frequency';
defaults.compare_series = false;
defaults.p_correct_type = 'fdr';
defaults.match_limits_across_files = true;
defaults.rois = Container( {[8, 15]; [15, 30]; [30, 50]; [50, 70]}, 'epochs', 'targacq' );

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

base_save_path = fullfile( conf.PATHS.plots, params.date, 'lines' );
formats = params.formats;
compare_series = params.compare_series;

rois = params.rois;

pl = ContainerPlotter();
plotby = params.plotby;
match_lim = params.match_limits_across_files;

summary_func = conf.PLOT.summary_function;
sfunc_name = func2str( summary_func );

%   loop over the combinations of each of these
measures = params.measures;
epochs = params.epochs;
manipulations = params.manipulations;
to_collapse = params.to_collapse;

kind = params.kind;

C = dsp2.util.general.allcomb( {measures, epochs, manipulations, to_collapse} );

F = figure(1);

for i = 1:size(C, 1)
  
  meas_type = C{i, 1};
  epoch = C{i, 2};
  manip = C{i, 3};
  
  if ( i == 1 )
    require_load = true;
  else
    require_load = false;
  end
  
  measure = dsp2.io.get_processed_measure( C(i, :), kind ...
    , 'config', conf ...
    , 'load_required', require_load ...
  );
  
  measure = measure.keep_within_freqs( [0, 100] );
  
  figs_for_each = { 'drugs', 'trialtypes', 'monkeys' };
  [~, c] = measure.get_indices( figs_for_each );
  roi = rois.only( epoch );
  
  fig_filenames = {};
  
  for k = 1:size(c, 1)
    for kk = 1:shape( roi, 1 )
      clf( F );
      
      roi_ = roi.data(kk);

      pl.default();
      pl.save_outer_folder = base_save_path;
      pl.add_ribbon = true;
      pl.summary_function = summary_func;
      pl.error_function = conf.PLOT.error_function;
      pl.compare_series = compare_series;
      pl.p_correct_type = params.p_correct_type;

      measure_ = measure.only( c(k, :) );

      if ( isequal(plotby, 'frequency') )
        measure_ = measure_.keep_within_freqs( [0, 100] );
        measure_ = measure_.time_mean( roi_{:} );
        pl.x = measure_.frequencies;
        pl.x_label = 'Hz';
        f_str = sprintf( '%0.1f_to_%0.1f_ms', roi_{1}(1), roi_{1}(2) );
      else
        switch ( epoch )
          case {'targacq', 'targon'}
            measure_ = measure_.keep_within_times( [-350, 300] );
          case 'reward'
            measure_ = measure_.keep_within_times( [-500, 500] );
        end
        measure_ = measure_.freq_mean( roi_{:} );
        pl.x = measure_.get_time_series();
        pl.x_label = sprintf( 'Time (ms) from %s', epoch );
        f_str = sprintf( '%d_to_%d_hz', roi_{1}(1), roi_{1}(2) );
      end

      measure_.data = squeeze( measure_.data );

      pl.y_label = strrep( meas_type, '_', ' ' );

      pl.plot( measure_, 'outcomes', {'monkeys', 'regions', 'trialtypes'} );

      labs = measure_.labels.flat_uniques( {'monkeys', 'drugs', 'trialtypes'} );    
      fname = strjoin( labs, '_' );
      fname = sprintf( '%s_%s', fname, f_str );

      for j = 1:numel(formats)
        fmt = formats{j};
        full_save_path = fullfile( base_save_path, sfunc_name, meas_type ...
          , kind, epoch, manip, fmt );

        dsp2.util.general.require_dir( full_save_path );

        full_fname = fullfile( full_save_path, [fname, '.', formats{j}] );
        saveas( gcf, full_fname, formats{j} );
        
        if ( strcmp(formats{j}, 'fig') )
          fig_filenames{end+1} = full_fname;
        end
      end
    end
  end
  
  if ( match_lim && ~isempty(fig_filenames) )
    editor = FigureEdits( fig_filenames );
    lims = editor.ylim();
    mins = Inf;
    maxs = -Inf;
    for k = 1:numel(lims)
      lim = lims{k};
      if ( iscell(lim) )
        lim = cell2mat( lims{k} );
        lim = min( lim, [], 1 );
      end
      mins = min( mins, lim(1) );
      maxs = max( maxs, lim(2) );
    end
    editor.ylim( [mins, maxs] );
    editor.save();
    editor.reset();
  end
end

end