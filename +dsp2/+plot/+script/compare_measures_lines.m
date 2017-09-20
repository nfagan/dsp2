%%  COMPARE_MEASURES_LINES -- Script interface to compare_measures_lines()

import dsp2.util.cluster.tmp_write;

dsp2.cluster.init();

conf = dsp2.config.load();

date = dsp2.process.format.get_date_dir();
kinds = { 'nanmedian' };
sfuncs = { @nanmean };
measures = { 'coherence', 'sfcoherence' };
epochs = { 'reward', 'targacq' };
manipulations = { 'pro_v_anti' };
to_collapse = { {'trials', 'monkeys'} };

bands = Container( {[15, 30]; [35, 50]}, 'band', {'beta'; 'gamma'} );

C = dsp2.util.general.allcomb( ...
  {epochs, manipulations, to_collapse, kinds, sfuncs} ...
);

require_load = true;

base_save_path = fullfile( conf.PATHS.plots, 'compare_measures', date );

tmp_write( '-clear' );

for i = 1:size(C, 1)
  tmp_write( {'\n Processing combination %d of %d', i, size(C, 1)} );
  
  row = C(i, :);
  
  epoch =   row{1};
  manip =   row{2};
  clpse =   row{3};
  kind =    row{4};
  sfunc =   row{5};
  
  conf.PLOT.summary_function = sfunc;
  
  sfunc_name = func2str( sfunc );
  
  if ( i > 1 ), require_load = false; end
  
  shared_inputs = { kind, 'config', conf, 'load_required', require_load };
  
  measure = Container();
  
  for k = 1:numel(measures)
    tmp_write( {'\n   Processing %d of %d ... ', k, numel(measures)} );
    c = [ measures(k), row(1:3) ];
    measure_ = dsp2.io.get_processed_measure( c, shared_inputs{:} );
    %   get rid of acc spikes -> bla field
    measure_ = measure_.only( 'bla_acc' );
    measure_ = measure_.keep_within_freqs( [0, 100] );
    measure_ = measure_.keep_within_times( [-500, 500] );
    measure_ = measure_.require_fields( 'signal_measure' );
    measure_( 'signal_measure' ) = measures{k};
    measure = measure.append( measure_ );
  end
  
  meas = strjoin( measures, '_' );
  
  save_path = fullfile( base_save_path, sfunc_name, meas, kind, epoch, manip );
  
  dsp2.plot.compare_measures_lines( measure, bands, save_path, 'config', conf );
end

