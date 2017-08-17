dsp2.cluster.init();

epoch = 'targon';

manipulation = 'pro_minus_anti';

conf = dsp2.config.load();

save_path = fullfile( conf.PATHS.plots, datestr(now, 'mmddyy'), 'spectra' );

measure = dsp2.cluster.script.get_hacky_meaned( manipulation );

figs_for_each = { 'monkeys', 'regions', 'drugs', 'trialtypes' };
[~, c] = measure.get_indices( figs_for_each );
  
for i = 1:size(c, 1)
  
  figure(1); clf();
  
  tlims = [ -350, 300 ];
  if ( strcmp(epoch, 'reward') )
    tlims = [ -500, 500 ];
  end

  measure_ = measure.only( c(i, :) );
  measure_.spectrogram( {'outcomes', 'monkeys', 'regions', 'drugs'} ...
    , 'frequencies', [ 0, 100 ] ...
    , 'time', tlims ...
    , 'clims', [] ...
    , 'shape', [1, 2] ...
  );

  labs = measure_.labels.flat_uniques( figs_for_each );    
  fname = strjoin( labs, '_' );
  fname = fullfile( save_path, manipulation, fname );
  dsp2.util.general.save_fig( gcf, fname, {'fig', 'png', 'svg'} );
end