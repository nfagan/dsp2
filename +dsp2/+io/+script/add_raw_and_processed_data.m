%%  add raw signals

new_datafolder = 'H:\SIGNALS\raw\kuro_64';
dsp2.io.add_raw_data_to_database( new_datafolder );

%%  add processed signals + basic behavioral data

conf = dsp2.config.load();
conf.SIGNALS.handle_missing_trials = 'skip';
conf = dsp2.config.set.inactivate_epochs( 'cueOn', conf );
conf.SIGNALS.EPOCHS.rwdOn.time = [-500, 500];
dsp2.io.add_processed_signals( 'config', conf, 'wideband', true );
dsp2.io.add_processed_behavior();

%%  calculate + save raw power, coherence, and normalized power

conf = dsp2.config.set.inactivate_epochs( 'all' );
conf = dsp2.config.set.activate_epochs( {'targAcq', 'rwdOn'}, conf );
% conf = dsp2.config.set.activate_epochs( 'targOn', conf );

conf.SIGNALS.reference_type = 'non_common_averaged';

dsp2.analysis.run( 'sfcoherence', 'config', conf );
% dsp2.analysis.run( 'coherence', 'config', conf );
% dsp2.analysis.run( 'normalized_power', 'config', conf );
% dsp2.analysis.run( 'raw_power', 'config', conf );

%%  calculate + save meaned versions of these measures

funcs = { @nanmedian, @nanmean };

for i = 1:numel(funcs)

conf.SIGNALS.meaned.summary_function = funcs{i};

dsp2.analysis.run_meaned( 'normalized_power', 'config', conf );
dsp2.analysis.run_meaned( 'coherence', 'config', conf );
% dsp2.analysis.run_meaned( 'raw_power', 'config', conf );

end

