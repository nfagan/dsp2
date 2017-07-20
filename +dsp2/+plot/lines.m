function lines(varargin)

%   LINES -- Plot and save line-plots for the given measures, epochs,
%     and manipulations.

defaults.config = dsp2.config.load();
defaults.date = '072017';

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

base_save_path = fullfile( conf.PATHS.plots, params.date, 'lines_median2' );

formats = { 'png', 'epsc' };

% rois = Container( {[0, 300]; [-150, 150]}, 'epochs', {'reward'; 'targacq'} );
roi1 = Container( {[8, 15]; [15, 30]; [25, 50]; [50, 70]}, 'epochs', 'targacq' );
roi2 = Container( {[8, 15]; [15, 30]; [25, 50]; [50, 70]}, 'epochs', 'reward' );
rois = roi1.append( roi2 );

pl = ContainerPlotter();

plotby = 'time';

%   loop over the combinations of each of these
measures = { 'coherence' };
epochs = { 'reward' };
% manipulations = { ...
%     'pro_v_anti', 'pro_minus_anti', 'pro_v_anti_drug' ...
%   , 'pro_minus_anti_drug', 'pro_v_anti_drug_minus_sal' ...
%   , 'pro_minus_anti_drug_minus_sal' ...
% };
manipulations = { 'pro_v_anti' };
to_collapse = { {'trials', 'monkeys'} };

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
  
  measure = dsp2.io.get_processed_measure( C(i, :), 'meaned' ...
    , 'config', conf ...
    , 'load_required', require_load ...
  );
  
  measure = measure.keep_within_freqs( [0, 100] );
  
  figs_for_each = { 'drugs', 'trialtypes', 'monkeys' };
  [~, c] = measure.get_indices( figs_for_each );
  roi = rois.only( epoch );
  
  for k = 1:size(c, 1)
    for kk = 1:shape( roi, 1 )
      clf( F );
      
      roi_ = roi.data(kk);

      pl.default();
      pl.save_outer_folder = base_save_path;
      pl.add_ribbon = true;
      pl.summary_function = conf.PLOT.summary_function;
      pl.error_function = conf.PLOT.error_function;

      measure_ = measure.only( c(k, :) );

      if ( isequal(plotby, 'frequency') )
        measure_ = measure_.time_mean( roi_{:} );
        pl.x = measure_.frequencies;
        pl.x_label = 'Hz';
        f_str = sprintf( '%0.1f_to_%0.1f_ms', roi_{1}(1), roi_{1}(2) );
      else
        switch ( epoch )
          case 'targacq'
            measure_ = measure_.keep_within_times( [-300, 350] );
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
        full_save_path = fullfile( base_save_path, meas_type, epoch, manip, fmt );

        dsp2.util.general.require_dir( full_save_path );

        full_fname = fullfile( full_save_path, [fname, '.', formats{j}] );
        saveas( gcf, full_fname, formats{j} );
      end
    end
  end 
  
end

end