%%  SUMMARY_BAR -- Script interface to summary_bar()

conf = dsp2.config.load();

date = '072617';
kinds = { 'nanmedian' };
sfuncs = { @nanmean };
measures = { 'coherence' };
epochs = { 'reward', 'targacq' };
manipulations = { 'pro_v_anti' };
to_collapse = { {'trials', 'monkeys'} };

bands = Container( {[15, 30]; [35, 50]}, 'band', {'beta'; 'gamma'} );
bands = sparse( bands );

C = dsp2.util.general.allcomb( ...
  {measures, epochs, manipulations, to_collapse, kinds, sfuncs} ...
);

require_load = true;

base_save_path = fullfile( conf.PATHS.plots, date, 'bar' );

for i = 1:size(C, 1)
  fprintf( '\n Processing combination %d of %d', i, size(C, 1) );
  
  row = C(i, :);
  
  c = row(1:4);
  
  meas =    row{1};
  epoch =   row{2};
  manip =   row{3};
  clpse =   row{4};
  kind =    row{5};
  sfunc =   row{6};
  
  conf.PLOT.summary_function = sfunc;
  
  sfunc_name = func2str( sfunc );
  
  if ( i > 1 ), require_load = false; end
  
  shared_inputs = { kind, 'config', conf, 'load_required', require_load };
  
  measure = dsp2.io.get_processed_measure( c, shared_inputs{:} );

  if ( strcmp(epoch, 'targacq') )
    %   use cued trials from target onset, and a different time window for
    %   the average.
    c_copy = { meas, 'targon', manip, clpse };
    
    cue_measure = dsp2.io.get_processed_measure( c_copy, shared_inputs{:} );
    
    measure = measure.rm( 'cued' );
    cue_measure = cue_measure.rm( 'choice' );
    
    cue_measure = cue_measure.time_mean( [50, 250] );
    measure = measure.time_mean( [-200, 0] );
    
    measure = measure.append( cue_measure );
  else
    assert( strcmp(epoch, 'reward'), 'Not defined for ''%s''.', epoch );
    measure = measure.time_mean( [50, 300] );
  end
  
  measure = measure.require_fields( 'signal_measure' );
  measure( 'signal_measure' ) = meas;
  
  save_path = fullfile( base_save_path, sfunc_name, meas, kind, epoch, manip );
  
  dsp2.plot.summary_bar( measure, bands, save_path, 'config', conf );
end

