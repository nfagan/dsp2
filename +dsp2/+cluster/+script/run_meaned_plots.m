conf = dsp2.config.load();

date_dir = datestr( now, 'mmddyy' );

load_path = fullfile( conf.PATHS.analyses, '081717', 'sfcoherence' );
save_path = fullfile( conf.PATHS.plots, date_dir, 'spectra' );

dsp2.util.general.require_dir( save_path );

manipulation = 'pro_v_anti';

mats = dsp2.util.general.dirstruct( load_path, '.mat' );
mats = { mats(:).name };

m_within = { 'outcomes', 'monkeys', 'trialtypes', 'regions', 'days', 'sites' };

measure = Container();

for i = 1:numel(mats)
  load( mats{i} );
  coh = coh.collapse( {'trials', 'monkeys'} );
  coh = coh.parfor_each( m_within, @nanmean );
  coh = coh.collapse_except( m_within );
  if ( ~isempty(strfind(manipulation, 'pro')) )
    coh = dsp2.process.manipulations.pro_v_anti( coh );
  end
  if ( ~isempty(strfind(manipulation, 'minus_anti')) )
    coh = dsp2.process.manipulations.pro_minus_anti( coh );
  end
  coh = coh.parfor_each( setdiff(m_within, {'days', 'sites'}), @nanmean );
  
  measure = measure.append( coh );
end

figs_for_each = { 'monkeys', 'regions', 'drugs', 'trialtypes' };
[~, c] = measure.get_indices( figs_for_each );
  
for k = 1:size(c, 1)
  
  figure(1); clf();
  
  tlims = [ -350, 300 ];
  if ( strcmp(epoch, 'reward') )
    tlims = [-500, 500];
  end

  measure_ = measure.only( c(k, :) );
  measure_.spectrogram( {'outcomes', 'monkeys', 'regions', 'drugs'} ...
    , 'frequencies', [0, 100] ...
    , 'time', tlims ...
    , 'clims', clims_.data ...
    , 'shape', shape ...
  );

  labs = measure_.labels.flat_uniques( figs_for_each );    
  fname = strjoin( labs, '_' );
  fname = fullfile( save_path, manipulation, fname );
  dsp2.util.general.save_fig( gcf, fname, {'fig', 'png', 'svg'} );
end