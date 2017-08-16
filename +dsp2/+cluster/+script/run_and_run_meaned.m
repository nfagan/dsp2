dsp2.cluster.init();

conf = dsp2.config.set.inactivate_epochs( 'all' );
conf = dsp2.config.set.activate_epochs( {'targOn'}, conf );

conf.SIGNALS.reference_type = 'non_common_averaged';
conf.SIGNALS.summary_function = @nanmedian;

dsp2.analysis.run( 'sfcoherence', 'config', conf );

% calculate + save meaned versions of these measures

dsp2.analysis.run_meaned( 'sfcoherence', 'config', conf );

exit();