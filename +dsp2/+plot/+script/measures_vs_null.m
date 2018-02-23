conf = dsp2.config.load();

% load_date = '121917'; % coherence;
load_date = '122017'; % norm power

base_load_p = fullfile( conf.PATHS.analyses, 'z_scored_spectra', load_date );
base_save_p = fullfile( conf.PATHS.plots, 'lines_vs_null', dsp2.process.format.get_date_dir() );

epochs = { 'reward', 'targacq' };
meas_types = { 'normalized_power' };
manips = { 'pro_minus_anti' };
clpses = { {'trials', 'monkeys'} };
smoothings = { false, true };

kind = 'nanmedian_2';

C = dsp2.util.general.allcomb( {epochs, meas_types, manips, clpses, smoothings} );

m_within = union( conf.SIGNALS.meaned.mean_within, {'descriptives'} );

rois = Container( ...
    {[-250, 0]; [50, 250]; [50, 300]} ...
  , 'epochs', {'targacq'; 'targon'; 'reward'} ...
);

do_save = true;
base_fname = 'vs_null';

FIG = figure(1);

for idx = 1:size(C, 1)
  
  clf( FIG );
  
  epoch = C{idx, 1};
  meas_type = C{idx, 2};
  manip = C{idx, 3};
  clpse = C{idx, 4};
  do_smooth = C{idx, 5};
  
  coh = dsp2.io.get_processed_measure( {meas_type, epoch, manip, clpse}, kind );
  
  if ( ~isempty(strfind(manip, 'drug')) )
    is_drug = true;
  else
    is_drug = false;
  end
  
  assert( ~is_drug, 'not yet implemented' );

  if ( strcmp(meas_type, 'coherence') )
    load_p = fullfile( base_load_p, meas_type, epoch, 'pro_v_anti', 'distributions' );
  else
    if ( ~is_drug )
      load_p = fullfile( base_load_p, meas_type, epoch, 'nondrug', 'pro_v_anti', 'distributions' );
    else
      load_p = '';
    end
  end
  
  dists = dsp2.util.general.concat( dsp2.util.general.load_mats(load_p) );
  
%   dists = extend( dists({'means'}), dists({'means'})+dists({'std_errors'}) ...
%     , dists({'means'})-dists({'std_errors'}) );

  dists = dists({'means'});
  dists = dists.replace( 'means', 'shuffled_means' );
  
  plt = coh;
  plt = plt.collapse( setdiff(plt.categories(), within) );
  plt = plt.require_fields( dists.categories() );
  plt.trial_stats = struct();
  
  dists.data = dists.data(:, 1:numel(coh.frequencies), :);
  
  plt = plt.append( SignalContainer(dists) );
  
  if ( strcmp(meas_type, 'coherence') )
    figs_are = { 'trialtypes', 'outcomes', 'monkeys', 'regions' };
    lines_are = { 'drugs', 'descriptives' };
  elseif ( strcmp(meas_type, 'normalized_power') )
    figs_are = { 'trialtypes', 'outcomes', 'monkeys', 'regions' };
    lines_are = { 'drugs', 'descriptives' };
  else
    error( 'Unrecognized meas type ''%s''.', meas_type );
  end
  
  plt = plt.collapse( clpse );
  
  if ( ~is_drug )
    plt = plt.collapse( 'drugs' );
  end
  
  [I, ~] = plt.get_indices( figs_are );
  
  matching_roi = rois.only( epoch );

  for i = 1:numel(I)
    plt_ = plt(I{i});
    
    for j = 1:shape(matching_roi, 1)
      
%       figure(1); clf();
      
      roi_ = matching_roi.data{j};
      plt_meaned = plt_.time_mean( roi_ );
      plt_meaned = plt_meaned.keep_within_freqs( [0, 100] );
      
      pl = ContainerPlotter();
      pl.add_ribbon = true;
      pl.compare_series = ~do_smooth;
      pl.x = plt_meaned.frequencies;
      pl.y_label = meas_type;
%       pl.y_lim = [-.04, .04];
      pl.y_lim = [];
      
      if ( do_smooth )
        dat = plt_meaned.data;
        for h = 1:size(dat, 1)
          dat(h, :) = smooth( dat(h, :), 3 );
        end
        plt_meaned.data = dat;
      end
      
      pl.plot( plt_meaned, lines_are, figs_are );

      fname = dsp2.util.general.append_uniques( plt_, base_fname, figs_are );   

      if ( do_save )
        if ( do_smooth )
          full_save_p = fullfile( base_save_p, meas_type, epoch, 'smoothed' );
        else
          full_save_p = fullfile( base_save_p, meas_type, epoch, 'nonsmoothed' );
        end
        dsp2.util.general.require_dir( full_save_p );
        dsp2.util.general.save_fig( gcf, fullfile(full_save_p, fname), {'epsc', 'png', 'fig'} );
      end
    end
  end
end
