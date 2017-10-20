dsp2.cluster.init();

conf = dsp2.config.set.inactivate_epochs( 'all' );
conf = dsp2.config.set.activate_epochs( {'cueOn', 'targOn', 'targAcq'}, conf );

conf.SIGNALS.reference_type = 'non_common_averaged';
conf.SIGNALS.meaned.summary_function = @Container.nanmedian_1d;

dsp2.analysis.run( 'coherence', 'config', conf );

dsp2.util.cluster.tmp_write( 'Done calculating complete.' );

% calculate + save meaned versions of these measures

conf.SIGNALS.meaned.pre_mean_operations{end+1} = { @remove_nans_and_infs, {} };

dsp2.analysis.run_meaned( 'coherence', 'config', conf );

dsp2.util.cluster.tmp_write( 'Done calculating meaned.' );

exit();