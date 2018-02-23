conf = dsp2.config.load();
epochs = { 'reward', 'targacq' };
is_drugs = { false };
bands = containers.Map( {'theta_alpha', 'beta', 'gamma'}, {[4, 12], [15, 30], [35, 50]} );
times = containers.Map( {'reward', 'targacq', 'targon'}, {[0, 200], [-200, 0], [50, 250]} );

date_dir = dsp2.process.format.get_date_dir();

base_p = fullfile( conf.PATHS.analyses, 'measures_within_magnitude', 'coherence' );
save_p = fullfile( conf.PATHS.plots, 'measures_within_magnitude', date_dir, 'coherence' );

C = dsp2.util.general.allcomb( {epochs, is_drugs} );

mean_within = { 'magnitudes', 'administration', 'outcomes', 'trialtypes' ...
  , 'days', 'sites', 'regions', 'channels', 'epochs' };

do_save = true;
base_fname = '';

fig = figure(1);

for i = 1:size(C, 1)
  fprintf( '\n Processing %d of %d', i, size(C, 1) );
  
  epoch = C{i, 1};
  is_drug = C{i, 2};
  time_roi = times( epoch );
  
  load_p = fullfile( base_p, epoch );
  full_save_p = fullfile( save_p, epoch );
  
  if ( is_drug )
    load_p = fullfile( load_p, 'drug' );
    full_save_p = fullfile( full_save_p, 'drug' );
  else
    load_p = fullfile( load_p, 'nondrug' );
    full_save_p = fullfile( full_save_p, 'nondrug' );
  end
  
  coh = dsp2.util.general.concat( dsp2.util.general.load_mats(load_p) );
  
  band_names = bands.keys;
  
  all_bands = Container();
  
  for j = 1:numel(band_names)
    freq_roi = bands( band_names{j} );
    
    meaned = coh.time_freq_mean( time_roi, freq_roi );
    meaned = meaned.each1d( mean_within, @rowops.nanmean );
    meaned = meaned.rm( {'errors'} );
    meaned = meaned.rm( dsp2.process.format.get_bad_days() );
    
    meaned = meaned.require_fields( 'band' );
    meaned( 'band' ) = band_names{j};
    
    all_bands = all_bands.append( meaned );
  end
  
  filenames_are = { 'band', 'magnitudes', 'outcomes', 'trialtypes' };
  figs_are = { 'trialtypes' };
  
  I = all_bands.get_indices( figs_are );
  
  for j = 1:numel(I)
    
    pl = ContainerPlotter();
    clf( fig );
    
    pl.order_by = { 'theta_alpha', 'beta', 'gamma' };
    pl.order_groups_by = { 'low', 'medium', 'high' };
    pl.y_lim = [ 0.75, 1 ];
    
    subset = all_bands( I{j} );
    
    pl.bar( subset, 'band', 'magnitudes', {'outcomes', 'trialtypes'} );

    if ( do_save )
      dsp2.util.general.require_dir( full_save_p );
      fname = dsp2.util.general.append_uniques( subset, base_fname, filenames_are );
      dsp2.util.general.save_fig( gcf, fullfile(full_save_p, fname), {'epsc', 'fig', 'png'} );
    end
  
  end
  
end