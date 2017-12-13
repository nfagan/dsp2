conf = dsp2.config.load();
load_date_dir = '121217';
save_date_dir = dsp2.process.format.get_date_dir();

is_drug = true;
epochs = { 'reward', 'targacq', 'targon' };
% epochs = { 'targon' };
kinds = { 'pro_v_anti' };
meas_types = { 'normalized_power' };
withins = { {'outcomes','trialtypes','regions','drugs','monkeys'}, {'outcomes','trialtypes','drugs','regions'} };

C = allcomb( {epochs, kinds, meas_types, withins} );

for idx = 1:size(C, 1)

  epoch = C{idx, 1};
  kind = C{idx, 2};
  meas_type = C{idx, 3};
  within = C{idx, 4};
  
  p = fullfile( conf.PATHS.analyses, 'z_scored_spectra', load_date_dir, meas_type, epoch );
  base_save_p = fullfile( conf.PATHS.plots, 'z_scored_spectra', save_date_dir, meas_type );
    
  if ( is_drug )
    p = fullfile( p, 'drug', kind );
    base_save_p = fullfile( base_save_p, 'drug', epoch, kind );
  else
    p = fullfile( p, kind );
    base_save_p = fullfile( base_save_p, 'nondrug', epoch, kind );
  end
  
  
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
    tlims = [ -100, 300 ];
  end

  figure(1); clf();

  plt = meaned;

  figs_are = { 'trialtypes', 'regions', 'monkeys', 'drugs' };
  [I, ~] = plt.get_indices( figs_are );

  for i = 1:numel(I)

    plt_ = plt(I{i});

    plt_.spectrogram( {'outcomes', 'trialtypes', 'regions'} ...
      , 'frequencies', [0, 100], 'time', tlims, 'shape', [1, 2] );

    fname = dsp2.util.general.append_uniques( plt_, base_fname, figs_are );   

    dsp2.util.general.require_dir( base_save_p );

    dsp2.util.general.save_fig( gcf, fullfile(base_save_p, fname), {'epsc', 'png', 'fig'}, true );
  end

end

%%



