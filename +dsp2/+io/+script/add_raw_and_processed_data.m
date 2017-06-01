%%  add raw signals

new_datafolder = 'H:\SIGNALS\raw\kuro_64';
dsp2.io.add_raw_data_to_database( new_datafolder );

%%  add processed signals + basic behavioral data

dsp2.io.add_processed_signals();
dsp2.io.add_processed_behavior();

%%  calculate + save raw power, coherence, and normalized power

conf = dsp2.config.set.inactivate_epochs( 'all' );
conf = dsp2.config.set.activate_epochs( {'targAcq', 'rwdOn'}, conf );

dsp2.analysis.run( 'coherence', 'config', conf );
% dsp2.analysis.run( 'raw_power', 'config', conf );
% dsp2.analysis.run( 'normalized_power', 'config', conf );

%%  calculate + save meaned versions of these measures

dsp2.analysis.run_meaned( 'coherence', 'config', conf );
dsp2.analysis.run_meaned( 'raw_power', 'config', conf );
% dsp2.analysis.run_meaned( 'measure_type', 'normalized_power', 'config', conf );
