dsp2.cluster.init();

conf = dsp2.config.set.inactivate_epochs( 'all' );
conf = dsp2.config.set.activate_epochs( {'cueOn'}, conf );

conf.SIGNALS.reference_type = 'non_common_averaged';
conf.SIGNALS.meaned.summary_function = @Container.nanmedian_1d;

dsp2.analysis.run( 'coherence', 'config', conf );

dsp2.util.cluster.tmp_write( 'Done calculating complete.' );

% calculate + save meaned versions of these measures

dsp2.analysis.run_meaned( 'coherence', 'config', conf );

dsp2.util.cluster.tmp_write( 'Done calculating meaned.' );

exit();