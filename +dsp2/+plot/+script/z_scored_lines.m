conf = dsp2.config.load();
load_date_dir = '120417';
save_date_dir = dsp2.process.format.get_date_dir();

% epochs = { 'reward', 'targacq' };
epochs = { 'targon' };
kinds = { 'pro_v_anti' };
meas_types = { 'normalized_power' };
withins = { {'outcomes','trialtypes','regions','monkeys', 'days', 'sites'} ...
  , {'outcomes','trialtypes','regions', 'days', 'sites'} };

C = allcomb( {epochs, kinds, meas_types, withins} );

rois = Container( ...
    {[-250, 0]; [50, 250]; [50, 300]} ...
  , 'epochs', {'targacq'; 'targon'; 'reward'} ...
);

do_save = true;

for idx = 1:size(C, 1)

  epoch = C{idx, 1};
  kind = C{idx, 2};
  meas_type = C{idx, 3};
  within = C{idx, 4};
  
  p = fullfile( conf.PATHS.analyses, 'z_scored_spectra', load_date_dir, meas_type, epoch, kind );

  base_save_p = fullfile( conf.PATHS.plots, 'z_scored_lines', save_date_dir, meas_type, epoch, kind );
  base_fname = 'pro_v_anti';

  coh = dsp2.util.general.load_mats( p, true );
  coh = dsp2.util.general.concat( coh );

  meaned = coh.each1d( within, @rowops.nanmean );

  if ( strcmp(epoch, 'reward') )
    tlims = [ -500, 500 ];
  elseif ( strcmp(epoch, 'targacq') )
    tlims = [ -350, 300 ];
  else
    assert( strcmp(epoch, 'targon'), 'Unrecognized epoch %s.', epoch );
    tlims = [ -300, 500 ];
  end

  figure(1); clf();

  plt = meaned;
  plt = plt.collapse( setdiff(plt.categories(), within) );

  [I, ~] = plt.get_indices( {'trialtypes', 'regions', 'monkeys'} );
  
  matching_roi = rois.only( epoch );

  for i = 1:numel(I)
    plt_ = plt(I{i});
    
    for j = 1:shape(matching_roi, 1)
      
      roi_ = matching_roi.data{j};
      plt_meaned = plt_.time_mean( roi_ );
      plt_meaned = plt_meaned.keep_within_freqs( [0, 100] );
      
      pl = ContainerPlotter();
      pl.add_ribbon = true;
      pl.compare_series = true;
      pl.x = plt_meaned.frequencies;
      
      pl.plot( plt_meaned, 'outcomes', {'trialtypes', 'regions', 'monkeys'} );

      fname = dsp2.util.general.append_uniques( plt_, base_fname, {'trialtypes', 'regions', 'monkeys'} );   

      if ( do_save )
        dsp2.util.general.require_dir( base_save_p );
        dsp2.util.general.save_fig( gcf, fullfile(base_save_p, fname), {'epsc', 'png', 'fig'} );
      end
    end
  end

end