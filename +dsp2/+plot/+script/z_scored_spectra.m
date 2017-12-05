conf = dsp2.config.load();
load_date_dir = '120417';
save_date_dir = dsp2.process.format.get_date_dir();
epoch = 'targacq';
kind = 'pro_v_anti';
meas_type = 'normalized_power';
p = fullfile( conf.PATHS.analyses, 'z_scored_spectra', load_date_dir, meas_type, epoch, kind );

base_save_p = fullfile( conf.PATHS.plots, 'z_scored_spectra', save_date_dir, meas_type, epoch, kind );
base_fname = 'pro_v_anti';

coh = dsp2.util.general.load_mats( p, true );
coh = dsp2.util.general.concat( coh );

meaned = coh.each1d( {'outcomes', 'trialtypes', 'regions'}, @rowops.nanmean );

%%

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

[I, C] = plt.get_indices( {'trialtypes', 'regions'} );

for i = 1:numel(I)
  
  plt_ = plt(I{i});

  plt_.spectrogram( {'outcomes', 'trialtypes', 'regions'} ...
    , 'frequencies', [0, 100], 'time', tlims, 'shape', [1, 2] );
  
  fname = dsp2.util.general.append_uniques( plt_, base_fname, {'trialtypes'} );   
  
  dsp2.util.general.require_dir( base_save_p );
  
  dsp2.util.general.save_fig( gcf, fullfile(base_save_p, fname), {'epsc', 'png', 'fig'} );
end