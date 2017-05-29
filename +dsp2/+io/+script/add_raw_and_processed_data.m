%%  add raw signals

new_datafolder = 'H:\SIGNALS\raw\kuro_64';
dsp2.io.add_raw_data_to_database( new_datafolder );

%%  add processed signals

dsp2.io.add_processed_signals();

%%  calculate raw power, coherence, and normalized power

conf = dsp2.config.set.inactivate_epochs( 'all' );
conf = dsp2.config.set.activate_epochs( {'targAcq', 'rwdOn'}, conf ); 

dsp2.analysis.run_coherence( 'config', conf );
dsp2.analysis.run_raw_power( 'config', conf );
dsp2.analysis.run_normalized_power( 'config', conf );
