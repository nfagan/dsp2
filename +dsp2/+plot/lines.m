function lines(varargin)

%   LINES -- Plot and save line-plots for the given measures, epochs,
%     and manipulations.

defaults.config = dsp2.config.load();
defaults.date = '062217';

params = dsp2.util.general.parsestruct( defaults, varargin );

conf = params.config;

base_save_path = fullfile( conf.PATHS.plots, params.date, 'lines' );

formats = { 'png', 'epsc' };

rois = Container( {[0, 300]; [-150, 150]}, 'epochs', {'reward'; 'targacq'} );

pl = ContainerPlotter();

plotby = 'frequency';

%   loop over the combinations of each of these
measures = { 'normalized_power', 'coherence' };
epochs = { 'reward', 'targacq' };
% manipulations = { ...
%     'pro_v_anti', 'pro_minus_anti', 'pro_v_anti_drug' ...
%   , 'pro_minus_anti_drug', 'pro_v_anti_drug_minus_sal' ...
%   , 'pro_minus_anti_drug_minus_sal' ...
% };
manipulations = { 'standard', 'pro_v_anti' };
to_collapse = { {'sites', 'trials'}, {'sites', 'trials', 'monkeys'} };

C = dsp2.util.general.allcomb( {measures, epochs, manipulations, to_collapse} );

F = figure(1);

for i = 1:size(C, 1)
  
  meas_type = C{i, 1};
  epoch = C{i, 2};
  manip = C{i, 3};
  
  measure = dsp2.io.get_processed_measure( C(i, :), 'meaned' );
  
  measure = measure.keep_within_freqs( [0, 100] );
  
  figs_for_each = { 'drugs', 'trialtypes' };
  [~, c] = measure.get_indices( figs_for_each );
  roi = rois.only( epoch );
  
  for k = 1:size(c, 1)
    
    clf( F );
    
    pl.default();
    pl.save_outer_folder = base_save_path;
    pl.add_ribbon = true;
    
    measure_ = measure.only( c(k, :) );
    
    if ( isequal(plotby, 'frequency') )
      measure_ = measure_.time_mean( roi.data{:} );
      pl.x = measure_.frequencies;
      pl.x_label = 'Hz';
    else
      measure_ = measure_.freq_mean( roi.data{:} );
      pl.x = measure_.get_time_series();      
    end
    
    pl.y_label = strrep( meas_type, '_', ' ' );
    
    pl.plot( measure_, 'outcomes', {'monkeys', 'regions', 'trialtypes'} );

    labs = measure_.labels.flat_uniques( {'monkeys', 'drugs', 'trialtypes'} );    
    fname = strjoin( labs, '_' );
    
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