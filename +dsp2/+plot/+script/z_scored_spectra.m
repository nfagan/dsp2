conf = dsp2.config.load();
% load_date_dir = '121217'; % np, drug, all epochs
% load_date_dir = '120817';
% load_date_dir = '112817'; % coherence, reward targacq, non-drug
% load_date_dir = '112917'; % coherence, targon
% % load_date_dir = '121117'; % coherence, all epochs, drug

% load_date_dir = '120417'; % np, all epochs, non-drug
load_date_dir = '121917'; % coh, all epochs, non-drug, pro_minus_anti;
% load_date_dir = '122017'; % np, all epochs, non-drug, pro_minus_anti;
save_date_dir = dsp2.process.format.get_date_dir();

is_drug = false;
is_ot_minus_sal = false;
epochs = { 'targacq' };
kinds = { 'pro_v_anti' };
meas_types = { 'coherence' };
withins = { {'outcomes', 'trialtypes', 'regions', 'drugs', 'monkeys'} ...
  , {'outcomes', 'trialtypes', 'drugs', 'regions'} };

C = allcomb( {epochs, kinds, meas_types, withins} );

adtl = '';

for idx = 1:size(C, 1)

  epoch = C{idx, 1};
  kind = C{idx, 2};
  meas_type = C{idx, 3};
  within = C{idx, 4};
  
  p = fullfile( conf.PATHS.analyses, 'z_scored_spectra', load_date_dir, meas_type, epoch );
  base_save_p = fullfile( conf.PATHS.plots, 'z_scored_spectra', save_date_dir, meas_type );
    
  if ( is_drug )
    p = fullfile( p, 'drug', kind );
    if ( is_ot_minus_sal )
      base_save_p = fullfile( base_save_p, 'ot_minus_sal', epoch, kind );
    else
      base_save_p = fullfile( base_save_p, 'drug', epoch, kind );
    end
  else
    p = fullfile( p, adtl,kind );
    base_save_p = fullfile( base_save_p, 'nondrug', epoch, kind );
  end
  
  base_fname = 'pro_v_anti';

  coh = dsp2.util.general.load_mats( p, true );
  coh = dsp2.util.general.concat( coh );
  
  if ( ~is_drug )
    coh = coh.collapse( 'drugs' );
  end

  meaned = coh.each1d( within, @rowops.nanmean );
  
  if ( is_drug && is_ot_minus_sal )
    meaned = meaned.collapse( {'blocks', 'sessions'} );
    meaned = meaned({'oxytocin'}) - meaned({'saline'});
  end
  
%   meaned = dsp2.process.manipulations.pro_minus_anti( meaned );

  if ( strcmp(epoch, 'reward') )
    tlims = [ -500, 500 ];
  elseif ( strcmp(epoch, 'targacq') )
    tlims = [ -350, 300 ];
  else
    assert( strcmp(epoch, 'targon'), 'Unrecognized epoch %s.', epoch );
    tlims = [ 0, 300 ];
  end

  figure(1); clf();

  plt = meaned;

  figs_are = { 'trialtypes', 'regions', 'monkeys', 'drugs' };
  [I, ~] = plt.get_indices( figs_are );

  for i = 1:numel(I)

    plt_ = plt(I{i});
    plt_ = plt_.rm( 'errors' );

    plt_.spectrogram( {'outcomes', 'trialtypes', 'regions', 'drugs', 'administration'} ...
      , 'frequencies', [0, 100], 'time', tlims, 'shape', [1, 2] );

    fname = dsp2.util.general.append_uniques( plt_, base_fname, union(figs_are, {'administration','drugs'}) );   

    dsp2.util.general.require_dir( base_save_p );

    dsp2.util.general.save_fig( gcf, fullfile(base_save_p, fname), {'svg', 'fig'}, true );
  end

end


